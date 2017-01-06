package Perl::Critic::Policy::Subroutines::ProhibitUnusedPrivateSubroutines;

use 5.006001;

use strict;
use warnings;

use English qw< $EVAL_ERROR -no_match_vars >;
use List::MoreUtils qw(any);
use Readonly;

use Perl::Critic::Utils qw{
    :characters hashify is_function_call is_method_call :severities
    $EMPTY $TRUE
};
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC =>
    q{Private subroutine/method '%s' declared but not used};
Readonly::Scalar my $EXPL => q{Eliminate dead code};

Readonly::Hash my %IS_COMMA => hashify( $COMMA, $FATCOMMA );

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'private_name_regex',
            description     => 'Pattern that determines what a private subroutine is.',
            default_string  => '\b_\w+\b',  ## no critic (RequireInterpolationOfMetachars)
            behavior        => 'string',
            parser          => \&_parse_private_name_regex,
        },
        {
            name            => 'allow',
            description     =>
                q<Subroutines matching the private name regex to allow under this policy.>,
            default_string  => $EMPTY,
            behavior        => 'string list',
        },
        {
            name            => 'skip_when_using',
            description     =>
                q<Modules that, if used within a file, will cause the policy to be disabled for this file>,
            default_string  => $EMPTY,
            behavior        => 'string list',
        },
    );
}

sub default_severity     { return $SEVERITY_MEDIUM       }
sub default_themes       { return qw( core maintenance certrec ) }
sub applies_to           { return 'PPI::Statement::Sub'  }

#-----------------------------------------------------------------------------

sub _parse_private_name_regex {
    my ($self, $parameter, $config_string) = @_;
    defined $config_string
        or $config_string = $parameter->get_default_string();

    my $regex;
    eval { $regex = qr/$config_string/; 1 } ## no critic (RegularExpressions)
        or $self->throw_parameter_value_exception(
            'private_name_regex',
            $config_string,
            undef,
            "is not a valid regular expression: $EVAL_ERROR",
        );

    $self->__set_parameter_value($parameter, $regex);

    return;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $document ) = @_;

    my @skip_modules = keys %{ $self->{_skip_when_using} };
    return if any { $document->uses_module($_) } @skip_modules;

    # Not interested in forward declarations, only the real thing.
    $elem->forward() and return;

    # Not interested in subs without names.
    my $name = $elem->name() or return;

    # If the sub is shoved into someone else's name space, we wimp out.
    $name =~ m/ :: /smx and return;

    # If the name is explicitly allowed, we just return (OK).
    $self->{_allow}{$name} and return;

    # If the name is not an anonymous subroutine according to our definition,
    # we just return (OK).
    $name =~ m/ \A $self->{_private_name_regex} \z /smx or return;

    # If the subroutine is called in the document, just return (OK).
    $self->_find_sub_call_in_document( $elem, $document ) and return;

    # If the subroutine is referred to in the document, just return (OK).
    $self->_find_sub_reference_in_document( $elem, $document ) and return;

    # If the subroutine is used in an overload, just return (OK).
    $self->_find_sub_overload_in_document( $elem, $document ) and return;

    # No uses of subroutine found. Return a violation.
    return $self->violation( sprintf( $DESC, $name ), $EXPL, $elem );
}


# Basically the spaceship operator for token locations. The arguments are the
# two tokens to compare. If either location is unavailable we return undef.
sub _compare_token_locations {
    my ( $left_token, $right_token ) = @_;
    my $left_loc = $left_token->location() or return;
    my $right_loc = $right_token->location() or return;
    return $left_loc->[0] <=> $right_loc->[0] ||
        $left_loc->[1] <=> $right_loc->[1];
}

# Find out if the subroutine defined in $elem is called in $document. Calls
# inside the subroutine itself do not count.
sub _find_sub_call_in_document {
    my ( $self, $elem, $document ) = @_;

    my $start_token = $elem->first_token();
    my $finish_token = $elem->last_token();
    my $name = $elem->name();

    if ( my $found = $document->find( 'PPI::Token::Word' ) ) {
        foreach my $usage ( @{ $found } ) {
            $name eq $usage->content() or next;
            is_function_call( $usage )
                or is_method_call( $usage )
                or next;
            _compare_token_locations( $usage, $start_token ) < 0
                and return $TRUE;
            _compare_token_locations( $finish_token, $usage ) < 0
                and return $TRUE;
        }
    }

    foreach my $regexp ( _find_regular_expressions( $document ) ) {

        _compare_token_locations( $regexp, $start_token ) >= 0
            and _compare_token_locations( $finish_token, $regexp ) >= 0
            and next;
        _find_sub_usage_in_regexp( $name, $regexp, $document )
            and return $TRUE;

    }

    return;
}

# Find analyzable regular expressions in the given document. This means
# matches, substitutions, and the qr{} operator.
sub _find_regular_expressions {
    my ( $document ) = @_;

    return ( map { @{ $document->find( $_ ) || [] } } qw{
        PPI::Token::Regexp::Match
        PPI::Token::Regexp::Substitute
        PPI::Token::QuoteLike::Regexp
    } );
}

# Find out if the subroutine named in $name is called in the given $regexp.
# This could happen either by an explicit s/.../.../e, or by interpolation
# (i.e. @{[...]} ).
sub _find_sub_usage_in_regexp {
    my ( $name, $regexp, $document ) = @_;

    my $ppix = $document->ppix_regexp_from_element( $regexp ) or return;
    $ppix->failures() and return;

    foreach my $code ( @{ $ppix->find( 'PPIx::Regexp::Token::Code' ) || [] } ) {
        my $doc = $code->ppi() or next;

        foreach my $word ( @{ $doc->find( 'PPI::Token::Word' ) || [] } ) {
            $name eq $word->content() or next;
            is_function_call( $word )
                or is_method_call( $word )
                or next;
            return $TRUE;
        }

    }

    return;
}

# Find out if the subroutine defined in $elem handles an overloaded operator.
# We recognize both string literals (the usual form) and words (in case
# someone perversely followed the subroutine name by a fat comma). We ignore
# the '\&_foo' construction, since _find_sub_reference_in_document() should
# find this.
sub _find_sub_overload_in_document {
    my ( $self, $elem, $document ) = @_;

    my $name = $elem->name();

    if ( my $found = $document->find( 'PPI::Statement::Include' ) ) {
        foreach my $usage ( @{ $found } ) {
            'overload' eq $usage->module() or next;
            my $inx;
            foreach my $arg ( _get_include_arguments( $usage ) ) {
                $inx++ % 2 or next;
                @{ $arg } == 1 or next;
                my $element = $arg->[0];

                if ( $element->isa( 'PPI::Token::Quote' ) ) {
                    $element->string() eq $name and return $TRUE;
                } elsif ( $element->isa( 'PPI::Token::Word' ) ) {
                    $element->content() eq $name and return $TRUE;
                }
            }
        }
    }

    return;
}

# Find things of the form '&_foo'. This includes both references proper (i.e.
# '\&foo'), calls using the sigil, and gotos. The latter two do not count if
# inside the subroutine itself.
sub _find_sub_reference_in_document {
    my ( $self, $elem, $document ) = @_;

    my $start_token = $elem->first_token();
    my $finish_token = $elem->last_token();
    my $symbol = q<&> . $elem->name();

    if ( my $found = $document->find( 'PPI::Token::Symbol' ) ) {
        foreach my $usage ( @{ $found } ) {
            $symbol eq $usage->content() or next;

            my $prior = $usage->sprevious_sibling();
            $prior
                and $prior->isa( 'PPI::Token::Cast' )
                and q<\\> eq $prior->content()
                and return $TRUE;

            is_function_call( $usage )
                or $prior
                    and $prior->isa( 'PPI::Token::Word' )
                    and 'goto' eq $prior->content()
                or next;

            _compare_token_locations( $usage, $start_token ) < 0
                and return $TRUE;
            _compare_token_locations( $finish_token, $usage ) < 0
                and return $TRUE;
        }
    }

    return;
}

# Expand the given element, losing any brackets along the way. This is
# intended to be used to flatten the argument list of 'use overload'.
sub _expand_element {
    my ( $element ) = @_;
    $element->isa( 'PPI::Node' )
        and return ( map { _expand_element( $_ ) } $_->children() );
    $element->significant() and return $element;
    return;
}

# Given an include statement, return its arguments. The return is a flattened
# list of lists of tokens, each list of tokens representing an argument.
sub _get_include_arguments {
    my ($include) = @_;

    # If there are no arguments, just return. We flatten the list because
    # someone might use parens to define it.
    my @arguments = map { _expand_element( $_ ) } $include->arguments()
        or return;

    my @elements;
    my $inx = 0;
    foreach my $element ( @arguments ) {
        if ( $element->isa( 'PPI::Token::Operator' ) &&
            $IS_COMMA{$element->content()} ) {
            $inx++;
        } else {
            push @{ $elements[$inx] ||= [] }, $element;
        }
    }

    return @elements;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::ProhibitUnusedPrivateSubroutines - Prevent unused private subroutines.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

By convention Perl authors (like authors in many other languages)
indicate private methods and variables by inserting a leading
underscore before the identifier.  This policy catches such subroutines
which are not used in the file which declares them.

This module defines a 'use' of a subroutine as a subroutine or method call to
it (other than from inside the subroutine itself), a reference to it (i.e.
C<< my $foo = \&_foo >>), a C<goto> to it outside the subroutine itself (i.e.
C<goto &_foo>), or the use of the subroutine's name as an even-numbered
argument to C<< use overload >>.


=head1 CONFIGURATION

You can define what a private subroutine name looks like by specifying
a regular expression for the C<private_name_regex> option in your
F<.perlcriticrc>:

    [Subroutines::ProhibitUnusedPrivateSubroutines]
    private_name_regex = _(?!_)\w+

The above example is a way of saying that subroutines that start with
a double underscore are not considered to be private.  (Perl::Critic,
in its implementation, uses leading double underscores to indicate a
distribution-private subroutine -- one that is allowed to be invoked by
other Perl::Critic modules, but not by anything outside of
Perl::Critic.)

You can configure additional subroutines to accept by specifying them
in a space-delimited list to the C<allow> option:

    [Subroutines::ProhibitUnusedPrivateSubroutines]
    allow = _bar _baz

These are added to the default list of exemptions from this policy. So the
above allows C<< sub _bar {} >> and C<< sub _baz {} >>, even if they are not
referred to in the module that defines them.

You can configure this policy not to check private subroutines declared in a
file that uses one or more particular named modules.  This allows you to, for
example, exclude unused private subroutine checking in classes that are roles.

    [Subroutines::ProhibitUnusedPrivateSubroutines]
    skip_when_using = Moose::Role Moo::Role Role::Tiny


=head1 HISTORY

This policy is derived from
L<Perl::Critic::Policy::Subroutines::ProtectPrivateSubs|Perl::Critic::Policy::Subroutines::ProtectPrivateSubs>,
which looks at the other side of the problem.


=head1 BUGS

Does not forbid C<< sub Foo::_foo{} >> because it does not know (and can not
assume) what is in the C<Foo> package.

Does not respect the scope caused by multiple packages in the same file.  For
example a file:

    package Foo;
    sub _is_private { print "A private sub!"; }

    package Bar;
    _is_private();

Will not trigger a violation even though C<Foo::_is_private> is not called.
Similarly, C<skip_when_using> currently works on a I<file> level, not on a
I<package scope> level.


=head1 SEE ALSO

L<Perl::Critic::Policy::Subroutines::ProtectPrivateSubs|Perl::Critic::Policy::Subroutines::ProtectPrivateSubs>.


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2009-2011 Thomas R. Wyant, III.

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
