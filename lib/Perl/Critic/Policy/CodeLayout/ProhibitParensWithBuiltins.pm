package Perl::Critic::Policy::CodeLayout::ProhibitParensWithBuiltins;

use 5.006001;
use strict;
use warnings;
use Readonly;

use List::MoreUtils qw{any};

use Perl::Critic::Utils qw{
    :booleans :severities :data_conversion :classification :language
};
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Array my @ALLOW => qw( my our local return state );
Readonly::Hash my %ALLOW => hashify( @ALLOW );

Readonly::Scalar my $DESC  => q{Builtin function called with parentheses};
Readonly::Scalar my $EXPL  => [ 13 ];

Readonly::Scalar my $PRECENDENCE_OF_LIST => precedence_of(q{>>}) + 1;
Readonly::Scalar my $PRECEDENCE_OF_COMMA => precedence_of(q{,});

#-----------------------------------------------------------------------------
# These are all the functions that are considered named unary
# operators.  These frequently require parentheses because they have lower
# precedence than ordinary function calls.

Readonly::Array my @NAMED_UNARY_OPS => qw(
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
Readonly::Hash my %NAMED_UNARY_OPS => hashify( @NAMED_UNARY_OPS );

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                      }
sub default_severity     { return $SEVERITY_LOWEST        }
sub default_themes       { return qw( core pbp cosmetic ) }
sub applies_to           { return 'PPI::Token::Word'      }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if exists $ALLOW{$elem};
    return if not is_perl_builtin($elem);
    return if not is_function_call($elem);

    my $sibling = $elem->snext_sibling();
    return if not $sibling;
    if ( $sibling->isa('PPI::Structure::List') ) {
        my $elem_after_parens = $sibling->snext_sibling();

        return if _is_named_unary_with_operator_inside_parens_exemption($elem, $sibling);
        return if _is_named_unary_with_operator_following_parens_exemption($elem, $elem_after_parens);
        return if _is_precedence_exemption($elem_after_parens);
        return if _is_equals_exemption($sibling);
        return if _is_sort_exemption($elem, $sibling);

        # If we get here, it must be a violation
        return $self->violation( $DESC, $EXPL, $elem );
    }
    return;    #ok!
}

#-----------------------------------------------------------------------------
# EXCEPTION 1: If the function is a named unary and there is an
# operator with higher precedence right after the parentheses.
# Example: int( 1.5 ) + 0.5;

sub _is_named_unary_with_operator_following_parens_exemption {
    my ($elem, $elem_after_parens) = @_;

    if ( _is_named_unary( $elem ) && $elem_after_parens ){
        # Smaller numbers mean higher precedence
        my $precedence = precedence_of( $elem_after_parens );
        return $TRUE if defined $precedence && $precedence < $PRECENDENCE_OF_LIST;
    }

    return $FALSE;
}

sub _is_named_unary {
    my ($elem) = @_;

    return exists $NAMED_UNARY_OPS{$elem->content};
}

#-----------------------------------------------------------------------------
# EXCEPTION 2, If there is an operator immediately after the
# parentheses, and that operator has precedence greater than
# or equal to a comma.
# Example: join($delim, @list) . "\n";

sub _is_precedence_exemption {
    my ($elem_after_parens) = @_;

    if ( $elem_after_parens ){
        # Smaller numbers mean higher precedence
        my $precedence = precedence_of( $elem_after_parens );
        return $TRUE if defined $precedence && $precedence <= $PRECEDENCE_OF_COMMA;
    }

    return $FALSE;
}

#-----------------------------------------------------------------------------
# EXCEPTION 3: If the first operator within the parentheses is '='
# Example: chomp( my $foo = <STDIN> );

sub _is_equals_exemption {
    my ($sibling) = @_;

    if ( my $first_op = $sibling->find_first('PPI::Token::Operator') ){
        return $TRUE if $first_op eq q{=};
    }

    return $FALSE;
}

#-----------------------------------------------------------------------------
# EXCEPTION 4: sort with default comparator but a function for the list data
# Example: sort(foo(@x))

sub _is_sort_exemption {
    my ($elem, $sibling) = @_;

    if ( $elem eq 'sort' ) {
        my $first_arg = $sibling->schild(0);
        if ( $first_arg && $first_arg->isa('PPI::Statement::Expression') ) {
            $first_arg = $first_arg->schild(0);
        }
        if ( $first_arg && $first_arg->isa('PPI::Token::Word') ) {
            my $next_arg = $first_arg->snext_sibling;
            return $TRUE if $next_arg && $next_arg->isa('PPI::Structure::List');
        }
    }

    return $FALSE;
}

#-----------------------------------------------------------------------------
# EXCEPTION 5: If the function is a named unary and there is an operator
# inside the parentheses.
# Example: length($foo || $bar);

sub _is_named_unary_with_operator_inside_parens_exemption {
    my ($elem, $parens) = @_;
    return _is_named_unary($elem) &&  _contains_operators($parens);
}

sub _contains_operators {
    my ($parens) = @_;
    return $TRUE if $parens->find_first('PPI::Token::Operator');
    return $FALSE;
}

#-----------------------------------------------------------------------------
1;

__END__


=pod

=for stopwords disambiguates builtins

=head1 NAME

Perl::Critic::Policy::CodeLayout::ProhibitParensWithBuiltins - Write C<open $handle, $path> instead of C<open($handle, $path)>.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


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


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 NOTES

Coding with parentheses can sometimes lead to verbose and awkward
constructs, so I think the intent of Conway's guideline is to remove
only the F<unnecessary> parentheses.  This policy makes exceptions for
some common situations where parentheses are usually required.
However, you may find other situations where the parentheses are
necessary to enforce precedence, but they cause still violations.  In
those cases, consider using the '## no critic' comments to silence
Perl::Critic.


=head1 BUGS

Some builtin functions (particularly those that take a variable number
of scalar arguments) should probably get parentheses.  This policy
should be enhanced to allow the user to specify a list of builtins
that are exempt from the policy.


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2005-2011 Imaginative Software Systems.  All rights reserved.

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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
