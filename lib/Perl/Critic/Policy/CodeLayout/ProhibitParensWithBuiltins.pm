#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
########################################################################

package Perl::Critic::Policy::CodeLayout::ProhibitParensWithBuiltins;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.22;

#----------------------------------------------------------------------------

my @allow = qw( my our local return );
my %allow = hashify( @allow );

my $desc  = q{Builtin function called with parens};
my $expl  = [ 13 ];

#----------------------------------------------------------------------------
# These are all the functions that are considered named unary
# operators.  These frequently require parens because they have lower
# precedence than ordinary function calls.

my @named_unary_ops = qw(
    alarm           glob        rand
    caller          gmtime      readlink
    chdir           hex         ref
    chroot          int         require
    cos             lc          return
    defined         lcfirst     rmdir
    delete          length      scalar
    do              localtime   sin
    eval            lock        sleep
    exists          log         sqrt
    exit            lstat       srand
    getgrp          my          stat
    gethostbyname   oct         uc
    getnetbyname    ord         ucfirst
    getprotobyname  quotemeta   umask
                                undef
);
my %named_unary_ops = hashify( @named_unary_ops );

#----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_LOWEST   }
sub default_themes   { return qw( pbp cosmetic ) }
sub applies_to       { return 'PPI::Token::Word' }

#----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if exists $allow{$elem};
    return if not is_perl_builtin($elem);
    return if not is_function_call($elem);

    my $sib = $elem->snext_sibling();
    return if !$sib;
    if ( $sib->isa('PPI::Structure::List') ) {

        my $elem_after_parens = $sib->snext_sibling();

        # EXCEPTION 1: If the function is a named unary and there is an
        # operator with higher precedence right after the parens.
        # Example: int( 1.5 ) + 0.5;

        if ( _is_named_unary( $elem ) && $elem_after_parens ){
            # Smaller numbers mean higher precedence
            my $precedence = precedence_of( $elem_after_parens );
            return if defined $precedence  && $precedence < 9;
        }

        # EXCEPTION 2, If there is an operator immediately adfter the parens,
        # and that operator has precedence greater than or eqaul to a comma.
        # Example: join($delim, @list) . "\n";

        if ( $elem_after_parens ){
            # Smaller numbers mean higher precedence
            my $precedence = precedence_of( $elem_after_parens );
            return if defined $precedence && $precedence <= 20;
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
    return exists $named_unary_ops{$elem->content};
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords disambiguates

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

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 expandtab :
