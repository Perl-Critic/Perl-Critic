#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::CodeLayout::ProhibitParensWithBuiltins;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.19;

#----------------------------------------------------------------------------

my %allow = ( my => 1, our => 1, local => 1, return => 1, );
my $desc  = q{Builtin function called with parens};
my $expl  = [ 13 ];

#----------------------------------------------------------------------------
# These are all the functions that take a LIST as an argument.  These
# functions are said to be 'greedy' because they gobble as many
# arguments as they can.  These functions often require parens to
# enforce precedence.

my %greedy_funcs = (
    chmod  =>  1,  formline =>  1,  print   =>  1,  sprintf => 1,  utime => 1,
    chomp  =>  1,  grep     =>  1,  printf  =>  1,  syscall => 1,  warn  => 1,
    chop   =>  1,  join     =>  1,  push    =>  1,  system  => 1,
    chown  =>  1,  kill     =>  1,  reverse =>  1,  tie     => 1,
    die    =>  1,  map      =>  1,  sort    =>  1,  unlink  => 1,
    exec   =>  1,  pack     =>  1,  splice  =>  1,  unshift => 1,
);

#----------------------------------------------------------------------------
# These are all the functions that are considered named unary
# operators.  These frequently require parens because they have lower
# precedence than ordinary function calls.

my %named_unary_ops = (
    alarm   => 1,         glob      => 1,  rand      => 1,  undef => 1,
    caller  => 1,         gmtime    => 1,  readlink  => 1,
    chdir   => 1,         hex       => 1,  ref       => 1,
    chroot  => 1,         int       => 1,  require   => 1,
    cos     => 1,         lc        => 1,  return    => 1,
    defined => 1,         lcfirst   => 1,  rmdir     => 1,
    delete  => 1,         length    => 1,  scalar    => 1,
    do      => 1,         localtime => 1,  sin       => 1,
    eval    => 1,         lock      => 1,  sleep     => 1,
    exists  => 1,         log       => 1,  sqrt      => 1,
    exit    => 1,         lstat     => 1,  srand     => 1,
    getgrp  => 1,         my        => 1,  stat      => 1,
    gethostbyname  => 1,  oct       => 1,  uc        => 1,
    getnetbyname   => 1,  ord       => 1,  ucfirst   => 1,
    getprotobyname => 1,  quotemeta => 1,  umask     => 1,
);

#----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_LOWEST }
sub applies_to { return 'PPI::Token::Word' }

#----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if exists $allow{$elem};
    return if ! is_perl_builtin($elem);
    return if ! is_function_call($elem);

    my $sib = $elem->snext_sibling();
    return if !$sib;
    if ( $sib->isa('PPI::Structure::List') ) {

        my $elem_after_parens = $sib->snext_sibling();

        # EXCEPTION 1: If the function is a named unary and there is
        # an operator with higher precedence right after the parens.
        # Example: int( 1.5 ) + 0.5;

        if ( _is_named_unary( $elem ) && $elem_after_parens ){
            my $p = precedence_of( $elem_after_parens );
            return if defined $p  && $p < 9;
        }

        # EXCEPTION 2, If the function is 'greedy' and there is an
        # operator immediately after the parens, and that operator
        # has precedence greater than or eqaul to a comma.
        # Example: join($delim, @list) . "\n";

        if ( _is_greedy($elem) && $elem_after_parens ){
            my $p = precedence_of( $elem_after_parens );
            return if defined $p  && $p <= 20;
        }

        # EXCEPTION 3: If the first operator within the parens is '='
        # Example: chomp( my $foo = <STDIN> );

        if ( my $first_op = $sib->find_first('PPI::Token::Operator') ){
            return if $first_op eq q{=};
        }

        # If we get here, it must be a violation
        return $self->violation( $desc, $expl, $elem );
    }
    return;    #ok!
}

#-----------------------------------------------------------------------------

sub _is_named_unary {
    my $elem = shift;
    return if ! $elem->isa('PPI::Token::Word');
    return exists $named_unary_ops{$elem};
}

#-----------------------------------------------------------------------------

sub _is_greedy {
    my $elem = shift;
    return if ! $elem->isa('PPI::Token::Word');
    return exists $greedy_funcs{$elem};
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::CodeLayout::ProhibitParensWithBuiltins

=head1 DESCRIPTION

Conway suggests that all built-in functions be called without
parentheses around the argument list.  This reduces visual clutter and
disambiguates built-in functions from user functions.  Exceptions are
made for C<my>, C<local>, and C<our> which require parentheses when
called with multiple arguments.

  open($handle, '>', $filename); #not ok
  open $handle, '>', $filename;  #ok

  split(/$pattern/, @list); #not ok
  split /$pattern/, @list;  #ok

=head1 NOTES

Coding with parens can sometimes lead to verbose and awkward
constructs, so I think the intent of Conway's guideline is to remove
only the F<unnecessary> parens.  This policy makes exceptions for some
common situations where parens are usually required.  However, you may
find other situations where the parens are necessary to enforce
precedence, but they cause still violations.  In those cases, consider
using the '## no critic' comments to silence Perl::Critic.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
