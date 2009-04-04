##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Document;

use 5.006001;
use strict;
use warnings;

use Carp qw< confess >;

use PPI::Document;
use PPI::Document::File;

use List::Util qw< reduce >;
use Scalar::Util qw< blessed weaken >;
use version;

use Perl::Critic::Annotation;
use Perl::Critic::Exception::Parse qw{ throw_parse };


#-----------------------------------------------------------------------------
# Load our optimization hacks, but only if we're using a version of PPI
# that we know is compatible.  TODO: Should we do this at compile time?

if ($PPI::Document::VERSION eq '1.203') {
    require Perl::Critic::PPIx::SpeedHacks;
}

#-----------------------------------------------------------------------------

our $VERSION = '1.098';

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
    return $self->_init(@args);
}

#-----------------------------------------------------------------------------

sub _init {

    my ($self, $source_code) = @_;

    # $source_code can be a file name, or a reference to a
    # PPI::Document, or a reference to a scalar containing source
    # code.  In the last case, PPI handles the translation for us.

    my $doc = _is_ppi_doc( $source_code ) ? $source_code
              : ref $source_code ? PPI::Document->new($source_code)
              : PPI::Document::File->new($source_code);

    # Bail on error
    if ( not defined $doc ) {
        my $errstr   = PPI::Document::errstr();
        my $file     = ref $source_code ? undef : $source_code;
        throw_parse
            message     => qq<Can't parse code: $errstr>,
            file_name   => $file;
    }

    $self->{_doc} = $doc;
    $self->{_annotations} = [];
    $self->{_suppressed_violations} = [];
    $self->{_disabled_line_map} = {};
    $self->index_locations();
    $self->_disable_shebang_fix();

    return $self;
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

sub filename {
    my ($self) = @_;
    my $doc = $self->{_doc};
    return $doc->can('filename') ? $doc->filename() : undef;
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
                map { version->new( $_->version() ) }
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
# PRIVATE functions & methods

sub _is_a_version_statement {
    my (undef, $element) = @_;

    return 0 if not $element->isa('PPI::Statement::Include');
    return 1 if $element->version();
    return 0;
}

#-----------------------------------------------------------------------------

sub _disable_shebang_fix {
    my ($self) = @_;

    # When you install a script using ExtUtils::MakeMaker or Module::Build, it
    # inserts some magical code into the top of the file (just after the
    # shebang).  This code allows people to call your script using a shell,
    # like `sh my_script`.  Unfortunately, this code causes several Policy
    # violations, so we disable them as if they had "## no critic" annotations.

    my $first_stmnt = $self->schild(0) || return;

    # Different versions of MakeMaker and Build use slightly different shebang
    # fixing strings.  This matches most of the ones I've found in my own Perl
    # distribution, but it may not be bullet-proof.

    my $fixin_rx = qr<^eval 'exec .* \$0 \${1\+"\$@"}'\s*[\r\n]\s*if.+;>ms; ## no critic (ExtendedFormatting)
    if ( $first_stmnt =~ $fixin_rx ) {
        my $line = $first_stmnt->location->[0];
        $self->{_disabled_line_map}->{$line}->{ALL} = 1;
        $self->{_disabled_line_map}->{$line + 1}->{ALL} = 1;
    }

    return $self;
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
    $doc = Perl::Critic::Document->new($doc);
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
write C<my $source = $doc->content();>

Perhaps there is a CPAN module out there which implements a facade
better than we do here?


=head1 INTERFACE SUPPORT

This is considered to be a public class.  Any changes to its interface
will go through a deprecation cycle.


=head1 CONSTRUCTOR

=over

=item C<< new($source_code) >>

Create a new instance referencing a PPI::Document instance.  The
C<$source_code> can be the name of a file, a reference to a scalar
containing actual source code, or a L<PPI::Document> or
L<PPI::Document::File>.

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

If C<$wanted> is a simple PPI class name, then the cache is employed.
Otherwise we forward the call to the corresponding method of the
C<PPI::Document> instance.


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

=item C<< process_annotations() >>

Causes this Document to scan itself and mark which lines &
policies are disabled by the C<"## no critic"> annotations.

=item C<< line_is_disabled_for_policy($line, $policy_object) >>

Returns true if the given C<$policy_object> or C<$policy_name> has
been disabled for at C<$line> in this Document.  Otherwise, returns false.

=item C<< add_annotation( $annotation ) >>

Adds an C<$annotation> object to this Document.

=item C<< annotations() >>

Returns a list containing all the L<Perl::Critic::Annotation> that
were found in this Document.

=item C<< add_suppressed_violation($violation) >>

Informs this Document that a C<$violation> was found but not reported
because it fell on a line that had been suppressed by a C<"## no critic">
annotation. Returns C<$self>.

=item C<< suppressed_violations() >>

Returns a list of references to all the L<Perl::Critic::Violation>s
that were found in this Document but were suppressed.

=back

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006-2009 Chris Dolan.

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
