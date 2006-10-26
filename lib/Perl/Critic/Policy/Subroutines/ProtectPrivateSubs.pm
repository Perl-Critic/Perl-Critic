#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::Subroutines::ProtectPrivateSubs;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.21;

#---------------------------------------------------------------------------

my $desc = q{Private variable used};
my $expl = q{Use published APIs};

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_MEDIUM   }
sub default_themes   { return qw(unreliable)     }
sub applies_to       { return 'PPI::Token::Word' }

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    my $psib = $elem->sprevious_sibling;
    my $psib_name = eval { $psib->content };
    no warnings 'uninitialized';    ## no critic ProhibitNoWarnings
    if (   $psib_name ne 'package'
        && $psib_name ne 'require'
        && $psib_name ne 'use'
        && (   $self->_is_other_pkg_private_function($elem)
            || $self->_is_other_pkg_private_method($elem) )
        )
    {
        return $self->violation( $desc, $expl, $elem );
    }
    return;                         #ok!
}

sub _is_other_pkg_private_function {
    my ( $self, $elem ) = @_;
    return $elem =~ m{ (\w+)::_\w+ \z }xms
        && $elem !~ m{ \A SUPER::_\w+ \z }xms;
}

sub _is_other_pkg_private_method {
    my ( $self, $elem ) = @_;

    # look for structures like "Some::Package->_foo()"
    $elem =~ m{ \A _\w+ \z }xms || return;
    my $op = $elem->sprevious_sibling() || return;
    $op eq q{->} || return;
    my $pkg = $op->sprevious_sibling() || return;
    $pkg->isa('PPI::Token::Word') || return;
    return 1;
}

1;

__END__

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::ProtectPrivateSubs

=head1 DESCRIPTION

By convention Perl authors (like authors in many other languages)
indicate private methods and variables by inserting a leading
underscore before the identifier.  This policy catches attempts to
access private variables from outside the package itself.

=head1 HISTORY

This policy is inspired by a similar test in L<B::Lint>

=head1 SEE ALSO

L<Perl::Critic::Policy::Subroutines::ProtectPrivateSubs>

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006 Chris Dolan.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
