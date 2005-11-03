package Perl::Critic::Policy::ValuesAndExpressions::RequireNumberSeparators;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.13';
$VERSION = eval $VERSION;    ## no critic

my $desc = q{Long number not separated with underscores};
my $expl = [55];

#---------------------------------------------------------------------------

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;

    #Set configuration, if defined
    $self->{_min} = defined $args{min_value} ? $args{min_value} : 10_000;

    return $self;
}

sub violates {
    my ( $self, $elem, $doc ) = @_;
    $elem->isa('PPI::Token::Number') || return;
    my $min = $self->{_min};

    if ( abs _to_number($elem) >= $min && $elem =~ m{ \d{4,} }mx ) {
        return Perl::Critic::Violation->new( $desc, $expl, $elem->location() );
    }
    return;    #ok!
}

sub _to_number {
    my $elem  = shift;
    my $value = "$elem";
    return eval $value;    ## no critic
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::RequireNumberSeparators

=head1 DESCRIPTION

Long numbers are be hard to read.  To improve legibility, Perl allows
numbers to be split into groups of digits separated by underscores.
This policy requires numbers sequences of more than three digits to be
separated.

 $long_int = 123456789;   #not ok
 $long_int = 123_456_789; #ok

 $long_float = 12345678.001;   #not ok
 $long_float = 12_345_678.001; #ok

=head1 CONSTRUCTOR

This Policy accepts an additional key-value pair in the C<new> method.
The key is 'min_value' and the value is the minimum absolute value of
numbers that must be separated.  The default is 10,000.  Thus, all
numbers >= 10,000 and <= -10,000 must be separated.  Users of the
Perl::Critic engine can configure this in their F<.perlcriticrc> like
this:

  [ValuesAndExpressions::RequireNumberSeparators]
  min_value = 100000    #That's one-hundred-thousand!

=head1 NOTES

As it is currently written, this policy only works properly with
decimal (base 10) numbers.  And it is obviouly biased toward Western
notation.  I'll try and address those issues in the future.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
