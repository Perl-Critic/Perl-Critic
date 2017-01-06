package Perl::Critic::Policy::ValuesAndExpressions::RequireNumberSeparators;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Long number not separated with underscores};
Readonly::Scalar my $EXPL => [ 59 ];

#-----------------------------------------------------------------------------

Readonly::Scalar my $MINIMUM_INTEGER_WITH_MULTIPLE_DIGITS => 10;

sub supported_parameters {
    return (
        {
            name            => 'min_value',
            description     => 'The minimum absolute value to require separators in.',
            default_string  => '10_000',
            behavior        => 'integer',
            integer_minimum => $MINIMUM_INTEGER_WITH_MULTIPLE_DIGITS,
        },
    );
}

sub default_severity  { return $SEVERITY_LOW           }
sub default_themes    { return qw( core pbp cosmetic ) }
sub applies_to        { return 'PPI::Token::Number'    }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    my $min = $self->{_min_value};

    return if $elem !~ m{ \d{4} }xms;
    return if abs $elem->literal() < $min;

    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::RequireNumberSeparators - Write C< 141_234_397.0145 > instead of C< 141234397.0145 >.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Long numbers can be difficult to read.  To improve legibility, Perl
allows numbers to be split into groups of digits separated by
underscores.  This policy requires number sequences of more than three
digits to be separated.

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
