package Perl::Critic::Policy::ErrorHandling::RequireCarping;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{
    :booleans :characters :severities :classification :data_conversion
};
use Perl::Critic::Utils::PPI qw{ is_ppi_expression_or_generic_statement };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL => [ 283 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name           => 'allow_messages_ending_with_newlines',
            description    => q{Don't complain about die or warn if the message ends in a newline.},
            default_string => '1',
            behavior       => 'boolean',
        },
        {
            name           => 'allow_in_main_unless_in_subroutine',
            description    => q{Don't complain about die or warn in main::, unless in a subroutine.},
            default_string => '0',
            behavior       => 'boolean',
        },
    );
}

sub default_severity  { return $SEVERITY_MEDIUM                          }
sub default_themes    { return qw( core pbp maintenance certrule )                }
sub applies_to        { return 'PPI::Token::Word'                        }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    my $alternative;
    if ( $elem eq 'warn' ) {
        $alternative = 'carp';
    }
    elsif ( $elem eq 'die' ) {
        $alternative = 'croak';
    }
    else {
        return;
    }

    return if ! is_function_call($elem);

    if ($self->{_allow_messages_ending_with_newlines}) {
        return if _last_flattened_argument_list_element_ends_in_newline($elem);
    }

    return if $self->{_allow_in_main_unless_in_subroutine}
        && !$self->_is_element_contained_in_subroutine( $elem )
        && $self->_is_element_in_namespace_main( $elem );    # RT #56619

    my $desc = qq{"$elem" used instead of "$alternative"};
    return $self->violation( $desc, $EXPL, $elem );
}

#-----------------------------------------------------------------------------

sub _last_flattened_argument_list_element_ends_in_newline {
    my $die_or_warn = shift;

    my $last_flattened_argument =
        _find_last_flattened_argument_list_element($die_or_warn)
        or return $FALSE;

    if ( $last_flattened_argument->isa('PPI::Token::Quote') ) {
        my $last_flattened_argument_string =
            $last_flattened_argument->string();
        if (
                $last_flattened_argument_string =~ m{ \n \z }xms
            or (
                    (
                            $last_flattened_argument->isa('PPI::Token::Quote::Double')
                        or $last_flattened_argument->isa('PPI::Token::Quote::Interpolate')
                    )
                and $last_flattened_argument_string =~ m{ [\\] n \z }xms
            )
        ) {
            return $TRUE;
        }
    }
    elsif ( $last_flattened_argument->isa('PPI::Token::HereDoc') ) {
        return $TRUE;
    }

    return $FALSE
}

#-----------------------------------------------------------------------------
# Here starts the fun.  Explanation by example:
#
# Let's say we've got the following (contrived) statement:
#
#    die q{Isn't }, ( $this, ( " fun?\n" ) , ) if "It isn't Monday.";
#
# This statement should pass because the last parameter that die is going to
# get is C<" fun?\n">.
#
# The approach is to first find the last non-flattened parameter.  If this
# is a simple token, we're done.  Else, it's some aggregate thing.  We can't
# tell what C<some_function( "foo\n" )> is going to do, so we give up on
# anything other than a PPI::Structure::List.
#
# There are three possible scenarios for the children of a List:
#
#   * No children of the List, i.e. the list looks like C< ( ) >.
#   * One PPI::Statement::Expression element.
#   * One PPI::Statement element.  That's right, an instance of the base
#     statement class and not some subclass.  *sigh*
#
# In the first case, we're done.  The latter two cases get treated
# identically.  We get the last child of the Statement and start the search
# all over again.
#
# Back to our example.  The PPI tree for this expression is
#
#     PPI::Document
#       PPI::Statement
#         PPI::Token::Word    'die'
#         PPI::Token::Quote::Literal          'q{Isn't }'
#         PPI::Token::Operator        ','
#         PPI::Structure::List        ( ... )
#           PPI::Statement::Expression
#             PPI::Token::Symbol      '$this'
#             PPI::Token::Operator    ','
#             PPI::Structure::List    ( ... )
#               PPI::Statement::Expression
#                 PPI::Token::Quote::Double   '" fun?\n"'
#             PPI::Token::Operator    ','
#         PPI::Token::Word    'if'
#         PPI::Token::Quote::Double   '"It isn't Monday.\n"'
#         PPI::Token::Structure       ';'
#
# We're starting with the Word containing 'die' (it could just as well be
# 'warn') because the earlier parts of validate() have taken care of any
# other possibility.  We're going to scan forward through 'die's siblings
# until we reach what we think the end of its parameters are. So we get
#
#     1. A Literal. A perfectly good argument.
#     2. A comma operator. Looks like we've got more to go.
#     3. A List. Another argument.
#     4. The Word 'if'.  Oops.  That's a postfix operator.
#
# Thus, the last parameter is the List.  So, we've got to scan backwards
# through the components of the List; again, the goal is to find the last
# value in the flattened list.
#
# Before decending into the List, we check that it isn't a subroutine call by
# looking at its prior sibling.  In this case, the prior sibling is a comma
# operator, so it's fine.
#
# The List has one Expression element as we expect.  We grab the Expression's
# last child and start all over again.
#
#     1. The last child is a comma operator, which Perl will ignore, so we
#        skip it.
#     2. The comma's prior sibling is a List.  This is the last significant
#        part of the outer list.
#     3. The List's prior sibling isn't a Word, so we can continue because the
#        List is not a parameter list.
#     4. We go through the child Expression and find that the last child of
#        that is a PPI::Token::Quote::Double, which is a simple, non-compound
#        token.  We return that and we're done.

sub _find_last_flattened_argument_list_element {
    my $die_or_warn = shift;

    # Zoom forward...
    my $current_candidate =
        _find_last_element_in_subexpression($die_or_warn);

    # ... scan back.
    while (
            $current_candidate
        and not _is_simple_list_element_token( $current_candidate )
        and not _is_complex_expression_token( $current_candidate )
    ) {
        if ( $current_candidate->isa('PPI::Structure::List') ) {
            $current_candidate =
                _determine_if_list_is_a_plain_list_and_get_last_child(
                    $current_candidate,
                    $die_or_warn
                );
        } elsif ( not $current_candidate->isa('PPI::Token') ) {
            return;
        } else {
            $current_candidate = $current_candidate->sprevious_sibling();
        }
    }

    return if not $current_candidate;
    return if _is_complex_expression_token( $current_candidate );

    my $penultimate_element = $current_candidate->sprevious_sibling();
    if ($penultimate_element) {
        # Bail if we've got a Word in front of the Element that isn't
        # the original 'die' or 'warn' or anything else that isn't
        # a comma or dot operator.
        if ( $penultimate_element->isa('PPI::Token::Operator') ) {
            if (
                    $penultimate_element ne $COMMA
                and $penultimate_element ne $PERIOD
            ) {
                return;
            }
        } elsif ( $penultimate_element != $die_or_warn ) {
            return
        }
    }

    return $current_candidate;
}

#-----------------------------------------------------------------------------
# This is the part where we scan forward from the 'die' or 'warn' to find
# the last argument.

sub _find_last_element_in_subexpression {
    my $die_or_warn = shift;

    my $last_following_sibling;
    my $next_sibling = $die_or_warn;
    while (
            $next_sibling = $next_sibling->snext_sibling()
        and not _is_postfix_operator( $next_sibling )
    ) {
        $last_following_sibling = $next_sibling;
    }

    return $last_following_sibling;
}

#-----------------------------------------------------------------------------
# Ensure that the list isn't a parameter list.  Find the last element of it.

sub _determine_if_list_is_a_plain_list_and_get_last_child {
    my ($list, $die_or_warn) = @_;

    my $prior_sibling = $list->sprevious_sibling();

    if ( $prior_sibling ) {
        # Bail if we've got a Word in front of the List that isn't
        # the original 'die' or 'warn' or anything else that isn't
        # a comma operator.
        if ( $prior_sibling->isa('PPI::Token::Operator') ) {
            if ( $prior_sibling ne $COMMA ) {
                return;
            }
        } elsif ( $prior_sibling != $die_or_warn ) {
            return
        }
    }

    my @list_children = $list->schildren();

    # If zero children, nothing to look for.
    # If multiple children, then PPI is not giving us
    # anything we understand.
    return if scalar (@list_children) != 1;

    my $list_child = $list_children[0];

    # If the child isn't an Expression or it is some other subclass
    # of Statement, we again don't understand PPI's output.
    return if not is_ppi_expression_or_generic_statement($list_child);

    my @statement_children = $list_child->schildren();
    return if scalar (@statement_children) < 1;

    return $statement_children[-1];
}


#-----------------------------------------------------------------------------
Readonly::Hash my %POSTFIX_OPERATORS =>
    hashify qw{ if unless while until for foreach };

sub _is_postfix_operator {
    my $element = shift;

    if (
            $element->isa('PPI::Token::Word')
        and $POSTFIX_OPERATORS{$element}
    ) {
        return $TRUE;
    }

    return $FALSE;
}


Readonly::Array my @SIMPLE_LIST_ELEMENT_TOKEN_CLASSES =>
    qw{
        PPI::Token::Number
        PPI::Token::Word
        PPI::Token::DashedWord
        PPI::Token::Symbol
        PPI::Token::Quote
        PPI::Token::HereDoc
    };

sub _is_simple_list_element_token {
    my $element = shift;

    return $FALSE if not $element->isa('PPI::Token');

    foreach my $class (@SIMPLE_LIST_ELEMENT_TOKEN_CLASSES) {
        return $TRUE if $element->isa($class);
    }

    return $FALSE;
}


#-----------------------------------------------------------------------------
# Tokens that can't possibly be part of an expression simple
# enough for us to examine.

Readonly::Array my @COMPLEX_EXPRESSION_TOKEN_CLASSES =>
    qw{
        PPI::Token::ArrayIndex
        PPI::Token::QuoteLike
        PPI::Token::Regexp
        PPI::Token::Cast
        PPI::Token::Label
        PPI::Token::Separator
        PPI::Token::Data
        PPI::Token::End
        PPI::Token::Prototype
        PPI::Token::Attribute
        PPI::Token::Unknown
    };

sub _is_complex_expression_token {
    my $element = shift;

    return $FALSE if not $element->isa('PPI::Token');

    foreach my $class (@COMPLEX_EXPRESSION_TOKEN_CLASSES) {
        return $TRUE if $element->isa($class);
    }

    return $FALSE;
}

#-----------------------------------------------------------------------------
# Check whether the given element is contained in a subroutine.

sub _is_element_contained_in_subroutine {
    my ( $self, $elem ) = @_;

    my $parent = $elem;
    while ( $parent = $parent->parent() ) {
        $parent->isa( 'PPI::Statement::Sub' ) and return $TRUE;
        $parent->isa( 'PPI::Structure::Block' ) or next;
        my $prior_elem = $parent->sprevious_sibling() or next;
        $prior_elem->isa( 'PPI::Token::Word' )
            and 'sub' eq $prior_elem->content()
            and return $TRUE;
    }

    return $FALSE;
}

#-----------------------------------------------------------------------------
# Check whether the given element is in main::

sub _is_element_in_namespace_main {
    my ( $self, $elem ) = @_;
    my $current_elem = $elem;
    my $prior_elem;

    while ( $current_elem ) {
        while ( $prior_elem = $current_elem->sprevious_sibling() ) {
            if ( $prior_elem->isa( 'PPI::Statement::Package' ) ) {
                return 'main' eq $prior_elem->namespace();
            }
        } continue {
            $current_elem = $prior_elem;
        }
        $current_elem = $current_elem->parent();
    }

    return $TRUE;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ErrorHandling::RequireCarping - Use functions from L<Carp|Carp> instead of C<warn> or C<die>.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

The C<die> and C<warn> functions both report the file and line number
where the exception occurred.  But if someone else is using your
subroutine, they usually don't care where B<your> code blew up.
Instead, they want to know where B<their> code invoked the subroutine.
The L<Carp|Carp> module provides alternative methods that report the
exception from the caller's file and line number.

By default, this policy will not complain about C<die> or C<warn>, if
it can determine that the message will always result in a terminal
newline.  Since perl suppresses file names and line numbers in this
situation, it is assumed that no stack traces are desired either and
none of the L<Carp|Carp> functions are necessary.

    die "oops" if $explosion;             #not ok
    warn "Where? Where?!" if $tiger;      #not ok

    open my $mouth, '<', 'food'
        or die 'of starvation';           #not ok

    if (! $dentist_appointment) {
        warn "You have bad breath!\n";    #ok
    }

    die "$clock not set.\n" if $no_time;  #ok

    my $message = "$clock not set.\n";
    die $message if $no_time;             #not ok, not obvious


=head1 CONFIGURATION

By default, this policy allows uses of C<die> and C<warn> ending in an
explicit newline. If you give this policy an
C<allow_messages_ending_with_newlines> option in your F<.perlcriticrc>
with a false value, then this policy will prohibit such uses.

    [ErrorHandling::RequireCarping]
    allow_messages_ending_with_newlines = 0

If you give this policy an C<allow_in_main_unless_in_subroutine> option
in your F<.perlcriticrc> with a true value, then this policy will allow
C<die> and C<warn> in name space main:: unless they appear in a
subroutine, even if they do not end in an explicit newline.

    [ErrorHandling::RequireCarping]
    allow_in_main_unless_in_subroutine = 1

=head1 BUGS

Should allow C<die> when it is obvious that the "message" is a reference.


=head1 SEE ALSO

L<Carp::Always|Carp::Always>


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
