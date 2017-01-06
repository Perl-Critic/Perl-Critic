package Perl::Critic::Policy::Subroutines::RequireArgUnpacking;

use 5.006001;
use strict;
use warnings;

use Carp;
use English qw(-no_match_vars);
use Readonly;

use File::Spec;
use List::Util qw(first);
use List::MoreUtils qw(uniq any);

use Perl::Critic::Utils qw<
    :booleans :characters :classification hashify :severities words_from_string
>;
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $AT => q{@};
Readonly::Scalar my $AT_ARG => q{@_}; ## no critic (InterpolationOfMetachars)
Readonly::Scalar my $DOLLAR => q{$};
Readonly::Scalar my $DOLLAR_ARG => q{$_};   ## no critic (InterpolationOfMetaChars)

Readonly::Scalar my $DESC => qq{Always unpack $AT_ARG first};
Readonly::Scalar my $EXPL => [178];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'short_subroutine_statements',
            description     =>
                'The number of statements to allow without unpacking.',
            default_string  => '0',
            behavior        => 'integer',
            integer_minimum => 0,
        },
        {
            name            => 'allow_subscripts',
            description     =>
                'Should unpacking from array slices and elements be allowed?',
            default_string  => $FALSE,
            behavior        => 'boolean',
        },
        {
            name            => 'allow_delegation_to',
            description     =>
                'Allow the usual delegation idiom to these namespaces/subroutines',
            behavior        => 'string list',
            list_always_present_values => [ qw< SUPER:: NEXT:: > ],
        }
    );
}

sub default_severity     { return $SEVERITY_HIGH             }
sub default_themes       { return qw( core pbp maintenance ) }
sub applies_to           { return 'PPI::Statement::Sub'      }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    # forward declaration?
    return if not $elem->block;

    my @statements = $elem->block->schildren;

    # empty sub?
    return if not @statements;

    # Don't apply policy to short subroutines

    # Should we instead be doing a find() for PPI::Statement
    # instances?  That is, should we count all statements instead of
    # just top-level statements?
    return if $self->{_short_subroutine_statements} >= @statements;

    # look for explicit dereferences of @_, including '$_[0]'
    # You may use "... = @_;" in the first paragraph of the sub
    # Don't descend into nested or anonymous subs
    my $state = 'unpacking'; # still in unpacking paragraph
    for my $statement (@statements) {

        my @magic = _get_arg_symbols($statement);

        my $saw_unpack = $FALSE;

        MAGIC:
        for my $magic (@magic) {
            # allow conditional checks on the size of @_
            next MAGIC if _is_size_check($magic);

            if ('unpacking' eq $state) {
                if ($self->_is_unpack($magic)) {
                    $saw_unpack = $TRUE;
                    next MAGIC;
                }
            }

            # allow @$_[] construct in "... for ();"
            # Check for "print @$_[] for ()" construct (rt39601)
            next MAGIC
                if _is_cast_of_array($magic) and _is_postfix_foreach($magic);

            # allow $$_[], which is equivalent to $_->[] and not a use
            # of @_ at all.
            next MAGIC
                if _is_cast_of_scalar( $magic );

            # allow delegation of the form "$self->SUPER::foo( @_ );"
            next MAGIC
                if $self->_is_delegation( $magic );

            # If we make it this far, it is a violation
            return $self->violation( $DESC, $EXPL, $elem );
        }
        if (not $saw_unpack) {
            $state = 'post_unpacking';
        }
    }
    return;  # OK
}

sub _is_unpack {
    my ($self, $magic) = @_;

    my $prev = $magic->sprevious_sibling();
    my $next = $magic->snext_sibling();

    # If we have a subscript, we're dealing with an array slice on @_
    # or an array element of @_. See RT #34009.
    if ( $next and $next->isa('PPI::Structure::Subscript') ) {
        $self->{_allow_subscripts} or return;
        $next = $next->snext_sibling;
    }

    return $TRUE if
            $prev
        and $prev->isa('PPI::Token::Operator')
        and is_assignment_operator($prev->content())
        and (
                not $next
            or  $next->isa('PPI::Token::Structure')
            and $SCOLON eq $next->content()
    );
    return;
}

sub _is_size_check {
    my ($magic) = @_;

    # No size check on $_[0]. RT #34009.
    $AT eq $magic->raw_type or return;

    my $prev = $magic->sprevious_sibling;
    my $next = $magic->snext_sibling;

    if ( $prev || $next ) {

        return $TRUE
            if _legal_before_size_check( $prev )
                and _legal_after_size_check( $next );
    }

    my $parent = $magic;
    {
        $parent = $parent->parent()
            or return;
        $prev = $parent->sprevious_sibling();
        $next = $parent->snext_sibling();
        $prev
            or $next
            or redo;
    }   # until ( $prev || $next );

    return $TRUE
        if $parent->isa( 'PPI::Structure::Condition' );

    return;
}

{

    Readonly::Hash my %LEGAL_NEXT_OPER => hashify(
        qw{ && || == != > >= < <= and or } );

    Readonly::Hash my %LEGAL_NEXT_STRUCT => hashify( qw{ ; } );

    sub _legal_after_size_check {
        my ( $next ) = @_;

        $next
            or return $TRUE;

        $next->isa( 'PPI::Token::Operator' )
            and return $LEGAL_NEXT_OPER{ $next->content() };

        $next->isa( 'PPI::Token::Structure' )
            and return $LEGAL_NEXT_STRUCT{ $next->content() };

        return;
    }
}

{

    Readonly::Hash my %LEGAL_PREV_OPER => hashify(
        qw{ && || ! == != > >= < <= and or not } );

    Readonly::Hash my %LEGAL_PREV_WORD => hashify(
        qw{ if unless } );

    sub _legal_before_size_check {
        my ( $prev ) = @_;

        $prev
            or return $TRUE;

        $prev->isa( 'PPI::Token::Operator' )
            and return $LEGAL_PREV_OPER{ $prev->content() };

        $prev->isa( 'PPI::Token::Word' )
            and return $LEGAL_PREV_WORD{ $prev->content() };

        return;
    }

}

sub _is_postfix_foreach {
    my ($magic) = @_;

    my $sibling = $magic;
    while ( $sibling = $sibling->snext_sibling ) {
        return $TRUE
            if
                    $sibling->isa('PPI::Token::Word')
                and $sibling =~ m< \A for (?:each)? \z >xms;
    }
    return;
}

sub _is_cast_of_array {
    my ($magic) = @_;

    my $prev = $magic->sprevious_sibling;

    return $TRUE
        if ( $prev && $prev->content() eq $AT )
            and $prev->isa('PPI::Token::Cast');
    return;
}

# This subroutine recognizes (e.g.) $$_[0]. This is a use of $_ (equivalent to
# $_->[0]), not @_.

sub _is_cast_of_scalar {
    my ($magic) = @_;

    my $prev = $magic->sprevious_sibling;
    my $next = $magic->snext_sibling;

    return $DOLLAR_ARG eq $magic->content() &&
        $prev && $prev->isa('PPI::Token::Cast') &&
            $DOLLAR eq $prev->content() &&
        $next && $next->isa('PPI::Structure::Subscript');
}

# A literal @_ is allowed as the argument for a delegation.
# An example of the idiom we are looking for is $self->SUPER::foo(@_).
# The argument list of (@_) is required; no other use of @_ is allowed.

sub _is_delegation {
    my ($self, $magic) = @_;

    $AT_ARG eq $magic->content() or return; # Not a literal '@_'.
    my $parent = $magic->parent()           # Don't know what to do with
        or return;                          #   orphans.
    $parent->isa( 'PPI::Statement::Expression' )
        or return;                          # Parent must be expression.
    1 == $parent->schildren()               # '@_' must stand alone in
        or return;                          #   its expression.
    $parent = $parent->parent()             # Still don't know what to do
        or return;                          #   with orphans.
    $parent->isa ( 'PPI::Structure::List' )
        or return;                          # Parent must be a list.
    1 == $parent->schildren()               # '@_' must stand alone in
        or return;                          #   the argument list.
    my $subroutine_name = $parent->sprevious_sibling()
        or return;                          # Missing sub name.
    $subroutine_name->isa( 'PPI::Token::Word' )
        or return;
    $self->{_allow_delegation_to}{$subroutine_name}
        and return 1;
    my ($subroutine_namespace) = $subroutine_name =~ m/ \A ( .* ::) \w+ \z /smx
        or return;
    return $self->{_allow_delegation_to}{$subroutine_namespace};
}


sub _get_arg_symbols {
    my ($statement) = @_;

    return grep {$AT_ARG eq $_->symbol} @{$statement->find(\&_magic_finder) || []};
}

sub _magic_finder {
    # Find all @_ and $_[\d+] not inside of nested subs
    my (undef, $elem) = @_;
    return $TRUE if $elem->isa('PPI::Token::Magic'); # match

    if ($elem->isa('PPI::Structure::Block')) {
        # don't descend into a nested named sub
        return if $elem->statement->isa('PPI::Statement::Sub');

        my $prev = $elem->sprevious_sibling;
        # don't descend into a nested anon sub block
        return if $prev
            and $prev->isa('PPI::Token::Word')
            and 'sub' eq $prev->content();
    }

    return $FALSE; # no match, descend
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::RequireArgUnpacking - Always unpack C<@_> first.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Subroutines that use C<@_> directly instead of unpacking the arguments
to local variables first have two major problems.  First, they are
very hard to read.  If you're going to refer to your variables by
number instead of by name, you may as well be writing assembler code!
Second, C<@_> contains aliases to the original variables!  If you
modify the contents of a C<@_> entry, then you are modifying the
variable outside of your subroutine.  For example:

   sub print_local_var_plus_one {
       my ($var) = @_;
       print ++$var;
   }
   sub print_var_plus_one {
       print ++$_[0];
   }

   my $x = 2;
   print_local_var_plus_one($x); # prints "3", $x is still 2
   print_var_plus_one($x);       # prints "3", $x is now 3 !
   print $x;                     # prints "3"

This is spooky action-at-a-distance and is very hard to debug if it's
not intentional and well-documented (like C<chop> or C<chomp>).

An exception is made for the usual delegation idiom C<<
$object->SUPER::something( @_ ) >>. Only C<SUPER::> and C<NEXT::> are
recognized (though this is configurable) and the argument list for the
delegate must consist only of C<< ( @_ ) >>.

=head1 CONFIGURATION

This policy is lenient for subroutines which have C<N> or fewer
top-level statements, where C<N> defaults to ZERO.  You can override
this to set it to a higher number with the
C<short_subroutine_statements> setting.  This is very much not
recommended but perhaps you REALLY need high performance.  To do this,
put entries in a F<.perlcriticrc> file like this:

  [Subroutines::RequireArgUnpacking]
  short_subroutine_statements = 2

By default this policy does not allow you to specify array subscripts
when you unpack arguments (i.e. by an array slice or by referencing
individual elements).  Should you wish to permit this, you can do so
using the C<allow_subscripts> setting. This defaults to false.  You can
set it true like this:

  [Subroutines::RequireArgUnpacking]
  allow_subscripts = 1

The delegation logic can be configured to allow delegation other than to
C<SUPER::> or C<NEXT::>. The configuration item is
C<allow_delegation_to>, and it takes a space-delimited list of allowed
delegates. If a given delegate ends in a double colon, anything in the
given namespace is allowed. If it does not, only that subroutine is
allowed. For example, to allow C<next::method> from C<Class::C3> and
_delegate from the current namespace in addition to SUPER and NEXT, the
following configuration could be used:

  [Subroutines::RequireArgUnpacking]
  allow_delegation_to = next::method _delegate

=head1 CAVEATS

PPI doesn't currently detect anonymous subroutines, so we don't check
those.  This should just work when PPI gains that feature.

We don't check for C<@ARG>, the alias for C<@_> from English.pm.  That's
deprecated anyway.

=head1 CREDITS

Initial development of this policy was supported by a grant from the
Perl Foundation.

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2007-2011 Chris Dolan.  Many rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
