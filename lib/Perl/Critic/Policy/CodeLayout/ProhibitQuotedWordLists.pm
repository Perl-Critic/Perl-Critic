##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::CodeLayout::ProhibitQuotedWordLists;

use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :characters :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.082';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{List of quoted literal words};
Readonly::Scalar my $EXPL => q{Use 'qw()' instead};

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'min_elements',
            description     => 'The minimum number of words in a list that will be complained about.',
            default_string  => '2',
            behavior        => 'integer',
            integer_minimum => 1,
        },
    );
}

sub default_severity { return $SEVERITY_LOW          }
sub default_themes   { return qw( core cosmetic )    }
sub applies_to       { return 'PPI::Structure::List' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    #Don't worry about subroutine calls
    my $sib = $elem->sprevious_sibling();
    return if !$sib;
    return if $sib->isa('PPI::Token::Word');
    return if $sib->isa('PPI::Token::Symbol');

    #Get the list elements
    my $expr = $elem->schild(0);
    return if !$expr;
    my @children = $expr->schildren();
    return if !@children;

    my $count = 0;
    for my $child ( @children ) {
        next if $child->isa('PPI::Token::Operator')  && $child eq $COMMA;

        #All elements must be literal strings,
        #of non-zero length, with no whitespace

        return if ! _is_literal($child);

        my $string = $child->string();
        return if $string =~ m{ \s }mx;
        return if $string eq $EMPTY;
        $count++;
    }

    #Were there enough?
    return if $count < $self->{_min_elements};

    #If we get here, then all elements were literals
    return $self->violation( $DESC, $EXPL, $elem );
}

sub _is_literal {
    my $elem = shift;
    return $elem->isa('PPI::Token::Quote::Single')
        || $elem->isa('PPI::Token::Quote::Literal');
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::CodeLayout::ProhibitQuotedWordLists

=head1 DESCRIPTION

Conway doesn't mention this, but I think C<qw()> is an underused
feature of Perl.  Whenever you need to declare a list of one-word
literals, the C<qw()> operator is wonderfully concise, and makes
it easy to add to the list in the future.

  @list = ('foo', 'bar', 'baz');  #not ok
  @list = qw(foo bar baz);        #ok

=head1 CONFIGURATION

This policy can be configured to only pay attention to word lists with
at least a particular number of elements.  By default, this value is 2,
which means that lists containing zero or one elements are ignored.
The minimum list size to be looked at can be specified by giving a
value for C<min_elements> in F<.perlcriticrc> like this:

  [CodeLayout::ProhibitQuotedWordLists]
  min_elements = 4

This would cause this policy to only complain about lists containing
four or more words.

=head1 NOTES

In the PPI parlance, a "list" is almost anything with parentheses.
I've tried to make this Policy smart by targeting only "lists" that
could be sensibly expressed with C<qw()>.  However, there may be some
edge cases that I haven't covered.  If you find one, send me a note.

=head1 IMPORTANT CHANGES

This policy was formerly called C<RequireQuotedWords> which seemed a
little counter-intuitive.  If you get lots of "Cannot load policy
module" errors, then you probably need to change C<RequireQuotedWords>
to C<ProhibitQuotedWordLists> in your F<.perlcriticrc> file.


=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

Copyright (c) 2005-2008 Jeffrey Ryan Thalhammer.  All rights reserved.

=head1 COPYRIGHT

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
