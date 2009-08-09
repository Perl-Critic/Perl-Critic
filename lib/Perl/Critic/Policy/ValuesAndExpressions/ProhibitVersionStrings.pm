##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::ValuesAndExpressions::ProhibitVersionStrings;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.103';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Version string used};
Readonly::Scalar my $EXPL => q{Use a real number instead};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                        }
sub default_severity     { return $SEVERITY_MEDIUM          }
sub default_themes       { return qw(core pbp maintenance)  }
sub applies_to           { return 'PPI::Statement::Include' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    if (
        (
                $elem->type() eq 'use'
            or  $elem->type() eq 'require'
        )
        and $elem->module ne 'lib'
    ) {

        # RT 44986 appears to require us to bite the bullet. So instead of
        # just a regular expression on the content of the element:

        # Check the second element, to see if it is a version string. If it
        # is, we have a violation. If it is any other sort of number, we
        # return with no violation.
        my $check = $elem->schild( 1 ) or return;
        _is_version_string( $check )
            and return $self->violation( $DESC, $EXPL, $elem );
        $check->isa( 'PPI::Token::Number' ) and return;

        # Check the third element. If it is a version string, return a
        # violation.
        $check = $check->snext_sibling();
        _is_version_string( $check )
            and return $self->violation( $DESC, $EXPL, $elem );

    }
    return;    #ok!
}

# TODO: Remove this when a released PPI properly supports version numbers (the
# current dev releases do support it).
sub _is_version_string {
    my ( $elem ) = @_;

    $elem or return;
    $elem->isa( 'PPI::Token::Number::Version' ) and return 1;

    # We could just return here, but PPI mis-parses v-strings with an actual
    # 'v' in front. So:
    $elem->isa( 'PPI::Token::Word' ) or return;
    $elem->content() =~ m/ \A v \d+ \z /smx or return;
    my $next = $elem->next_sibling()    # not snext, to disallow white space.
        or return;
    return $next->isa( 'PPI::Token::Number' );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitVersionStrings - Don't use strings like C<v1.4> or C<1.4.5> when including other modules.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Whenever you C<use> or C<require> a module, you can specify a minimum
version requirement.  To ensure compatibility with older Perls, this
version number should be expressed as a floating-point number.  Do not
use v-strings or three-part numbers.  The Perl convention for
expressing version numbers as floats is: version + (patch level /
1000).

    use Foo v1.2    qw(foo bar);  # not ok
    use Foo 1.2.03  qw(foo bar);  # not ok
    use Foo 1.00203 qw(foo bar);  # ok


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
