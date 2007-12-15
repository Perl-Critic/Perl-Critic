##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::CodeLayout::ProhibitHardTabs;

use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :booleans :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.081_001';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Hard tabs used};
Readonly::Scalar my $EXPL => [ 20 ];

my $DEFAULT_ALLOW_LEADING_TABS = $TRUE;

#-----------------------------------------------------------------------------

sub supported_parameters { return qw( allow_leading_tabs ) }
sub default_severity { return $SEVERITY_MEDIUM    }
sub default_themes   { return qw( core cosmetic ) }
sub applies_to       { return 'PPI::Token'        }

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    my ($self, $config) = @_;

    #Set config, if defined
    my $allow_leading_tabs = $config->{allow_leading_tabs};
    $self->{_allow_leading_tabs} =
        defined $allow_leading_tabs ? $allow_leading_tabs : $TRUE;

    return $TRUE;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    $elem =~ m{ \t }mx || return;

    # The __DATA__ element is exempt
    return if $elem->parent->isa('PPI::Statement::Data');

    # Permit leading tabs, if allowed
    return if $self->_allow_leading_tabs() && $elem->location->[1] == 1;

    # Must be a violation...
    return $self->violation( $DESC, $EXPL, $elem );
}

#-----------------------------------------------------------------------------

sub _allow_leading_tabs {
    my ( $self ) = @_;

    return $self->{_allow_leading_tabs};
}

1;

__END__

#-----------------------------------------------------------------------------

=head1 NAME

Perl::Critic::Policy::CodeLayout::ProhibitHardTabs

=head1 DESCRIPTION

Putting hard tabs in your source code (or POD) is one of the worst
things you can do to your co-workers and colleagues, especially if
those tabs are anywhere other than a leading position.  Because
various applications and devices represent tabs differently, they can
cause you code to look vastly different to other people.  Any decent
editor can be configured to expand tabs into spaces.  L<Perl::Tidy>
also does this for you.

This Policy catches all tabs in your source code, including POD,
quotes, and HEREDOCs.  The contents of the C<__DATA__> section are not
examined.

=head1 CONFIGURATION

Tabs in a leading position are allowed, but if you want to forbid all tabs
everywhere, put this to your F<.perlcriticrc> file:

    [CodeLayout::ProhibitHardTabs]
    allow_leading_tabs = 0

=head1 NOTES

Beware that Perl::Critic may report the location of the string that
contains the tab, not the actual location of the tab, so you may need
to do some hunting.  I'll try and fix this in the future.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2007 Jeffrey Ryan Thalhammer.  All rights reserved.

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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
