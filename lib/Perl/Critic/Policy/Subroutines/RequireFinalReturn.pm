#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::Subroutines::RequireFinalReturn;

use strict;
use warnings;
use Carp qw(confess);
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.20;

#---------------------------------------------------------------------------

my $desc = q{Subroutine does not end with "return"};
my $expl = [ 197 ];

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGH        }
sub default_themes    { return qw( risky pbp )       }
sub applies_to       { return 'PPI::Statement::Sub' }

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    # skip BEGIN{} and INIT{} and END{} etc
    return if $elem->isa('PPI::Statement::Scheduled');

    my @blocks = grep {$_->isa('PPI::Structure::Block')} $elem->schildren();
    if (@blocks > 1) {  
       # sanity check
       confess 'Internal error: subroutine should have no more than one block';
    }
    elsif (@blocks == 0) {
       #Technically, subroutines don't have to have a block at all. In
       # that case, its just a declaration so this policy doesn't really apply
       return; # ok!
    }


    my ($block) = @blocks;
    if (_block_is_empty($block) || _block_has_return($block)) {
        return; # OK
    }

    # Must be a violation
    return $self->violation( $desc, $expl, $elem );
}

#------------------------

sub _block_is_empty {
    my ( $block ) = @_;
    return $block->schildren() == 0;
}

#------------------------

sub _block_has_return {
    my ( $block ) = @_;
    my @blockparts = $block->schildren();
    my $final = $blockparts[-1]; # always defined because we call _block_is_empty first
    return if !$final;
    return _is_explicit_return($final)
        || _is_compound_return($final);
}

#-------------------------

sub _is_explicit_return {
    my ( $final ) = @_;
    return $final->isa('PPI::Statement::Break') &&
           $final =~ m/ \A (?: return | goto ) \b /xms;
}

#-------------------------

sub _is_compound_return {
    my ( $final ) = @_;

    if (!$final->isa('PPI::Statement::Compound')) {
        return; #fail
    }

    my $begin = $final->schild(0);
    return if !$begin; #fail
    if (!($begin->isa('PPI::Token::Word') &&
          ($begin eq 'if' || $begin eq 'unless'))) {
        return; #fail
    }

    my @blocks = grep {!$_->isa('PPI::Structure::Condition') &&
                       !$_->isa('PPI::Token')} $final->schildren();
    # Sanity check:
    if (scalar grep {!$_->isa('PPI::Structure::Block')} @blocks) { 
        confess 'Internal error: expected only conditions, blocks and tokens in the if statement';
        return; ## no critic (UnreachableCode)
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

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::RequireFinalReturn

=head1 DESCRIPTION

Require all subroutines to terminate with a C<return> (or a C<goto>).

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

=head1 LIMITATIONS

We do not look for returns inside ternary operators.  That
construction is too complicated to analyze right now.  Besides, a
better form is the return outside of the ternary like this: C<return
foo ? 1 : bar ? 2 : 3>

Also, this policy doesn't allow you to terminate a subroutine with
C<die>, C<exit>, C<croak>, or C<confess>.  We'll try and fix that in
the future.

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Chris Dolan.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
