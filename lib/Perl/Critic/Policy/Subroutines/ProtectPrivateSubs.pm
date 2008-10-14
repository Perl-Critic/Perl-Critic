##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::Subroutines::ProtectPrivateSubs;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.093_01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Private subroutine/method used};
Readonly::Scalar my $EXPL => q{Use published APIs};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                     }
sub default_severity     { return $SEVERITY_MEDIUM       }
sub default_themes       { return qw( core maintenance ) }
sub applies_to           { return 'PPI::Token::Word'     }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    if (my $psib = $elem->sprevious_sibling()) {
        my $psib_name = $psib->content();
        return if $psib_name eq 'package';
        return if $psib_name eq 'require';
        return if $psib_name eq 'use';
    }

    if ( $self->_is_other_pkg_private_function($elem)
         || $self->_is_other_pkg_private_method($elem) )
    {
        return $self->violation( $DESC, $EXPL, $elem );
    }

    return;  # ok!
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

    # sometimes the previous sib is a keyword, as in:
    # shift->_private_method();  This is typically used as
    # shorthand for "my $self=shift; $self->_private_method()"
    return if $pkg eq 'shift' or $pkg eq '__PACKAGE__';

    return 1;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::ProtectPrivateSubs - Prevent access to private subs in other packages.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

By convention Perl authors (like authors in many other languages)
indicate private methods and variables by inserting a leading
underscore before the identifier.  This policy catches attempts to
access private variables from outside the package itself.


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 HISTORY

This policy is inspired by a similar test in L<B::Lint|B::Lint>


=head1 BUGS

Doesn't forbid C<< $pkg->_foo() >> because it can't tell the
difference between that and C<< $self->_foo() >>


=head1 SEE ALSO

L<Perl::Critic::Policy::Variables::ProtectPrivateVars|Perl::Critic::Policy::Variables::ProtectPrivateVars>


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006-2008 Chris Dolan.  All rights reserved.

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
