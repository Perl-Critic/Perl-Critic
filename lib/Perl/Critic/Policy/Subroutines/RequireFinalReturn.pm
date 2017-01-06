package Perl::Critic::Policy::Subroutines::RequireFinalReturn;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Exception::Fatal::Internal qw{ throw_internal };
use Perl::Critic::Utils qw{ :characters :severities :data_conversion };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL => [ 197 ];

Readonly::Hash my %CONDITIONALS => hashify( qw(if unless for foreach) );

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'terminal_funcs',
            description     => 'The additional subroutines to treat as terminal.',
            default_string  => $EMPTY,
            behavior        => 'string list',
            list_always_present_values =>
                [ qw< croak confess die exec exit throw Carp::confess Carp::croak ...> ],
        },
    );
}

sub default_severity { return $SEVERITY_HIGH        }
sub default_themes   { return qw( core bugs pbp certrec )   }
sub applies_to       { return 'PPI::Statement::Sub' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    # skip BEGIN{} and INIT{} and END{} etc
    return if $elem->isa('PPI::Statement::Scheduled');

    my @blocks = grep {$_->isa('PPI::Structure::Block')} $elem->schildren();
    if (@blocks > 1) {
       # sanity check
       throw_internal 'Subroutine should have no more than one block';
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
    my $desc;
    if ( my $name = $elem->name() ) {
        $desc = qq<Subroutine "$name" does not end with "return">;
    }
    else {
        $desc = q<Subroutine does not end with "return">;
    }

    return $self->violation( $desc, $EXPL, $elem );
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
        || $self->_is_given_when_return($final)
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
          ($begin->content() eq 'if' || $begin->content() eq 'unless'))) {
        return; #fail
    }

    my @blocks = grep {!$_->isa('PPI::Structure::Condition') &&
                       !$_->isa('PPI::Token')} $final->schildren();
    # Sanity check:
    if (scalar grep {!$_->isa('PPI::Structure::Block')} @blocks) {
        throw_internal
            'Expected only conditions, blocks and tokens in the if statement';
    }

    for my $block (@blocks) {
        if (! $self->_block_has_return($block)) {
            return; #fail
        }
    }

    return 1;
}

#-----------------------------------------------------------------------------

sub _is_given_when_return {
    my ( $self, $final ) = @_;

    if ( ! $final->isa( 'PPI::Statement::Given' ) ) {
        return; #fail
    }

    my $begin = $final->schild(0);
    return if !$begin; #fail
    if ( ! ( $begin->isa( 'PPI::Token::Word' ) &&
            $begin->content() eq 'given' ) ) {
        return; #fail
    }

    my @blocks = grep {!$_->isa( 'PPI::Structure::Given' ) &&
                       !$_->isa( 'PPI::Token' )} $final->schildren();
    # Sanity check:
    if (scalar grep {!$_->isa('PPI::Structure::Block')} @blocks) {
        throw_internal
            'Expected only givens, blocks and tokens in the given statement';
    }
    if (@blocks > 1) {
       # sanity check
       throw_internal 'Given statement should have no more than one block';
    }
    @blocks or return;  #fail

    my $have_default;   # We have to fail unless a default block is present

    foreach my $stmnt ( $blocks[0]->schildren() ) {

        if ( $stmnt->isa( 'PPI::Statement::When' ) ) {

            # Check for the default block.
            my $first_token;
            $first_token = $stmnt->schild( 0 )
                and 'default' eq $first_token->content()
                and $have_default = 1;

            $self->_is_when_stmnt_with_return( $stmnt )
                or return;  #fail

        } else {

            $self->_is_suffix_when_with_return( $stmnt )
                or return;  #fail

        }

    }

    return $have_default;
}

#-----------------------------------------------------------------------------

sub _is_return_or_goto_stmnt {
    my ( $self, $stmnt ) = @_;
    return if not $stmnt->isa('PPI::Statement::Break');
    my $first_token = $stmnt->schild(0) || return;
    return $first_token->content() eq 'return'
        || $first_token->content() eq 'goto';
}

#-----------------------------------------------------------------------------

sub _is_terminal_stmnt {
    my ( $self, $stmnt ) = @_;
    return if not $stmnt->isa('PPI::Statement');
    my $first_token = $stmnt->schild(0) || return;
    return exists $self->{_terminal_funcs}->{$first_token};
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

#-----------------------------------------------------------------------------

sub _is_when_stmnt_with_return {
    my ( $self, $stmnt ) = @_;

    my @inner = grep { ! $_->isa( 'PPI::Token' ) &&
                    ! $_->isa( 'PPI::Structure::When' ) }
                $stmnt->schildren();
    if ( scalar grep { ! $_->isa( 'PPI::Structure::Block' ) } @inner ) {
        throw_internal 'When statement should contain only tokens, conditions, and blocks';
    }
    @inner > 1
        and throw_internal 'When statement should have no more than one block';
    @inner or return;   #fail

    foreach my $block ( @inner ) {
        if ( ! $self->_block_has_return( $block ) ) {
            return; #fail
        }
    }

    return 1;   #succeed
}

#-----------------------------------------------------------------------------

sub _is_suffix_when_with_return {
    my ( $self, $stmnt ) = @_;
    return if not $stmnt->isa('PPI::Statement');
    foreach my $elem ( $stmnt->schildren() ) {
        return ( $self->_is_return_or_goto_stmnt( $stmnt ) ||
                $self->_is_terminal_stmnt( $stmnt ) )
            if $elem->isa( 'PPI::Token::Word' )
                && 'when' eq $elem->content();
    }
    return;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::RequireFinalReturn - End every path through a subroutine with an explicit C<return> statement.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Require all subroutines to terminate explicitly with one of the
following: C<return>, C<carp>, C<croak>, C<die>, C<exec>, C<exit>,
C<goto>, or C<throw>.

Subroutines without explicit return statements at their ends can be
confusing.  It can be challenging to deduce what the return value will
be.

Furthermore, if the programmer did not mean for there to be a
significant return value, and omits a return statement, some of the
subroutine's inner data can leak to the outside.  Consider this case:

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

In this case, the last statement in check_password() is the
assignment.  The result of that assignment is the implicit return
value, so a wrong guess returns the right password!  Adding a
C<return;> at the end of that subroutine solves the problem.

The only exception allowed is an empty subroutine.

Be careful when fixing problems identified by this Policy; don't
blindly put a C<return;> statement at the end of every subroutine.

=head1 CONFIGURATION

If you've created your own terminal functions that behave like C<die>
or C<exit>, then you can configure Perl::Critic to recognize those
functions as well.  Just put something like this in your
F<.perlcriticrc>:

    [Subroutines::RequireFinalReturn]
    terminal_funcs = quit abort bailout

=head1 BUGS

We do not look for returns inside ternary operators.  That
construction is too complicated to analyze right now.  Besides, a
better form is the return outside of the ternary like this: C<return
foo ? 1 : bar ? 2 : 3>

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2011 Chris Dolan.

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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
