package Perl::Critic::Violation;

use strict;
use warnings;
use Carp;
use IO::String;
use Pod::PlainText;
use Perl::Critic::Utils;
use String::Format qw(stringf);
use English qw(-no_match_vars);
use overload q{""} => 'to_string';

our $VERSION = '0.13';
$VERSION = eval $VERSION;    ## no critic

#Class variables...
our $FORMAT = "%m at line %l, column %c. %e.\n"; #Default stringy format
our %DIAGNOSTICS = ();  #Cache of diagnositc messages

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


sub new {

    #Check arguments to help out developers who might
    #be creating new Perl::Critic::Policy modules.

    if ( @_ != 4 ) {
        my $msg = 'Wrong number of args to Violation->new()';
        croak $msg;
    }

    if ( ref $_[3] ne 'ARRAY' ) {
        my $msg = '3rd arg to Violation->new() must be ARRAY ref';
        croak $msg;
    }

    #Create object
    my ( $class, $desc, $expl, $loc ) = @_;
    my $self = bless {}, $class;
    $self->{_description} = $desc;
    $self->{_explanation} = $expl;
    $self->{_location}    = $loc;
    $self->{_policy}      = caller;

    return $self;
}

#---------------------------

sub location { 
    my $self = shift;
    return $self->{_location};
}

#---------------------------

sub diagnostics { 
    my $self = shift;
    my $pol = $self->policy();
    return $DIAGNOSTICS{$pol};
}

#---------------------------

sub description { 
    my $self = shift; 
    return $self->{_description};
}

#---------------------------

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

#---------------------------

sub policy { 
    my $self = shift;
    return $self->{_policy};
}

#---------------------------

sub to_string {
    my $self = shift;
    my %fspec = ( l => $self->location->[0], c => $self->location->[1],
		  m => $self->description(), e => $self->explanation(),
		  p => $self->policy(),      d => $self->diagnostics(), 
    );
    return stringf($FORMAT, %fspec);
}

#---------------------------

sub _mod2file {
    my $module = shift;
    $module  =~ s{::}{/}mxg;         
    $module .= '.pm';
    return $INC{$module} || $EMPTY;
}

#---------------------------

sub _get_diagnostics {

    my $file = shift;

    # Extract POD out to a filehandle
    my $handle = IO::String->new();         
    my $parser = Pod::PlainText->new();
    $parser->select('DESCRIPTION');    
    $parser->parse_from_file($file, $handle);

    # Slurp POD back in
    $handle->pos(0);                              #Rewind to the beginning.
    <$handle>;                                    #Throw away header
    return do { local $RS = undef; <$handle> };   #Slurp in the rest
}

1;

#----------------------------------------------------------------------------

__END__

=head1 NAME

Perl::Critic::Violation - Represents policy violations

=head1 SYNOPSIS

  use PPI;
  use Perl::Critic::Violation;

  my $loc  = $node->location();   #$node is a PPI::Node object
  my $desc = 'Offending code';    #Describe the violation
  my $expl = [1,45,67];           #Page numbers from PBB
  my $vio  = Perl::Critic::Violation->new($desc, $expl, $loc);

=head1 DESCRIPTION

Perl::Critic::Violation is the generic represntation of an individual
Policy violation.  Its primary purpose is to provide an abstraction
layer so that clients of L<Perl::Critic> don't have to know anything
about L<PPI>.  The C<violations> method of all L<Perl::Critic::Policy>
subclasses must return a list of these Perl::Critic::Violation
objects.

=head1 CONSTRUCTOR

=over 8

=item new( $description, $explanation, $location )

Retruns a reference to a new C<Perl::Critic::Violation> object. The
arguments are a description of the violation (as string), an
explanation for the policy (as string) or a series of page numbers in
PBB (as an ARRAY ref), and the location of the violation (as an ARRAY
ref).  The C<$location> must have two elements, representing the line
and column number, in that order.

=back

=head1 METHODS

=over 8

=item description ( void )

Returns a brief description of the policy that has been volated as a string.

=item explanation( void )

Returns the explanation for this policy as a string or as reference to
an array of page numbers in PBB.

=item location( void )

Returns a two-element list containing the line and column number where the 
violation occurred.

=item diagnostics( void )

This feature is experimental.  Returns a formatted string containing a
full discussion of the motivation, and details of the Policy module
that created this Violation.  This information is automatically
extracted from the DESCRIPTION section of the Policy module's POD.

=item policy( void )

Returns the name of the Perl::Critic::Policy module that created this Violation.

=item to_string( void )

Returns a string repesentation of this violation.  The content of the
string depends on the current value of the C<$FORMAT> package
variable.  See C<"OVERLOADS"> for the details.

=back

=head1 FIELDS

=over 8

=item $Perl::Critic::Violation::FORMAT

Sets the format for all Violation objects when they are evaluated in
string context.  The default is C<'%d at line %l, column %c. %e'>.
See L<"OVERLOADS"> for formatting options.  If you want to change
C<$FORMAT>, you should localize it first.

=back

=head1 OVERLOADS

Perl::Critic::Violation overloads the "" operator to produce neat
little messages when evaluated in string context.  The format
depends on the current value of the C<$FORMAT> package variable.

Formats are a combination of literal and escape characters similar to
the way C<sprintf> works.  If you want to know the specific formatting
capabilities, look at L<String::Format>. Valid escape characters are:

  Escape    Meaning
  -------   -------------------------------------------------------
  %m        Brief description of the violation
  %l        Line number where the violation occured
  %c        Column number where the violation occured
  %e        Explanation of violation or page numbers in PBP
  %d        Full diagnostic discussion of the violation
  %p        Name of the Policy module that created the violation

Here are some examples:
  
  $Perl::Critic::Violation::FORMAT = "%m at line %l, column %c.\n"; 
  #looks like "Mixed case variable name at line 6, column 23."

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

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
