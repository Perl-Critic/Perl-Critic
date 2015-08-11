package Perl::Critic::Policy::ControlStructures::ProhibitUnlessBlocks;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{"unless" block used};
Readonly::Scalar my $EXPL => [ 97 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                         }
sub default_severity     { return $SEVERITY_LOW              }
sub default_themes       { return qw(core pbp cosmetic)      }
sub applies_to           { return 'PPI::Statement::Compound' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    if ( $elem->first_element() eq 'unless' ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }
    return;    #ok!
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ControlStructures::ProhibitUnlessBlocks - Write C<if(! $condition)> instead of C<unless($condition)>.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Conway discourages using C<unless> because it leads to
double-negatives that are hard to understand.  Instead, reverse the
logic and use C<if>.

    unless($condition) { do_something() } #not ok
    unless(! $no_flag) { do_something() } #really bad
    if( ! $condition)  { do_something() } #ok

This Policy only covers the block-form of C<unless>.  For the postfix
variety, see C<ProhibitPostfixControls>.


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 SEE ALSO

L<Perl::Critic::Policy::ControlStructures::ProhibitPostfixControls|Perl::Critic::Policy::ControlStructures::ProhibitPostfixControls>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>

=head1 COPYRIGHT

Copyright (c) 2005-2011 Imaginative Software Systems.  All rights reserved.

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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
