package Perl::Critic::Policy::Subroutines::RequireFinalReturn;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.13';
$VERSION = eval $VERSION;    ## no critic

my $desc = q{Subroutine does not end with return};
my $expl = q{Implicit return values are confusing};

#---------------------------------------------------------------------------

sub applies_to {
    return 'PPI::Statement::Sub';
}

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my @blocks = grep {$_->isa('PPI::Structure::Block')} $elem->schildren();
    if (@blocks != 1) {  # sanity check
       die 'Internal error: subroutine should have exactly one block';
    }

    my ($block) = @blocks;
    if (_block_is_empty($block) || _block_has_return($block)) {
        return; # OK
    }
    return Perl::Critic::Violation->new( $desc, $expl, $elem->location() );
}

sub _block_is_empty {
    my ( $block ) = @_;
    return $block->schildren() == 0;
}

sub _block_has_return {
    my ( $block ) = @_;
    my @blockparts = $block->schildren();
    my $last = $blockparts[-1];
    return $last && (_is_explicit_return($last) ||
                     _is_compound_return($last));
}

sub _is_explicit_return {
    my ( $last ) = @_;
    return $last->isa('PPI::Statement::Break') &&
           $last =~ m/ \A return\b /xms;
}

sub _is_compound_return {
    my ( $last ) = @_;
 
    if (!$last->isa('PPI::Statement::Compound')) {
        return; #fail
    }

    my $begin = $last->schild(0) || return; #fail
    if (!($begin->isa('PPI::Token::Word') && $begin eq 'if')) {
        return; #fail
    }

    my @blocks = grep {!$_->isa('PPI::Structure::Condition') &&
                       !$_->isa('PPI::Token')} $last->schildren();
    # Sanity check:
    if (scalar grep {!$_->isa('PPI::Structure::Block')} @blocks) { 
        die 'Internal error: expected only conditions, blocks and tokens in the if statement';
        return; #fail
    }

    for my $block (@blocks) {
        if (!_block_has_return($block)) {
            return; #fail
        }
    }

    return 1;
}

1;

__END__

=head1 NAME

Perl::Critic::Policy::Subroutines::RequireFinalReturn

=head1 DESCRIPTION

Subroutines without explicit return statements at their ends can be
confusing.  It can be challenging to deduce what the return value will
be.

Furthermore, if the programmer did not mean for there to be a
significant return value, and omits a return statement, some of the
subroutine's inner data can leak to the outside.  Consider this case:

   package Password;
   # every time the user guesses the password wrong, it's value
   # is rotated by one character
   my $password;
   sub set_password {
      $password = shift;
   }
   sub check_password {
      my $guess = shift;
      if ($guess eq $password) {
         unlock_secrets();
      } else {
         $password = (substr $password, 1).(substr $password, 0, 1);
      }
   }
   1;

In this case, the last statement in check_password() is the
assignment.  The result of that assignment is the implicit return
value, so a wrong guess returns the right password!  Adding a
C<return;> at the end of that subroutine solves the problem.

The only exception allowed is an empty subroutine.

We do not look for returns inside ternary operators.  That
construction is too complicated to analyze right now.  Besides, a
better form is the return outside of the ternary like this: C<return
foo ? 1 : bar ? 2 : 3>

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

Copyright (c) 2005 Chris Dolan.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.
