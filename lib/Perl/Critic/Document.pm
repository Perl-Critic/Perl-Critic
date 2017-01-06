package Perl::Critic::Document;

use 5.006001;
use strict;
use warnings;

use Carp qw< confess >;

use List::Util qw< reduce >;
use Scalar::Util qw< blessed refaddr weaken >;
use version;

use PPI::Document;
use PPI::Document::File;
use PPIx::Utilities::Node qw< split_ppi_node_by_namespace >;

use Perl::Critic::Annotation;
use Perl::Critic::Exception::Parse qw< throw_parse >;
use Perl::Critic::Utils qw< :booleans :characters shebang_line >;

use PPIx::Regexp 0.010 qw< >;

#-----------------------------------------------------------------------------

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

our $AUTOLOAD;
sub AUTOLOAD {  ## no critic (ProhibitAutoloading,ArgUnpacking)
    my ( $function_name ) = $AUTOLOAD =~ m/ ([^:\']+) \z /xms;
    return if $function_name eq 'DESTROY';
    my $self = shift;
    return $self->{_doc}->$function_name(@_);
}

#-----------------------------------------------------------------------------

sub new {
    my ($class, @args) = @_;

    my $self = bless {}, $class;

    $self->_init_common();
    $self->_init_from_external_source(@args);

    return $self;
}

#-----------------------------------------------------------------------------

sub _new_for_parent_document {
    my ($class, $ppi_document, $parent_document) = @_;

    my $self = bless {}, $class;

    $self->_init_common();

    $self->{_doc}       = $ppi_document;
    $self->{_is_module} = $parent_document->is_module();

    return $self;
}

#-----------------------------------------------------------------------------

sub _init_common {
    my ($self) = @_;

    $self->{_annotations} = [];
    $self->{_suppressed_violations} = [];
    $self->{_disabled_line_map} = {};

    return;
}

#-----------------------------------------------------------------------------

sub _init_from_external_source { ## no critic (Subroutines::RequireArgUnpacking)
    my $self = shift;
    my %args;

    if (@_ == 1) {
        warnings::warnif(
            'deprecated',
            'Perl::Critic::Document->new($source) deprecated, use Perl::Critic::Document->new(-source => $source) instead.' ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
        );
        %args = ('-source' => shift);
    } else {
        %args = @_;
    }

    my $source_code = $args{'-source'};

    # $source_code can be a file name, or a reference to a
    # PPI::Document, or a reference to a scalar containing source
    # code.  In the last case, PPI handles the translation for us.

    my $ppi_document =
        _is_ppi_doc($source_code)
            ? $source_code
            : ref $source_code
                ? PPI::Document->new($source_code)
                : PPI::Document::File->new($source_code);

    # Bail on error
    if (not defined $ppi_document) {
        my $errstr   = PPI::Document::errstr();
        my $file     = ref $source_code ? undef : $source_code;
        throw_parse
            message     => qq<Can't parse code: $errstr>,
            file_name   => $file;
    }

    $self->{_doc} = $ppi_document;
    $self->index_locations();
    $self->_disable_shebang_fix();
    $self->{_filename_override} = $args{'-filename-override'};
    $self->{_is_module} = $self->_determine_is_module(\%args);

    return;
}

#-----------------------------------------------------------------------------

sub _is_ppi_doc {
    my ($ref) = @_;
    return blessed($ref) && $ref->isa('PPI::Document');
}

#-----------------------------------------------------------------------------

sub ppi_document {
    my ($self) = @_;
    return $self->{_doc};
}

#-----------------------------------------------------------------------------

sub isa {
    my ($self, @args) = @_;
    return $self->SUPER::isa(@args)
        || ( (ref $self) && $self->{_doc} && $self->{_doc}->isa(@args) );
}

#-----------------------------------------------------------------------------

sub find {
    my ($self, $wanted, @more_args) = @_;

    # This method can only find elements by their class names.  For
    # other types of searches, delegate to the PPI::Document
    if ( ( ref $wanted ) || !$wanted || $wanted !~ m/ \A PPI:: /xms ) {
        return $self->{_doc}->find($wanted, @more_args);
    }

    # Build the class cache if it doesn't exist.  This happens at most
    # once per Perl::Critic::Document instance.  %elements of will be
    # populated as a side-effect of calling the $finder_sub coderef
    # that is produced by the caching_finder() closure.
    if ( !$self->{_elements_of} ) {

        my %cache = ( 'PPI::Document' => [ $self ] );

        # The cache refers to $self, and $self refers to the cache.  This
        # creates a circular reference that leaks memory (i.e.  $self is not
        # destroyed until execution is complete).  By weakening the reference,
        # we allow perl to collect the garbage properly.
        weaken( $cache{'PPI::Document'}->[0] );

        my $finder_coderef = _caching_finder( \%cache );
        $self->{_doc}->find( $finder_coderef );
        $self->{_elements_of} = \%cache;
    }

    # find() must return false-but-defined on fail
    return $self->{_elements_of}->{$wanted} || q{};
}

#-----------------------------------------------------------------------------

sub find_first {
    my ($self, $wanted, @more_args) = @_;

    # This method can only find elements by their class names.  For
    # other types of searches, delegate to the PPI::Document
    if ( ( ref $wanted ) || !$wanted || $wanted !~ m/ \A PPI:: /xms ) {
        return $self->{_doc}->find_first($wanted, @more_args);
    }

    my $result = $self->find($wanted);
    return $result ? $result->[0] : $result;
}

#-----------------------------------------------------------------------------

sub find_any {
    my ($self, $wanted, @more_args) = @_;

    # This method can only find elements by their class names.  For
    # other types of searches, delegate to the PPI::Document
    if ( ( ref $wanted ) || !$wanted || $wanted !~ m/ \A PPI:: /xms ) {
        return $self->{_doc}->find_any($wanted, @more_args);
    }

    my $result = $self->find($wanted);
    return $result ? 1 : $result;
}

#-----------------------------------------------------------------------------

sub namespaces {
    my ($self) = @_;

    return keys %{ $self->_nodes_by_namespace() };
}

#-----------------------------------------------------------------------------

sub subdocuments_for_namespace {
    my ($self, $namespace) = @_;

    my $subdocuments = $self->_nodes_by_namespace()->{$namespace};

    return $subdocuments ? @{$subdocuments} : ();
}

#-----------------------------------------------------------------------------

sub ppix_regexp_from_element {
    my ( $self, $element ) = @_;

    if ( blessed( $element ) && $element->isa( 'PPI::Element' ) ) {
        my $addr = refaddr( $element );
        return $self->{_ppix_regexp_from_element}{$addr}
            if exists $self->{_ppix_regexp_from_element}{$addr};
        return ( $self->{_ppix_regexp_from_element}{$addr} =
            PPIx::Regexp->new( $element,
                default_modifiers =>
                $self->_find_use_re_modifiers_in_scope_from_element(
                    $element ),
            ) );
    } else {
        return PPIx::Regexp->new( $element );
    }
}

sub _find_use_re_modifiers_in_scope_from_element {
    my ( $self, $elem ) = @_;
    my @found;
    foreach my $use_re ( @{ $self->find( 'PPI::Statement::Include' ) || [] } )
    {
        're' eq $use_re->module()
            or next;
        $self->element_is_in_lexical_scope_after_statement_containing(
            $elem, $use_re )
            or next;
        my $prefix = 'no' eq $use_re->type() ? q{-} : $EMPTY;
        push @found,
            map { "$prefix$_" }
            grep { m{ \A / }smx }
            map {
                $_->isa( 'PPI::Token::Quote' ) ? $_->string() :
                $_->isa( 'PPI::Token::QuoteLike::Words' ) ?  $_->literal() :
                $_->content() }
            $use_re->schildren();
    }
    return \@found;
}

#-----------------------------------------------------------------------------

# This got hung on the Perl::Critic::Document, rather than living in
# Perl::Critic::Utils::PPI, because of the possibility that caching of scope
# objects would turn out to be desirable.

sub element_is_in_lexical_scope_after_statement_containing {
    my ( $self, $inner_elem, $outer_elem ) = @_;

    # If the outer element defines a scope, we're true if and only if
    # the outer element contains the inner element.
    $outer_elem->scope()
        and return $inner_elem->descendant_of( $outer_elem );

    # In the more general case:

    # The last element of the statement containing the outer element
    # must be before the inner element. If not, we know we're false,
    # without walking the parse tree.

    my $stmt = $outer_elem->statement()
        or return;
    my $last_elem = $stmt->last_element()
        or return;

    my $stmt_loc = $last_elem->location()
        or return;

    my $inner_loc = $inner_elem->location()
        or return;

    $stmt_loc->[0] > $inner_loc->[0]
        and return;
    $stmt_loc->[0] == $inner_loc->[0]
        and $stmt_loc->[1] > $inner_loc->[1]
        and return;

    # Since we know the inner element is after the outer element, find
    # the element that defines the scope of the statement that contains
    # the outer element.

    my $parent = $stmt;
    while ( ! $parent->scope() ) {
        $parent = $parent->parent()
            or return;
    }

    # We're true if and only if the scope of the outer element contains
    # the inner element.

    return $inner_elem->descendant_of( $parent );

}

#-----------------------------------------------------------------------------

sub filename {
    my ($self) = @_;

    if (defined $self->{_filename_override}) {
        return $self->{_filename_override};
    }
    else {
        my $doc = $self->{_doc};
        return $doc->can('filename') ? $doc->filename() : undef;
    }
}

#-----------------------------------------------------------------------------

sub highest_explicit_perl_version {
    my ($self) = @_;

    my $highest_explicit_perl_version =
        $self->{_highest_explicit_perl_version};

    if ( not exists $self->{_highest_explicit_perl_version} ) {
        my $includes = $self->find( \&_is_a_version_statement );

        if ($includes) {
            # Note: this doesn't use List::Util::max() because that function
            # doesn't use the overloaded ">=" etc of a version object.  The
            # reduce() style lets version.pm take care of all comparing.
            #
            # For reference, max() ends up looking at the string converted to
            # an NV, or something like that.  An underscore like "5.005_04"
            # provokes a warning and is chopped off at "5.005" thus losing the
            # minor part from the comparison.
            #
            # An underscore "5.005_04" is supposed to mean an alpha release
            # and shouldn't be used in a perl version.  But it's shown in
            # perlfunc under "use" (as a number separator), and appears in
            # several modules supplied with perl 5.10.0 (like version.pm
            # itself!).  At any rate if version.pm can understand it then
            # that's enough for here.
            $highest_explicit_perl_version =
                reduce { $a >= $b ? $a : $b }
                map    { version->new( $_->version() ) }
                       @{$includes};
        }
        else {
            $highest_explicit_perl_version = undef;
        }

        $self->{_highest_explicit_perl_version} =
            $highest_explicit_perl_version;
    }

    return $highest_explicit_perl_version if $highest_explicit_perl_version;
    return;
}

#-----------------------------------------------------------------------------

sub uses_module {
    my ($self, $module_name) = @_;

    return exists $self->_modules_used()->{$module_name};
}

#-----------------------------------------------------------------------------

sub process_annotations {
    my ($self) = @_;

    my @annotations = Perl::Critic::Annotation->create_annotations($self);
    $self->add_annotation(@annotations);
    return $self;
}

#-----------------------------------------------------------------------------

sub line_is_disabled_for_policy {
    my ($self, $line, $policy) = @_;
    my $policy_name = ref $policy || $policy;

    # HACK: This Policy is special.  If it is active, it cannot be
    # disabled by a "## no critic" annotation.  Rather than create a general
    # hook in Policy.pm for enabling this behavior, we chose to hack
    # it here, since this isn't the kind of thing that most policies do

    return 0 if $policy_name eq
        'Perl::Critic::Policy::Miscellanea::ProhibitUnrestrictedNoCritic';

    return 1 if $self->{_disabled_line_map}->{$line}->{$policy_name};
    return 1 if $self->{_disabled_line_map}->{$line}->{ALL};
    return 0;
}

#-----------------------------------------------------------------------------

sub add_annotation {
    my ($self, @annotations) = @_;

    # Add annotation to our private map for quick lookup
    for my $annotation (@annotations) {

        my ($start, $end) = $annotation->effective_range();
        my @affected_policies = $annotation->disables_all_policies ?
            qw(ALL) : $annotation->disabled_policies();

        # TODO: Find clever way to do this with hash slices
        for my $line ($start .. $end) {
            for my $policy (@affected_policies) {
                $self->{_disabled_line_map}->{$line}->{$policy} = 1;
            }
        }
    }

    push @{ $self->{_annotations} }, @annotations;
    return $self;
}

#-----------------------------------------------------------------------------

sub annotations {
    my ($self) = @_;
    return @{ $self->{_annotations} };
}

#-----------------------------------------------------------------------------

sub add_suppressed_violation {
    my ($self, $violation) = @_;
    push @{$self->{_suppressed_violations}}, $violation;
    return $self;
}

#-----------------------------------------------------------------------------

sub suppressed_violations {
    my ($self) = @_;
    return @{ $self->{_suppressed_violations} };
}

#-----------------------------------------------------------------------------

sub is_program {
    my ($self) = @_;

    return not $self->is_module();
}

#-----------------------------------------------------------------------------

sub is_module {
    my ($self) = @_;

    return $self->{_is_module};
}

#-----------------------------------------------------------------------------
# PRIVATE functions & methods

sub _is_a_version_statement {
    my (undef, $element) = @_;

    return 0 if not $element->isa('PPI::Statement::Include');
    return 1 if $element->version();
    return 0;
}

#-----------------------------------------------------------------------------

sub _caching_finder {
    my $cache_ref = shift;  # These vars will persist for the life
    my %isa_cache = ();     # of the code ref that this sub returns


    # Gather up all the PPI elements and sort by @ISA.  Note: if any
    # instances used multiple inheritance, this implementation would
    # lead to multiple copies of $element in the $elements_of lists.
    # However, PPI::* doesn't do multiple inheritance, so we are safe

    return sub {
        my (undef, $element) = @_;
        my $classes = $isa_cache{ref $element};
        if ( !$classes ) {
            $classes = [ ref $element ];
            # Use a C-style loop because we append to the classes array inside
            for ( my $i = 0; $i < @{$classes}; $i++ ) { ## no critic(ProhibitCStyleForLoops)
                no strict 'refs';                       ## no critic(ProhibitNoStrict)
                push @{$classes}, @{"$classes->[$i]::ISA"};
                $cache_ref->{$classes->[$i]} ||= [];
            }
            $isa_cache{$classes->[0]} = $classes;
        }

        for my $class ( @{$classes} ) {
            push @{$cache_ref->{$class}}, $element;
        }

        return 0; # 0 tells find() to keep traversing, but not to store this $element
    };
}

#-----------------------------------------------------------------------------

sub _disable_shebang_fix {
    my ($self) = @_;

    # When you install a program using ExtUtils::MakeMaker or Module::Build, it
    # inserts some magical code into the top of the file (just after the
    # shebang).  This code allows people to call your program using a shell,
    # like `sh my_script`.  Unfortunately, this code causes several Policy
    # violations, so we disable them as if they had "## no critic" annotations.

    my $first_stmnt = $self->schild(0) || return;

    # Different versions of MakeMaker and Build use slightly different shebang
    # fixing strings.  This matches most of the ones I've found in my own Perl
    # distribution, but it may not be bullet-proof.

    my $fixin_rx = qr<^eval 'exec .* \$0 \$[{]1[+]"\$@"}'\s*[\r\n]\s*if.+;>ms; ## no critic (ExtendedFormatting)
    if ( $first_stmnt =~ $fixin_rx ) {
        my $line = $first_stmnt->location->[0];
        $self->{_disabled_line_map}->{$line}->{ALL} = 1;
        $self->{_disabled_line_map}->{$line + 1}->{ALL} = 1;
    }

    return $self;
}

#-----------------------------------------------------------------------------

sub _determine_is_module {
    my ($self, $args) = @_;

    my $file_name = $self->filename();
    if (
            defined $file_name
        and ref $args->{'-program-extensions'} eq 'ARRAY'
    ) {
        foreach my $ext ( @{ $args->{'-program-extensions'} } ) {
            my $regex =
                ref $ext eq 'Regexp'
                    ? $ext
                    : qr< @{ [ quotemeta $ext ] } \z >xms;

            return $FALSE if $file_name =~ m/$regex/smx;
        }
    }

    return $FALSE if shebang_line($self);
    return $FALSE if defined $file_name && $file_name =~ m/ [.] PL \z /smx;

    return $TRUE;
}

#-----------------------------------------------------------------------------

sub _nodes_by_namespace {
    my ($self) = @_;

    my $nodes = $self->{_nodes_by_namespace};

    return $nodes if $nodes;

    my $ppi_document = $self->ppi_document();
    if (not $ppi_document) {
        return $self->{_nodes_by_namespace} = {};
    }

    my $raw_nodes_map = split_ppi_node_by_namespace($ppi_document);

    my %wrapped_nodes;
    while ( my ($namespace, $raw_nodes) = each %{$raw_nodes_map} ) {
        $wrapped_nodes{$namespace} = [
            map { __PACKAGE__->_new_for_parent_document($_, $self) }
                @{$raw_nodes}
        ];
    }

    return $self->{_nodes_by_namespace} = \%wrapped_nodes;
}

#-----------------------------------------------------------------------------

# Note: must use exists on return value to determine membership because all
# the values are false, unlike the result of hashify().
sub _modules_used {
    my ($self) = @_;

    my $mapping = $self->{_modules_used};

    return $mapping if $mapping;

    my $includes = $self->find('PPI::Statement::Include');
    if (not $includes) {
        return $self->{_modules_used} = {};
    }

    my %mapping;
    for my $module (
        grep { $_ } map  { $_->module() || $_->pragma() } @{$includes}
    ) {
        # Significanly ess memory than $h{$k} => 1.  Thanks Mr. Lembark.
        $mapping{$module} = ();
    }

    return $self->{_modules_used} = \%mapping;
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=for stopwords pre-caches

=head1 NAME

Perl::Critic::Document - Caching wrapper around a PPI::Document.


=head1 SYNOPSIS

    use PPI::Document;
    use Perl::Critic::Document;
    my $doc = PPI::Document->new('Foo.pm');
    $doc = Perl::Critic::Document->new(-source => $doc);
    ## Then use the instance just like a PPI::Document


=head1 DESCRIPTION

Perl::Critic does a lot of iterations over the PPI document tree via
the C<PPI::Document::find()> method.  To save some time, this class
pre-caches a lot of the common C<find()> calls in a single traversal.
Then, on subsequent requests we return the cached data.

This is implemented as a facade, where method calls are handed to the
stored C<PPI::Document> instance.


=head1 CAVEATS

This facade does not implement the overloaded operators from
L<PPI::Document|PPI::Document> (that is, the C<use overload ...>
work). Therefore, users of this facade must not rely on that syntactic
sugar.  So, for example, instead of C<my $source = "$doc";> you should
write C<< my $source = $doc->content(); >>

Perhaps there is a CPAN module out there which implements a facade
better than we do here?


=head1 INTERFACE SUPPORT

This is considered to be a public class.  Any changes to its interface
will go through a deprecation cycle.


=head1 CONSTRUCTOR

=over

=item C<< new(-source => $source_code, '-filename-override' => $filename, '-program-extensions' => [program_extensions]) >>

Create a new instance referencing a PPI::Document instance.  The
C<$source_code> can be the name of a file, a reference to a scalar
containing actual source code, or a L<PPI::Document|PPI::Document> or
L<PPI::Document::File|PPI::Document::File>.

In the event that C<$source_code> is a reference to a scalar containing actual
source code or a L<PPI::Document|PPI::Document>, the resulting
L<Perl::Critic::Document|Perl::Critic::Document> will not have a filename.
This may cause L<Perl::Critic::Document|Perl::Critic::Document> to incorrectly
classify the source code as a module or script.  To avoid this problem, you
can optionally set the C<-filename-override> to force the
L<Perl::Critic::Document|Perl::Critic::Document> to have a particular
C<$filename>.  Do not use this option if C<$source_code> is already the name
of a file, or is a reference to a L<PPI::Document::File|PPI::Document::File>.

The '-program-extensions' argument is optional, and is a reference to a list
of strings and/or regular expressions. The strings will be made into regular
expressions matching the end of a file name, and any document whose file name
matches one of the regular expressions will be considered a program.

If -program-extensions is not specified, or if it does not determine the
document type, the document will be considered to be a program if the source
has a shebang line or its file name (if any) matches C<< m/ [.] PL \z /smx >>.

=back

=head1 METHODS

=over

=item C<< ppi_document() >>

Accessor for the wrapped PPI::Document instance.  Note that altering
this instance in any way can cause unpredictable failures in
Perl::Critic's subsequent analysis because some caches may fall out of
date.


=item C<< find($wanted) >>

=item C<< find_first($wanted) >>

=item C<< find_any($wanted) >>

Caching wrappers around the PPI methods.  If C<$wanted> is a simple PPI class
name, then the cache is employed. Otherwise we forward the call to the
corresponding method of the C<PPI::Document> instance.


=item C<< namespaces() >>

Returns a list of the namespaces (package names) in the document.


=item C<< subdocuments_for_namespace($namespace) >>

Returns a list of sub-documents containing the elements in the given
namespace.  For example, given that the current document is for the source

    foo();
    package Foo;
    package Bar;
    package Foo;

this method will return two L<Perl::Critic::Document|Perl::Critic::Document>s
for a parameter of C<"Foo">.  For more, see
L<PPIx::Utilities::Node/split_ppi_node_by_namespace>.


=item C<< ppix_regexp_from_element($element) >>

Caching wrapper around C<< PPIx::Regexp->new($element) >>.  If
C<$element> is a C<PPI::Element> the cache is employed, otherwise it
just returns the results of C<< PPIx::Regexp->new() >>.  In either case,
it returns C<undef> unless the argument is something that
L<PPIx::Regexp|PPIx::Regexp> actually understands.

=item C<< element_is_in_lexical_scope_after_statement_containing( $inner, $outer ) >>

Is the C<$inner> element in lexical scope after the statement containing
the C<$outer> element?

In the case where C<$outer> is itself a scope-defining element, returns true
if C<$outer> contains C<$inner>. In any other case, C<$inner> must be
after the last element of the statement containing C<$outer>, and the
innermost scope for C<$outer> also contains C<$inner>.

This is not the same as asking whether C<$inner> is visible from
C<$outer>.


=item C<< filename() >>

Returns the filename for the source code if applicable
(PPI::Document::File) or C<undef> otherwise (PPI::Document).


=item C<< isa( $classname ) >>

To be compatible with other modules that expect to get a
PPI::Document, the Perl::Critic::Document class masquerades as the
PPI::Document class.


=item C<< highest_explicit_perl_version() >>

Returns a L<version|version> object for the highest Perl version
requirement declared in the document via a C<use> or C<require>
statement.  Returns nothing if there is no version statement.


=item C<< uses_module($module_or_pragma_name) >>

Answers whether there is a C<use>, C<require>, or C<no> of the given name in
this document.  Note that there is no differentiation of modules vs. pragmata
here.


=item C<< process_annotations() >>

Causes this Document to scan itself and mark which lines &
policies are disabled by the C<"## no critic"> annotations.


=item C<< line_is_disabled_for_policy($line, $policy_object) >>

Returns true if the given C<$policy_object> or C<$policy_name> has
been disabled for at C<$line> in this Document.  Otherwise, returns false.


=item C<< add_annotation( $annotation ) >>

Adds an C<$annotation> object to this Document.


=item C<< annotations() >>

Returns a list containing all the
L<Perl::Critic::Annotation|Perl::Critic::Annotation>s that
were found in this Document.


=item C<< add_suppressed_violation($violation) >>

Informs this Document that a C<$violation> was found but not reported
because it fell on a line that had been suppressed by a C<"## no critic">
annotation. Returns C<$self>.


=item C<< suppressed_violations() >>

Returns a list of references to all the
L<Perl::Critic::Violation|Perl::Critic::Violation>s
that were found in this Document but were suppressed.


=item C<< is_program() >>

Returns whether this document is considered to be a program.


=item C<< is_module() >>

Returns whether this document is considered to be a Perl module.

=back

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006-2011 Chris Dolan.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
