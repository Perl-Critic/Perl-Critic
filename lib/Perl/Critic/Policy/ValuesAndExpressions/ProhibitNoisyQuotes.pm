package Perl::Critic::Policy::ValuesAndExpressions::ProhibitNoisyQuotes;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.13';
$VERSION = eval $VERSION;    ## no critic

my $noise_rx = qr{\A ["|']  [^ \w () {} [\] <> ]{1,2}  ['|"] \z}x;
my $desc     = q{Quotes used with a noisy string};
my $expl     = [53];

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;
    $elem->isa('PPI::Token::Quote::Double')
      || $elem->isa('PPI::Token::Quote::Single')
      || return;

    if ( $elem =~ $noise_rx ) {
        return Perl::Critic::Violation->new( $desc, $expl, $elem->location() );
    }
    return;    #ok!
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitNoisyQuotes

=head1 DESCRIPTION

Don't use quotes for one or two-character strings of non-alphanumeric
characters (i.e. noise).  These tend to be hard to read.  For
legibility, use C<q{}> or a named value.  However, braces, parens, and 
brackets tend do to look better in quotes, so those are allowed.

  $str = join ',', @list;     #not ok
  $str = join ",", @list;     #not ok
  $str = join q{,}, @list;    #better

  $COMMA = q{,};
  $str = join $COMMA, @list;  #best

  $lbrace = '(';          #ok
  $rbrace = ')';          #ok
  print '(', @list, ')';  #ok

=head1 SEE ALSO 

L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitEmptyQuotes>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
