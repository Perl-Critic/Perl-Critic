package Perl::Critic::Policy::InputOutput::ProhibitBacktickOperators;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.13';
$VERSION = eval $VERSION;    ## no critic

my $expl = q{Use IPC::Open3 instead};
my $desc = q{Backtick operator used};

#----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;
    if (   $elem->isa('PPI::Token::QuoteLike::Backtick')
        || $elem->isa('PPI::Token::QuoteLike::Command') )
    {
        return Perl::Critic::Violation->new( $desc, $expl, $elem->location() );
    }
    return;    #ok!
}

1;

__END__

=head1 NAME

Perl::Critic::Policy::InputOutput::ProhibitBacktickOperators

=head1 DESCRIPTION

Backticks are super-convenient, especially for CGI programs, but I
find that they make a lot of noise by filling up STDERR with messages
when they fail.  I think its better to use IPC::Open3 to trap all the
output and let the application decide what to do with it.


  use IPC::Open3;

  @output = `some_command`;                      #not ok

  my ($writer, $reader, $err);
  open3($writer, $reader, $err, 'some_command'); #ok;
  @output = <$reader>;  #Output here
  @errors = <$err>;     #Errors here, instead of the console

=head1 NOTES

This policy also prohibits the generalized form of backticks seen as
C<qx{}>.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.
