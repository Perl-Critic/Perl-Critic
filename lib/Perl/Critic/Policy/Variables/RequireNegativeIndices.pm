##################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##################################################################

package Perl::Critic::Policy::Variables::RequireNegativeIndices;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.20;

#----------------------------------------------------------------------------

my $desc = q{Negative array index should be used};
my $expl = [ 88 ];

#----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGH }
sub applies_to { return 'PPI::Structure::Subscript' }

#----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    return if $elem->braces ne '[]';
    my ($name, $isref) = _is_bad_index( $elem );
    return if ( !$name );
    return if !_is_array_name( $elem, $name, $isref );
    return $self->violation( $desc, $expl, $elem );
}

sub _is_bad_index {
    # return (varname, 0|1) if this could be a violation
    my ( $elem ) = @_;

    my @children = $elem->schildren();
    return if @children != 1; # too complex
    return if !$children[0]->isa( 'PPI::Statement::Expression'); # too complex
                
    # This is the expression elements that compose the array indexing
    my @expr = $children[0]->schildren();
    return if !@expr || @expr > 4; # no-op or too complex
    my ($name, $isref, $isindex) = _is_bad_var_in_index(\@expr);
    return if !$name;
    return $name, $isref if !@expr && $isindex;
    return if !_is_minus_number(@expr);
    return $name, $isref;
}

sub _is_bad_var_in_index {
    # return (varname, isref=0|1, isindex=0|1) if this could be a violation
    my ( $expr ) = @_;

    if ( $expr->[0]->isa('PPI::Token::ArrayIndex') ) {
        # [$#arr]
        return _arrayindex($expr);
    }
    elsif ( $expr->[0]->isa('PPI::Token::Cast') ) {
        # [$#{$arr} ...] or [$#$arr ...] or [@{$arr} ...] or [@$arr ...]
        return _cast($expr);
    }
    elsif ($expr->[0]->isa('PPI::Token::Symbol')) {
        # [@arr ...]
        return _symbol($expr);
    }

    return;
}

sub _arrayindex {
    # return (varname, isref=0|1, isindex=0|1) if this could be a violation
    my ( $expr ) = @_;
    my $arrindex = shift @{$expr};
    if ($arrindex->content =~ m/\A \$\# (.*) \z /xms) { # What else could it be???
       return $1, 0, 1;
    }
    return;
}

sub _cast {
    # return (varname, isref=0|1, isindex=0|1) if this could be a violation
    my ( $expr ) = @_;
    my $cast = shift @{$expr};
    if ( $cast eq q{$#} || $cast eq q{@} ) { ## no critic(RequireInterpolationOfMetachars)
        my $isindex = $cast eq q{$#} ? 1 : 0;  ## no critic(RequireInterpolationOfMetachars)
        my $arrvar = shift @{$expr};
        if ($arrvar->isa('PPI::Structure::Block')) {
            # look for [$#{$arr} ...] or [@{$arr} ...]
            my @blockchildren = $arrvar->schildren();
            return if @blockchildren != 1;
            return if !$blockchildren[0]->isa('PPI::Statement');
            my @ggg = $blockchildren[0]->schildren;
            return if @ggg != 1;
            return if !$ggg[0]->isa('PPI::Token::Symbol');
            if ($ggg[0] =~ m/\A \$ (.*) \z/xms) {
                return $1, 1, $isindex;
            }
        }
        elsif ( $arrvar->isa('PPI::Token::Symbol') ) {
           # look for [$#$arr ...] or [@$arr ...]
           if ($arrvar =~ m/\A \$ (.*) \z/xms) {
              return $1, 1, $isindex;
           }
        }
    }
    return;
}

sub _symbol {
    # return (varname, isref=0|1, isindex=0|1) if this could be a violation
    my ( $expr ) = @_;
    my $arrvar = shift @{$expr};
    if ($arrvar =~ m/\A \@ (.*) \z/xms) {
       return $1, 0, 0;
    }
    return;
}

sub _is_minus_number  # return true if @expr looks like "- n"
{
    my @expr = @_;

    return if !@expr;

    ## Workaround for PPI 1.115 bug "t/data/08_regression/14_minus.code"
    # Consider deleting this block when we depend on a later PPI
    if ( @expr == 1 ) {
        my $number = shift @expr;
        return if !$number->isa('PPI::Token::Number');
        return if $number !~ m/\A \-/xms;
        return 1;
    }
    ## End workaround

    return if @expr != 2;

    my $op = shift @expr;
    return if !$op->isa('PPI::Token::Operator');
    return if $op ne q{-};
    
    my $number = shift @expr;
    return if !$number->isa('PPI::Token::Number');

    return 1;
}

sub _is_array_name {  # return true if name and isref matches
    my ( $elem, $name, $isref ) = @_;

    my $sib = $elem->sprevious_sibling;
    return if !$sib;

    if ($sib->isa('PPI::Token::Operator') && $sib eq '->') {
        return if ( !$isref );
        $isref = 0;
        $sib = $sib->sprevious_sibling;
        return if !$sib;
    }

    return if !$sib->isa('PPI::Token::Symbol');
    return if $sib !~ m/\A \$ \Q$name\E \z/xms;

    my $cousin = $sib->sprevious_sibling;
    return if $isref ^ _is_dereferencer( $cousin );
    return if $isref && _is_dereferencer( $cousin->sprevious_sibling );

    return $elem;
}

sub _is_dereferencer { # must return 0 or 1, not undef
    my $elem = shift;

    return 0 if !$elem;
    return 1 if $elem->isa('PPI::Token::Operator') && $elem eq '->';
    return 1 if $elem->isa('PPI::Token::Cast');
    return 0;
}

1;

#----------------------------------------------------------------------------

__END__

=pod

=for stopwords performant

=head1 NAME

Perl::Critic::Policy::Variables::RequireNegativeIndices

=head1 DESCRIPTION

Conway points out that

  $arr[$#arr];
  $arr[$#arr-1];
  $arr[@arr-1];
  $arr[@arr-2];

are equivalent to

  $arr[-1];
  $arr[-2];
  $arr[-1];
  $arr[-2];

and the latter are more readable, performant and maintainable.  The
latter is because the programmer no longer needs to keep two variable
names matched.

This policy notices all of the simple forms of the above problem, but
does not recognize any of these more complex examples:

   $some->[$data_structure]->[$#{$some->[$data_structure]} -1];
   my $ref = \@arr;
   $ref->[$#arr];

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2006 Chris Dolan.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
