##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::Variables::RequireLexicalLoopIterators;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.105';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Loop iterator is not lexical};
Readonly::Scalar my $EXPL => [ 108 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                         }
sub default_severity     { return $SEVERITY_HIGHEST          }
sub default_themes       { return qw(core pbp bugs)          }
sub applies_to           { return 'PPI::Statement::Compound' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    # First child will be 'for' or 'foreach' keyword
    return if $elem->type() ne 'foreach';

    my $first_child = $elem->schild(0);
    return if not $first_child;
    my $start = $first_child->isa('PPI::Token::Label') ? 1 : 0;

    my $potential_scope = $elem->schild($start + 1);
    return if not $potential_scope;
    return if $potential_scope->isa('PPI::Structure::List');

    return if $potential_scope eq 'my';

    return $self->violation( $DESC, $EXPL, $elem );
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Variables::RequireLexicalLoopIterators - Write C<for my $element (@list) {...}> instead of C<for $element (@list) {...}>.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

C<for>/C<foreach> loops I<always> create new lexical variables for
named iterators.  In other words

    for $zed (...) {
        ...
    }

is equivalent to

    for my $zed (...) {
        ...
    }

This may not seem like a big deal until you see code like

    my $bicycle;
    for $bicycle (@things_attached_to_the_bike_rack) {
        if (
                $bicycle->is_red()
            and $bicycle->has_baseball_card_in_spokes()
            and $bicycle->has_bent_kickstand()
        ) {
            $bicycle->remove_lock();

            last;
        }
    }

    if ( $bicycle and $bicycle->is_unlocked() ) {
        ride_home($bicycle);
    }

which is not going to allow you to arrive in time for dinner with your
family because the C<$bicycle> outside the loop is different from the
C<$bicycle> inside the loop.  You may have freed your bicycle, but you
can't remember which one it was.


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2005-2009 Jeffrey Ryan Thalhammer.  All rights reserved.

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
