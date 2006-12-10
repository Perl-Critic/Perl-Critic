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

sub default_severity { return $SEVERITY_MEDIUM   }
sub default_themes   { return qw(core pbp unreliable) }
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

sub _find_last_flattened_list_element {
    my $starting_element = shift;

    my $last_following_sibling;
    my $next_sibling = $starting_element;
    while ( $next_sibling = $next_sibling->snext_sibling() ) {
        $last_following_sibling = $next_sibling;
    }

    return if not $last_following_sibling;

    my $current_candidate = $last_following_sibling;
    while (
            not _is_list_element_token( $current_candidate )
        and not _is_stop_token( $current_candidate )
    ) {
        return if not $current_candidate->isa('PPI::Token'); # Lists not handled yet.

        $current_candidate = $current_candidate->sprevious_sibling();
    }

    return if _is_stop_token( $current_candidate );

    return $current_candidate;
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

    return 0 if not $element->isa('PPI::Token');

    foreach my $class (@LIST_ELEMENT_TOKEN_CLASSES) {
        return 1 if $element->isa($class);
    }

    return 0;
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

    return 0 if not $element->isa('PPI::Token');

    foreach my $class (@STOP_TOKEN_CLASSES) {
        return 1 if $element->isa($class);
    }

    return 0;
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
