package Perl::Critic::Policy::CodeLayout::ProhibitQuotedWordLists;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw{ :characters :severities :classification};
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

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
        {
            name            => 'strict',
            description     => 'Complain even if there are non-word characters in the values.',
            default_string  => '0',
            behavior        => 'boolean',
        },
    );
}

sub default_severity { return $SEVERITY_LOW          }
sub default_themes   { return qw( core cosmetic )    }
sub applies_to       { return 'PPI::Structure::List' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    # Don't worry about subroutine calls
    my $sibling = $elem->sprevious_sibling();
    return if not $sibling;

    return if $sibling->isa('PPI::Token::Symbol');
    return if $sibling->isa('PPI::Token::Operator') and $sibling eq '->';
    return if $sibling->isa('PPI::Token::Word') and not is_included_module_name($sibling);

    # Get the list elements
    my $expr = $elem->schild(0);
    return if not $expr;
    my @children = $expr->schildren();
    return if not @children;

    my $count = 0;
    for my $child ( @children ) {
        next if $child->isa('PPI::Token::Operator')  && $child eq $COMMA;

        # All elements must be literal strings,
        # and must contain 1 or more word characters.

        return if not _is_literal($child);

        my $string = $child->string();
        return if $string =~ m{ \s }xms;
        return if $string eq $EMPTY;
        return if not $self->{_strict} and $string !~ m{\A [\w-]+ \z}xms;
        $count++;
    }

    # Were there enough?
    return if $count < $self->{_min_elements};

    # If we get here, then all elements were literals
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

Perl::Critic::Policy::CodeLayout::ProhibitQuotedWordLists - Write C<qw(foo bar baz)> instead of C<('foo', 'bar', 'baz')>.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Conway doesn't mention this, but I think C<qw()> is an underused
feature of Perl.  Whenever you need to declare a list of one-word
literals, the C<qw()> operator is wonderfully concise, and makes it
easy to add to the list in the future.

    @list = ('foo', 'bar', 'baz');  #not ok
    @list = qw(foo bar baz);        #ok

    use Foo ('foo', 'bar', 'baz');  #not ok
    use Foo qw(foo bar baz);        #ok

=head1 CONFIGURATION

This policy can be configured to only pay attention to word lists with
at least a particular number of elements.  By default, this value is
2, which means that lists containing zero or one elements are ignored.
The minimum list size to be looked at can be specified by giving a
value for C<min_elements> in F<.perlcriticrc> like this:

    [CodeLayout::ProhibitQuotedWordLists]
    min_elements = 4

This would cause this policy to only complain about lists containing
four or more words.

By default, this policy won't complain if any of the values in the list
contain non-word characters.  If you want it to, set the C<strict>
option to a true value.

    [CodeLayout::ProhibitQuotedWordLists]
    strict = 1


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
