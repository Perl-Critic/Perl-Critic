#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
########################################################################

package Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseSubs;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.13_01';
$VERSION = eval $VERSION;    ## no critic

#---------------------------------------------------------------------------

my $mixed_rx = qr/ [A-Z][a-z] | [a-z][A-Z] /x;
my $desc     = 'Mixed-case subroutine name';
my $expl     = [ 44 ];

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_LOWEST }
sub applies_to { return 'PPI::Statement::Sub' }

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;
    if ( $elem->name() =~ $mixed_rx ) {
        my $sev = $self->get_severity();
        return Perl::Critic::Violation->new( $desc, $expl, $elem, $sev );
    }
    return;    #ok!
}

1;

__END__

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseSubs

=head1 DESCRIPTION

Conway's recommended naming convention is to use lower-case words
separated by underscores.  Well-recognized acronyms can be in ALL
CAPS, but must be separated by underscores from other parts of the
name.

  sub foo_bar{}   #ok
  sub foo_BAR{}   #ok
  sub FOO_bar{}   #ok
  sub FOO_BAR{}   #ok

  sub FooBar {}   #not ok
  sub FOObar {}   #not ok
  sub fooBAR {}   #not ok
  sub fooBar {}   #Not ok

=head1 SEE ALSO

L<Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseVars>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
