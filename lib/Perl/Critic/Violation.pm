##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Violation;

use strict;
use warnings;
use English qw(-no_match_vars);
use Readonly;

use File::Basename qw(basename);
use IO::String qw();
use Pod::PlainText qw();
use String::Format qw(stringf);
use overload ( q{""} => 'to_string', cmp => '_compare' );

use Perl::Critic::Utils qw{ :characters :internal_lookup };
use Perl::Critic::Exception::Fatal::Internal qw{ &throw_internal };

our $VERSION = 1.06;

#Class variables...
our $FORMAT = "%m at line %l, column %c. %e.\n"; #Default stringy format
my %DIAGNOSTICS = ();  #Cache of diagnostic messages

#-----------------------------------------------------------------------------

Readonly::Scalar my $CONSTRUCTOR_ARG_COUNT => 5;

sub new {
    my ( $class, $desc, $expl, $elem, $sev ) = @_;

    #Check arguments to help out developers who might
    #be creating new Perl::Critic::Policy modules.

    if ( @_ != $CONSTRUCTOR_ARG_COUNT ) {
        throw_internal 'Wrong number of args to Violation->new()';
    }

    if ( ! eval { $elem->isa( 'PPI::Element' ) } ) {

        if ( eval { $elem->isa( 'Perl::Critic::Document' ) } ) {
            # break the facade, return the real PPI::Document
            $elem = $elem->{_doc};
        }
        else {
            throw_internal
                '3rd arg to Violation->new() must be a PPI::Element';
        }
    }

    #Create object
    my $self = bless {}, $class;
    $self->{_description} = $desc;
    $self->{_explanation} = $expl;
    $self->{_severity}    = $sev;
    $self->{_policy}      = caller;
    $self->{_elem}        = $elem;

    # Do these now before the weakened $doc gets garbage collected
    my $top = $elem->top();
    $self->{_filename} = $top->can('filename') ? $top->filename() : undef;
    $self->{_source}   = _first_line_of_source( $elem );

    return $self;
}

#-----------------------------------------------------------------------------

sub set_format { return $FORMAT = verbosity_to_format( $_[0] ); }  ##no critic(ArgUnpacking)
sub get_format { return $FORMAT;         }

#-----------------------------------------------------------------------------

sub sort_by_location {  ##no critic(ArgUnpacking)

    ref $_[0] || shift;              #Can call as object or class method
    return scalar @_ if ! wantarray; #In case we are called in scalar context

    ## no critic qw(RequireSimpleSort);
    ## TODO: What if $a and $b are not Violation objects?
    return
        map {$_->[0]}
            sort { ($a->[1] <=> $b->[1]) || ($a->[2] <=> $b->[2]) }
                map {[$_, $_->location->[0] || 0, $_->location->[1] || 0]}
                    @_;
}

#-----------------------------------------------------------------------------

sub sort_by_severity {  ##no critic(ArgUnpacking)

    ref $_[0] || shift;              #Can call as object or class method
    return scalar @_ if ! wantarray; #In case we are called in scalar context

    ## no critic qw(RequireSimpleSort);
    ## TODO: What if $a and $b are not Violation objects?
    return
        map {$_->[0]}
            sort { $a->[1] <=> $b->[1] }
                map {[$_, $_->severity() || 0]}
                    @_;
}

#-----------------------------------------------------------------------------

sub location {
    my $self = shift;

    return $self->{_location} ||= $self->{_elem}->location() || [0,0,0];
}

#-----------------------------------------------------------------------------

sub diagnostics {
    my $self = shift;
    my $pol = $self->policy();
    if (!$DIAGNOSTICS{$pol}) {
        if ( my $file = _mod2file($pol) ) {
            if ( my $diags = _get_diagnostics($file) ) {
               $DIAGNOSTICS{$pol} = $diags;
            }
        }
        $DIAGNOSTICS{$pol} ||= "    No diagnostics available\n";
    }
    return $DIAGNOSTICS{$pol};
}

#-----------------------------------------------------------------------------

sub description {
    my $self = shift;
    return $self->{_description};
}

#-----------------------------------------------------------------------------

sub explanation {
    my $self = shift;
    my $expl = $self->{_explanation};
    if ( !$expl ) {
       $expl = '(no explanation)';
    }
    if ( ref $expl eq 'ARRAY' ) {
        my $page = @{$expl} > 1 ? 'pages' : 'page';
        $page .= $SPACE . join $COMMA, @{$expl};
        $expl = "See $page of PBP";
    }
    return $expl;
}

#-----------------------------------------------------------------------------

sub severity {
    my $self = shift;
    return $self->{_severity};
}

#-----------------------------------------------------------------------------

sub policy {
    my $self = shift;
    return $self->{_policy};
}

#-----------------------------------------------------------------------------

sub filename {
    my $self = shift;
    return $self->{_filename};
}

#-----------------------------------------------------------------------------


sub source {
    my $self = shift;
    return $self->{_source};
}

#-----------------------------------------------------------------------------

sub to_string {
    my $self = shift;

    my $long_policy = $self->policy();
    (my $short_policy = $long_policy) =~ s/ \A Perl::Critic::Policy:: //xms;

    # Wrap the more expensive ones in sub{} to postpone evaluation
    my %fspec = (
         'f' => sub { $self->filename() },
         'F' => sub { basename( $self->filename()) },
         'l' => sub { $self->location->[0] },
         'c' => sub { $self->location->[1] },
         'm' => $self->description(),
         'e' => $self->explanation(),
         's' => $self->severity(),
         'd' => sub { $self->diagnostics() },
         'r' => sub { $self->source() },
         'P' => $long_policy,
         'p' => $short_policy,
    );
    return stringf($FORMAT, %fspec);
}

#-----------------------------------------------------------------------------
# Apparently, some perls do not implicitly stringify overloading
# objects before doing a comparison.  This causes a couple of our
# sorting tests to fail.  To work around this, we overload C<cmp> to
# do it explicitly.
#
# 20060503 - More information:  This problem has been traced to
# Test::Simple versions <= 0.60, not perl itself.  Upgrading to
# Test::Simple v0.62 will fix the problem.  But rather than forcing
# everyone to upgrade, I have decided to leave this workaround in
# place.

sub _compare { return "$_[0]" cmp "$_[1]" }

#-----------------------------------------------------------------------------

sub _mod2file {
    my $module = shift;
    $module  =~ s{::}{/}mxg;
    $module .= '.pm';
    return $INC{$module} || $EMPTY;
}

#-----------------------------------------------------------------------------

sub _get_diagnostics {

    my $file = shift;

    (my $podfile = $file) =~ s{\.[^\.]+ \z}{.pod}mx;
    if (-f $podfile)
    {
       $file = $podfile;
    }
    # Extract POD into a string
    my $pod_string = $EMPTY;
    my $handle     = IO::String->new( \$pod_string );
    my $parser     = Pod::PlainText->new();
    $parser->select('DESCRIPTION');

    # Use parse_from_filehandle instead of parse_from_file as a
    # workaround for RT bug #21009 and #21010, which document a bad
    # interaction with Devel::Cover 0.58 and
    # Pod::Parser::parse_from_file
    return $EMPTY if not (open my $fh, '<', $file);
    $parser->parse_from_filehandle( $fh, $handle );

    # Remove header and trailing whitespace.
    $pod_string =~ s{ \A \s* DESCRIPTION \s* \n}{}mx;
    $pod_string =~ s{ \s* \z}{}mx;
    return $pod_string;
}

#-----------------------------------------------------------------------------

sub _first_line_of_source {
    my $elem = shift;

    my $stmnt = $elem->statement() || $elem;
    my $code_string = $stmnt->content() || $EMPTY;

    #Chop everything but the first line (without newline);
    $code_string =~ s{ \n.* }{}smx;
    return $code_string;
}


1;

#-----------------------------------------------------------------------------

__END__

=head1 NAME

Perl::Critic::Violation - Represents policy violations

=head1 SYNOPSIS

  use PPI;
  use Perl::Critic::Violation;

  my $elem = $doc->child(0);      #$doc is a PPI::Document object
  my $desc = 'Offending code';    #Describe the violation
  my $expl = [1,45,67];           #Page numbers from PBP
  my $sev  = 5;                   #Severity level of this violation

  my $vio  = Perl::Critic::Violation->new($desc, $expl, $node, $sev);

=head1 DESCRIPTION

Perl::Critic::Violation is the generic representation of an individual
Policy violation.  Its primary purpose is to provide an abstraction
layer so that clients of L<Perl::Critic> don't have to know anything
about L<PPI>.  The C<violations> method of all L<Perl::Critic::Policy>
subclasses must return a list of these Perl::Critic::Violation
objects.

=head1 CONSTRUCTOR

=over 8

=item C<new( $description, $explanation, $element, $severity )>

Returns a reference to a new C<Perl::Critic::Violation> object. The
arguments are a description of the violation (as string), an
explanation for the policy (as string) or a series of page numbers in
PBP (as an ARRAY ref), a reference to the L<PPI> element that caused
the violation, and the severity of the violation (as an integer).

=back

=head1 METHODS

=over 8

=item C<description()>

Returns a brief description of the policy that has been violated as a string.

=item C<explanation()>

Returns an explanation of the policy as a string or as reference to
an array of page numbers in PBP.

=item C<location()>

Returns a three-element array reference containing the line and real
& virtual column numbers where this Violation occurred, as in
L<PPI::Element>.

=item C<filename()>

Returns the path to the file where this Violation occurred.  In some
cases, the path may be undefined because the source code was not read
directly from a file.

=item C<severity()>

Returns the severity of this Violation as an integer ranging from 1 to
5, where 5 is the "most" severe.

=item C<sort_by_severity( @violation_objects )>

If you need to sort Violations by severity, use this handy routine:

   @sorted = Perl::Critic::Violation::sort_by_severity(@violations);

=item C<sort_by_location( @violation_objects )>

If you need to sort Violations by location, use this handy routine:

   @sorted = Perl::Critic::Violation::sort_by_location(@violations);

=item C<diagnostics()>

Returns a formatted string containing a full discussion of the
motivation for and details of the Policy module that created this
Violation.  This information is automatically extracted from the
C<DESCRIPTION> section of the Policy module's POD.

=item C<policy()>

Returns the name of the L<Perl::Critic::Policy> that created this
Violation.

=item C<source()>

Returns the string of source code that caused this exception.  If the
code spans multiple lines (e.g. multi-line statements, subroutines or
other blocks), then only the first line will be returned.

=item C<set_format( $FORMAT )>

Class method.  Sets the format for all Violation objects when they are
evaluated in string context.  The default is C<'%d at line %l, column
%c. %e'>.  See L<"OVERLOADS"> for formatting options.

=item C<get_format()>

Class method. Returns the current format for all Violation objects
when they are evaluated in string context.

=item C<to_string()>

Returns a string representation of this violation.  The content of the
string depends on the current value of the C<$FORMAT> package
variable.  See L<"OVERLOADS"> for the details.

=back

=head1 FIELDS

=over 8

=item C<$Perl::Critic::Violation::FORMAT>

B<DEPRECATED:> Use the C<set_format> and C<get_format> methods instead.

Sets the format for all Violation objects when they are evaluated in string
context.  The default is C<'%d at line %l, column %c. %e'>.  See
L<"OVERLOADS"> for formatting options.  If you want to change C<$FORMAT>, you
should probably localize it first.

=back

=head1 OVERLOADS

Perl::Critic::Violation overloads the C<""> operator to produce neat
little messages when evaluated in string context.  The format depends
on the current value of the C<$FORMAT> package variable.

Formats are a combination of literal and escape characters similar to
the way C<sprintf> works.  If you want to know the specific formatting
capabilities, look at L<String::Format>. Valid escape characters are:

    Escape    Meaning
    -------   ----------------------------------------------------------------
    %c        Column number where the violation occurred
    %d        Full diagnostic discussion of the violation
    %e        Explanation of violation or page numbers in PBP
    %F        Just the name of the file where the violation occurred.
    %f        Path to the file where the violation occurred.
    %l        Line number where the violation occurred
    %m        Brief description of the violation
    %P        Full name of the Policy module that created the violation
    %p        Name of the Policy without the Perl::Critic::Policy:: prefix
    %r        The string of source code that caused the violation
    %s        The severity level of the violation

Here are some examples:

  $Perl::Critic::Violation::FORMAT = "%m at line %l, column %c.\n";
  #looks like "Mixed case variable name at line 6, column 23."

  $Perl::Critic::Violation::FORMAT = "%m near '%r'\n";
  #looks like "Mixed case variable name near 'my $theGreatAnswer = 42;'"

  $Perl::Critic::Violation::FORMAT = "%l:%c:%p\n";
  #looks like "6:23:NamingConventions::ProhibitMixedCaseVars"

  $Perl::Critic::Violation::FORMAT = "%m at line %l. %e. \n%d\n";
  #looks like "Mixed case variable name at line 6.  See page 44 of PBP.
                    Conway's recommended naming convention is to use lower-case words
                    separated by underscores.  Well-recognized acronyms can be in ALL
                    CAPS, but must be separated by underscores from other parts of the
                    name."

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2007 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
