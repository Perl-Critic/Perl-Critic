package Perl::Critic::Policy::CodeLayout::ProhibitQuotedWordLists;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.13';
$VERSION = eval $VERSION;    ## no critic

my $desc     = q{List of quoted literal words};
my $expl     = q{Use 'qw()' instead};

#---------------------------------------------------------------------------

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    
    #Set configuration if defined
    $self->{_min} = defined $args{min_elements} ? $args{min_elements} : 2;
    return $self;
}

sub violates {
    my ( $self, $elem, $doc ) = @_;
    $elem->isa('PPI::Structure::List') || return;

    #Don't worry about subroutine calls
    my $sib = $elem->sprevious_sibling() || return;
    return if $sib->isa('PPI::Token::Word');
    return if $sib->isa('PPI::Token::Symbol');

    #Get the list elements
    my $expr = $elem->schild(0) || return;
    my @children = $expr->schildren();
    @children || return;

    my $count = 0;
    for my $child ( @children ) {
	next if $child->isa('PPI::Token::Operator')  && $child eq $COMMA;
	return if ! _is_literal($child);
	return if $child =~ m{ \s }mx;
	$count++;
    }

    #Were there enough?
    return if $count < $self->{_min};

    #If we get here, then all children were literals
    return Perl::Critic::Violation->new( $desc, $expl, $elem->location() );
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

Perl::Critic::Policy::CodeLayout::ProhibitQuotedWordLists;

=head1 DESCRIPTION

Conway doesn't mention this, but I think C<qw()> is an underutilized
feature of Perl.  Whenever you need to declare a list of one-word
literals, the C<qw()> operator is wonderfully concise and saves you
lots of keystrokes.  And uusing C<qw()> makes it easy to add to the
list in the future.

  @list = ('foo', 'bar', 'baz');  #not ok
  @list = qw(foo bar baz);        #ok

=head1 CONSTRUCTOR

This Policy accepts an additional key-value pair in the constructor.
The key must be 'min_elements' and the value is the minimum number of
elements in the list.  Lists with fewer elements will be overlooked by
this Policy.  The default is 2.  Users of Perl::Critic can configure
this in their F<.perlcriticrc> file like this:

  [CodeLayout::ProhibitQuotedWordLists]
  min_elements = 4

=head1 NOTES

In the PPI parlance, a "list" is almost anything with parens.  I've
tried to make this Policy smart by targeting only "lists" that could
be sensibly expressed with C<qw()>.  However, there may be some edge
cases that I haven't covered.  If you find one, send me a note.

=head1 IMPORTANT CHANGES

This policy was formerly called "RequireQuotedWords" which seemed a
little counterintuitive.  If you get lots of "Cannot load policy
module" errors, then you probably need to change "RequireQuotedWords"
to "ProhibitQuotedWordLists" in your F<.perlcriticrc> file.


=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
