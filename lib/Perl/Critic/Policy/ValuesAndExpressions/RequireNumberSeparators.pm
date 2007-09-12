##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::ValuesAndExpressions::RequireNumberSeparators;

use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :booleans :severities };
use base 'Perl::Critic::Policy';

our $VERSION = 1.076;

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Long number not separated with underscores};
Readonly::Scalar my $EXPL => [ 59 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return qw( min_value )         }
sub default_severity  { return $SEVERITY_LOW           }
sub default_themes    { return qw( core pbp cosmetic ) }
sub applies_to        { return 'PPI::Token::Number'    }

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    my ($self, $config) = @_;

    #Set configuration, if defined
    $self->{_min} =
        defined $config->{min_value}
            ? $config->{min_value}
            : 10_000;

    return $TRUE;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    my $min = $self->{_min};

    return if $elem !~ m{ \d{4} }mx;
    return if abs _to_number($elem) < $min;

    return $self->violation( $DESC, $EXPL, $elem );
}

#-----------------------------------------------------------------------------

sub _to_number {
    my $elem  = shift;

    # TODO: when we can depend on PPI > v1.118, we can remove this if()
    if ( $elem->can('literal') ) {
        return $elem->literal();
    }

    # This eval is necessary because Perl only supports the underscore
    # during compilation, not numification.

    my $value = $elem->content;
    $value = eval $value;    ## no critic
    return $value;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::RequireNumberSeparators

=head1 DESCRIPTION

Long numbers can be difficult to read.  To improve legibility, Perl
allows numbers to be split into groups of digits separated by
underscores.  This policy requires number sequences of more than
three digits to be separated.

 $long_int = 123456789;   #not ok
 $long_int = 123_456_789; #ok

 $long_float = 12345678.001;   #not ok
 $long_float = 12_345_678.001; #ok

=head1 CONFIGURATION

The minimum absolute value of numbers that must contain separators can
be configured via the C<min_value> option.  The default is 10,000;
thus, all numbers >= 10,000 and <= -10,000 must have separators.  For
example:

  [ValuesAndExpressions::RequireNumberSeparators]
  min_value = 100000    # That's one-hundred-thousand!

=head1 NOTES

As it is currently written, this policy only works properly with
decimal (base 10) numbers.  And it is obviously biased toward Western
notation.  I'll try and address those issues in the future.

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
