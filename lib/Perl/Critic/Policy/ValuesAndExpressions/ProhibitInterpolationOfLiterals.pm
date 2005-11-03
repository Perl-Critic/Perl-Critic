
package Perl::Critic::Policy::ValuesAndExpressions::ProhibitInterpolationOfLiterals;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.13';
$VERSION = eval $VERSION;    ## no critic

my $desc = q{Useless interpolation of literal string};
my $expl = [51];

#---------------------------------------------------------------------------

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;
    $self->{_allow} = [];

    #Set configuration, if defined
    if ( defined $args{allow} ) {
	my @allow = split m{ \s+ }mx, $args{allow};
	#Try to be forgiving with the configuration...
	for (@allow) { m{ \A qq }mx || ($_ = 'qq' . $_) }  #Add 'qq'
	for (@allow) { (length $_ <= 3) || chop }    #Chop closing char
	$self->{_allow} = \@allow;
    }

    return $self;
}

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;
    $elem->isa('PPI::Token::Quote::Double')
      || $elem->isa('PPI::Token::Quote::Interpolate')
      || return;

    #Overlook allowed quote styles
    for my $allowed ( @{ $self->{_allow} } ) {
        return if $elem =~ m{ \A \Q$allowed\E }mx;
    }

    if ( !_has_interpolation($elem) ) {
        return Perl::Critic::Violation->new( $desc, $expl, $elem->location() );
    }
    return;    #ok!
}

sub _has_interpolation {
    my $elem = shift || return;
    return $elem =~ m{ (?<!\\) [\$\@] \S+ }mx      #Contains unescaped $. or @.
      || $elem   =~ m{ \\[tnrfae0xcNLuLUEQ] }mx;   #Containts escaped metachars
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitInterpolationOfLiterals

=head1 DESCRIPTION

Don't use double-quotes or C<qq//> if your string doesn't require
interpolation.  This saves the interpreter a bit of work and it lets
the reader know that you really did intend the string to be literal.

  print "foobar";     #not ok
  print 'foobar';     #ok
  print qq/foobar/;   #not ok
  print q/foobar/;    #ok

  print "$foobar";    #ok
  print "foobar\n";   #ok
  print qq/$foobar/;  #ok
  print qq/foobar\n/; #ok

  print qq{$foobar};  #preferred
  print qq{foobar\n}; #preferred

=head1 CONSTRUCTOR

This Policy accepts an additional key-value pair in the constructor,
The key is 'allow' and the value is a string of quote styles
that are exempt from this policy.  Valid styles are C<qq{}>, C<qq()>,
C<qq[]>, and C<qq//>. Multiple styles should be separated by
whitespace.  This is useful because some folks have configured their
editor to apply special syntax highlighting within certain styles of
quotes.  For example, you can tweak C<vim> to use SQL highlighting for
everything that appears within C<qq{}> or C<qq[]> quotes.  But if
those strings are literal, Perl::Critic will complain.  To prevent
this, put the following in your F<.perlcriticrc> file:

  [ValuesAndExpressions::ProhibitInterpolationOfLiterals]
  allow = qq{} qq[]

=head1 SEE ALSO

L<Perl::Critic::Policy::ValuesAndExpressions::RequireInterpolationOfMetachars>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
