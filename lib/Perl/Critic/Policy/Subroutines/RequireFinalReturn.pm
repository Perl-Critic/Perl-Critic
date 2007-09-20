##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::Subroutines::RequireFinalReturn;

use strict;
use warnings;
use Readonly;

use Carp qw(confess);

use Perl::Critic::Utils qw{
    :booleans :characters :severities :data_conversion
};
use base 'Perl::Critic::Policy';

our $VERSION = 1.078;

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Subroutine does not end with "return"};
Readonly::Scalar my $EXPL => [ 197 ];

Readonly::Hash my %CONDITIONALS => hashify( qw(if unless for foreach) );

#-----------------------------------------------------------------------------

sub supported_parameters { return qw(terminal_funcs)    }
sub default_severity { return $SEVERITY_HIGH        }
sub default_themes   { return qw( core bugs pbp )   }
sub applies_to       { return 'PPI::Statement::Sub' }

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    my ($self, $config) = @_;

    my $user_terminals = $config->{terminal_funcs} || q{};
    my @user_terminals = words_from_string( $user_terminals );
    my @default_terminals =
        qw(exit die croak confess throw Carp::confess Carp::croak);

    $self->{_terminals} = { hashify(@default_terminals, @user_terminals) };

    return $TRUE;
}

#-----------------------------------------------------------------------------

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
    if ($self->_block_is_empty($block) || $self->_block_has_return($block)) {
        return; # OK
    }

    # Must be a violation
    return $self->violation( $DESC, $EXPL, $elem );
}

#-----------------------------------------------------------------------------

sub _block_is_empty {
    my ( $self, $block ) = @_;
    return $block->schildren() == 0;
}

#-----------------------------------------------------------------------------

sub _block_has_return {
    my ( $self, $block ) = @_;
    my @blockparts = $block->schildren();
    my $final = $blockparts[-1]; # always defined because we call _block_is_empty first
    return if !$final;
    return $self->_is_explicit_return($final)
        || $self->_is_compound_return($final);
}

#-----------------------------------------------------------------------------

sub _is_explicit_return {
    my ( $self, $final ) = @_;

    return if $self->_is_conditional_stmnt( $final );
    return $self->_is_return_or_goto_stmnt( $final )
        || $self->_is_terminal_stmnt( $final );
}

#-----------------------------------------------------------------------------

sub _is_compound_return {
    my ( $self, $final ) = @_;

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
        if (! $self->_block_has_return($block)) {
            return; #fail
        }
    }

    return 1;
}

#-----------------------------------------------------------------------------

sub _is_return_or_goto_stmnt {
    my ( $self, $stmnt ) = @_;
    return if not $stmnt->isa('PPI::Statement::Break');
    my $first_token = $stmnt->schild(0) || return;
    return $first_token eq 'return' || $first_token eq 'goto';
}

#-----------------------------------------------------------------------------

sub _is_terminal_stmnt {
    my ( $self, $stmnt ) = @_;
    return if not $stmnt->isa('PPI::Statement');
    my $first_token = $stmnt->schild(0) || return;
    return exists $self->{_terminals}->{$first_token};
}

#-----------------------------------------------------------------------------

sub _is_conditional_stmnt {
    my ( $self, $stmnt ) = @_;
    return if not $stmnt->isa('PPI::Statement');
    for my $elem ( $stmnt->schildren() ) {
        return 1 if $elem->isa('PPI::Token::Word')
            && exists $CONDITIONALS{$elem};
    }
    return;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::RequireFinalReturn

=head1 DESCRIPTION

Require all subroutines to terminate explicitly with one of the following:
C<return>, C<goto>, C<die>, C<exit>, C<throw>, C<carp> or C<croak>.

Subroutines without explicit return statements at their ends can be confusing.
It can be challenging to deduce what the return value will be.

Furthermore, if the programmer did not mean for there to be a significant
return value, and omits a return statement, some of the subroutine's inner
data can leak to the outside.  Consider this case:

   package Password;
   # every time the user guesses the password wrong, its value
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

In this case, the last statement in check_password() is the assignment.  The
result of that assignment is the implicit return value, so a wrong guess
returns the right password!  Adding a C<return;> at the end of that subroutine
solves the problem.

The only exception allowed is an empty subroutine.

=head1 CONFIGURATION

If you've created your own terminal functions that behave like C<die> or
C<exit>, then you can configure Perl::Critic to recognize those functions as
well.  Just put something like this in your F<.perlcriticrc>:

  [Subroutines::RequireFinalReturns]
  terminal_funcs = quit abort bailout

=head1 LIMITATIONS

We do not look for returns inside ternary operators.  That
construction is too complicated to analyze right now.  Besides, a
better form is the return outside of the ternary like this: C<return
foo ? 1 : bar ? 2 : 3>

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2007 Chris Dolan.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
