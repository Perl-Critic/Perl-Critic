#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::CodeLayout::RequireTrailingCommas;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.20;

#----------------------------------------------------------------------------

my $desc  = q{List declaration without trailing comma};
my $expl  = [ 17 ];

#----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_LOWEST }
sub default_themes    { return qw(pbp cosmetic) }
sub applies_to       { return 'PPI::Structure::List' }

#----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    $elem =~ m{ \n }mx || return;

    # Is it an assignment of some kind?
    my $sib = $elem->sprevious_sibling();
    return if !$sib;
    $sib->isa('PPI::Token::Operator') && $sib =~ m{ = }mx || return;

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
        return $self->violation( $desc, $expl, $elem );
    }

    return; #ok!
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::CodeLayout::RequireTrailingCommas

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

=head1 NOTES

In the PPI parlance, a "list" is almost anything with parens.  I've
tried to make this Policy smart by targeting only "lists" that have at
least one element and are being assigned to something.  However, there
may be some edge cases that I haven't covered.  If you find one, send
me a note.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
