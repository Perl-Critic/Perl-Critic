package Perl::Critic::Policy::ValuesAndExpressions::RequireQuotedHeredocTerminator;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.13';
$VERSION = eval $VERSION;    ## no critic

my $heredoc_rx = qr/ \A << ["|'] .* ['|"] \z /x;
my $desc       = q{Heredoc terminator must be quoted};
my $expl       = [62];

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;
    $elem->isa('PPI::Token::HereDoc') || return;

    if ( $elem !~ $heredoc_rx ) {
        return Perl::Critic::Violation->new( $desc, $expl, $elem->location() );
    }
    return;    #ok!
}

1;

__END__

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::RequireQuotedHeredocTerminator

=head1 DESCRIPTION

Putting single or double-quotes around your HEREDOC terminator make it obvious
to the reader whether the content is going to be interpolated or not.

  print <<END_MESSAGE;    #not ok
  Hello World
  END_MESSAGE

  print <<'END_MESSAGE';  #ok
  Hello World
  END_MESSAGE

  print <<"END_MESSAGE";  #ok
  $greeting
  END_MESSAGE

=head1 SEE ALSO 

L<Perl::Critic::Policy::ValuesAndExpressions::RequireUpperCaseHeredocTerminator>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.
