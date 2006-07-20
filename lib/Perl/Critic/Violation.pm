#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Violation;

use strict;
use warnings;
use Carp;
use IO::String;
use Pod::PlainText;
use Perl::Critic::Utils;
use String::Format qw(stringf);
use English qw(-no_match_vars);
use overload ( q{""} => q{to_string}, cmp => q{_compare} );

our $VERSION = '0.18';
$VERSION = eval $VERSION;    ## no critic

#Class variables...
our $FORMAT = "%m at line %l, column %c. %e.\n"; #Default stringy format
my %DIAGNOSTICS = ();  #Cache of diagnostic messages

#----------------------------------------------------------------------------

sub import {

    my $caller = caller;
    return if exists $DIAGNOSTICS{$caller};

    if ( my $file = _mod2file($caller) ) {
        if ( my $diags = _get_diagnostics($file) ) {
               $DIAGNOSTICS{$caller} = $diags;
               return; #ok!
           }
    }

    #If we get here, then we couldn't get diagnostics
    my $no_diags = "    No diagnostics available\n";
    $DIAGNOSTICS{$caller} = $no_diags;

    return; #ok!
}

#----------------------------------------------------------------------------

sub new {
    my ( $class, $desc, $expl, $elem, $sev ) = @_;

    #Check arguments to help out developers who might
    #be creating new Perl::Critic::Policy modules.

    if ( @_ != 5 ) {
        my $msg = 'Wrong number of args to Violation->new()';
        croak $msg;
    }

    if ( ! eval { $elem->isa( 'PPI::Element' ) } ) {

        if ( eval { $elem->isa( 'Perl::Critic::Document' ) } ) {
            # break the facade, return the real PPI::Document
            $elem = $elem->{_doc};
        }
        else {
            my $msg = '3rd arg to Violation->new() must be a PPI::Element';
            croak $msg;
        }
    }

    #Create object
    my $self = bless {}, $class;
    $self->{_description} = $desc;
    $self->{_explanation} = $expl;
    $self->{_severity}    = $sev;
    $self->{_policy}      = caller;
    $self->{_location}    = $elem->location() || [0,0];

    my $stmnt = $elem->statement() || $elem;
    $self->{_source} = $stmnt->content() || $EMPTY;


    return $self;
}

#-----------------------------------------------------------------------------

sub set_format { return $FORMAT = $_[0]; }
sub get_format { return $FORMAT;         }

#-----------------------------------------------------------------------------

sub sort_by_location {

    ref $_[0] || shift;              #Can call as object or class method
    return scalar @_ if ! wantarray; #In case we are called in scalar context

    ## no critic qw(RequireSimpleSort);
    ## TODO: What if $a and $b are not Violation objects?
    return sort {   (($a->location->[0] || 0) <=> ($b->location->[0] || 0))
                 || (($a->location->[1] || 0) <=> ($b->location->[1] || 0)) } @_;
}

#-----------------------------------------------------------------------------

sub sort_by_severity {

    ref $_[0] || shift;              #Can call as object or class method
    return scalar @_ if ! wantarray; #In case we are called in scalar context

    ## no critic qw(RequireSimpleSort);
    ## TODO: What if $a and $b are not Violation objects?
    return sort { ($a->severity() || 0) <=> ($b->severity() || 0) } @_;
}

#-----------------------------------------------------------------------------

sub location {
    my $self = shift;
    return $self->{_location};
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
    if( ref $expl eq 'ARRAY' ) {
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

sub source {
     my $self = shift;
     my $source = $self->{_source};
     #Return the first line of code only.
     $source =~ m{\A ( [^\n]* ) }mx;
     return $1;
}

#-----------------------------------------------------------------------------

sub to_string {
    my $self = shift;

    my $short_policy = $self->policy();
    $short_policy =~ s/ \A Perl::Critic::Policy:: //xms;

    my %fspec = (
         'l' => $self->location->[0], 'c' => $self->location->[1],
         'm' => $self->description(), 'e' => $self->explanation(),
         'P' => $self->policy(),      'd' => $self->diagnostics(),
         's' => $self->severity(),    'r' => $self->source(),
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
    $parser->parse_from_file( $file, $handle );

    # Remove header and trailing whitespace.
    $pod_string =~ s{ \A \s* DESCRIPTION \s* }{}smx;
    $pod_string =~ s{ \s* \z}{}smx;
    return $pod_string;
}

1;

#----------------------------------------------------------------------------

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

Returns a two-element list containing the line and column number where
this Violation occurred.

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

This variable is deprecated.  Use the C<set_format> and C<get_format>
class methods instead.

Sets the format for all Violation objects when they are evaluated in
string context.  The default is C<'%d at line %l, column %c. %e'>.
See L<"OVERLOADS"> for formatting options.  If you want to change
C<$FORMAT>, you should probably localize it first.

=back

=head1 OVERLOADS

Perl::Critic::Violation overloads the C<""> operator to produce neat
little messages when evaluated in string context.  The format depends
on the current value of the C<$FORMAT> package variable.

Formats are a combination of literal and escape characters similar to
the way C<sprintf> works.  If you want to know the specific formatting
capabilities, look at L<String::Format>. Valid escape characters are:

  Escape    Meaning
  -------   -----------------------------------------------------------------
  %m        Brief description of the violation
  %f        Name of the file where the violation occurred.
  %l        Line number where the violation occurred
  %c        Column number where the violation occurred
  %e        Explanation of violation or page numbers in PBP
  %d        Full diagnostic discussion of the violation
  %r        The string of source code that caused the violation
  %P        Name of the Policy module that created the violation
  %p        Name of the Policy without the Perl::Critic::Policy:: prefix
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

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
