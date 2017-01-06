package Perl::Critic::Policy::CodeLayout::RequireTrailingCommas;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :characters :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{List declaration without trailing comma};
Readonly::Scalar my $EXPL => [ 17 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                     }
sub default_severity     { return $SEVERITY_LOWEST       }
sub default_themes       { return qw(core pbp cosmetic)  }
sub applies_to           { return 'PPI::Structure::List' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    $elem =~ m{ \n }xms || return;

    # Is it an assignment of some kind?
    my $sib = $elem->sprevious_sibling();
    return if !$sib;
    $sib->isa('PPI::Token::Operator') && $sib =~ m{ = }xms || return;

    # List elements are children of an expression
    my $expr = $elem->schild(0);
    return if !$expr;

    # Does the list have more than 1 element?
    # This means list element, not PPI element.
    my @children = $expr->schildren();
    return if 1 >= grep {    $_->isa('PPI::Token::Operator')
                          && $_ eq $COMMA } @children;

    # Is the final element a comma?
    my $final = $children[-1];
    if ( ! ($final->isa('PPI::Token::Operator') && $final eq $COMMA) ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }

    return; #ok!
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::CodeLayout::RequireTrailingCommas - Put a comma at the end of every multi-line list declaration, including the last one.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Conway suggests that all elements in a multi-line list should be
separated by commas, including the last element.  This makes it a
little easier to re-order the list by cutting and pasting.

    my @list = ($foo,
                $bar,
                $baz);  #not ok

    my @list = ($foo,
                $bar,
                $baz,); #ok


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 NOTES

In the PPI parlance, a "list" is almost anything with parentheses.
I've tried to make this Policy smart by targeting only "lists" that
have at least one element and are being assigned to something.
However, there may be some edge cases that I haven't covered.  If you
find one, send me a note.


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
