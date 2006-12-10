##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::ErrorHandling::RequireCarping;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.22;

#-----------------------------------------------------------------------------

my $expl = [ 283 ];

#-----------------------------------------------------------------------------

# TODO: make configurable to be strict again.
sub default_severity { return $SEVERITY_MEDIUM   }
sub default_themes   { return qw(core pbp maintenance) }
sub applies_to       { return 'PPI::Token::Word' }

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

    my $last_list_element = _find_last_flattened_list_element($elem);
    if (
            $last_list_element
        and (
                $last_list_element->isa('PPI::Token::Quote::Double')
            or  $last_list_element->isa('PPI::Token::Quote::Interpolate')
        )
    ) {
        return if $last_list_element =~ m{ [\\] n . \z }xmso;
    }

    my $desc = qq{"$elem" used instead of "$alternative"};
    return $self->violation( $desc, $expl, $elem );
}

# TODO: refactor this overly complicated function
sub _find_last_flattened_list_element {
    my $starting_element = shift;

    my $last_following_sibling;
    my $next_sibling = $starting_element;
    while (
            $next_sibling = $next_sibling->snext_sibling()
        and not _is_postfix_operator( $next_sibling )
    ) {
        $last_following_sibling = $next_sibling;
    }

    return if not $last_following_sibling;

    my $current_candidate = $last_following_sibling;
    while (
            not _is_list_element_token( $current_candidate )
        and not _is_stop_token( $current_candidate )
    ) {
        if ( $current_candidate->isa('PPI::Structure::List') ) {
            my $prior_sibling = $current_candidate->sprevious_sibling();

            if ( $prior_sibling ) {
                if ( $prior_sibling->isa('PPI::Token::Operator') ) {
                    if ( $prior_sibling != $COMMA ) {
                        return;
                    }
                } elsif ( $prior_sibling != $starting_element ) {
                    return
                }
            }

            my @list_children = $current_candidate->schildren();

            # If zero children, nothing to look for.
            # If multiple children, then PPI is not giving us
            # anything we understand.
            return if scalar (@list_children) != 1;

            my $list_child = $list_children[0];
            return if not $list_child->isa('PPI::Statement');
            if (
                    not $list_child->isa('PPI::Statement::Expression')
                and ref $list_child ne 'PPI::Statement'
            ) {
                return;
            }

            my @statement_children = $list_child->schildren();
            return if scalar (@statement_children) < 1;

            $current_candidate = $statement_children[-1];
        } elsif ( not $current_candidate->isa('PPI::Token') ) {
            return;
        } else {
            $current_candidate = $current_candidate->sprevious_sibling();
        }
    }

    return if _is_stop_token( $current_candidate );

    return $current_candidate;
}


my %POSTFIX_OPERATORS = hashify qw{ if unless while until for foreach };

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


my @LIST_ELEMENT_TOKEN_CLASSES =
    qw{
        PPI::Token::Number
        PPI::Token::Word
        PPI::Token::DashedWord
        PPI::Token::Symbol
        PPI::Token::Quote
    };

sub _is_list_element_token {
    my $element = shift;

    return $FALSE if not $element->isa('PPI::Token');

    foreach my $class (@LIST_ELEMENT_TOKEN_CLASSES) {
        return $TRUE if $element->isa($class);
    }

    return $FALSE;
}


my @STOP_TOKEN_CLASSES =
    qw{
        PPI::Token::ArrayIndex
        PPI::Token::QuoteLike
        PPI::Token::Regexp
        PPI::Token::HereDoc
        PPI::Token::Cast
        PPI::Token::Label
        PPI::Token::Separator
        PPI::Token::Data
        PPI::Token::End
        PPI::Token::Prototype
        PPI::Token::Attribute
        PPI::Token::Unknown
    };

sub _is_stop_token {
    my $element = shift;

    return $FALSE if not $element->isa('PPI::Token');

    foreach my $class (@STOP_TOKEN_CLASSES) {
        return $TRUE if $element->isa($class);
    }

    return $FALSE;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ErrorHandling::RequireCarping

=head1 DESCRIPTION

The C<die> and C<warn> functions both report the file and line number
where the exception occurred.  But if someone else is using your
subroutine, they usually don't care where B<your> code blew up.
Instead, they want to know where B<their> code invoked the subroutine.
The L<Carp> module provides alternative methods that report the
exception from the caller's file and line number.


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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
