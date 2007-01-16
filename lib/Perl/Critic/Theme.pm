##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Theme;

use strict;
use warnings;
use Carp qw(confess);
use English qw(-no_match_vars);
use List::MoreUtils qw(any);
use Perl::Critic::Utils;

#-----------------------------------------------------------------------------

our $VERSION = 1.00;

#-----------------------------------------------------------------------------

sub new {

    my ( $class, %args ) = @_;
    my $self = bless {}, $class;
    $self->_init( %args );
    return $self;
}

#-----------------------------------------------------------------------------

sub _init {

    my ($self, %args) = @_;
    my $model = $args{-model} || $EMPTY;

    die qq{Illegal character "$1" in theme model.\n}
        if $model =~ m/ ( [^()\s\w\d\+\-\*\&\|\!] ) /mx;

    $self->{_model} = _cook_model( $model );

    return $self;
}


#-----------------------------------------------------------------------------

sub model {
    my $self = shift;
    return $self->{_model};
}

#-----------------------------------------------------------------------------

sub policy_is_thematic {

    my ($self, %args) = @_;
    my $policy = $args{-policy} || confess 'The -policy argument is required';
    ref $policy || confess 'The -policy must be an object';

    my $model = $self->{_model} || return 1;
    my %themes = hashify( $policy->get_themes() );

    # This bit of magic turns the model into a perl expression that can be
    # eval-ed for truth.  Each theme name in the model is translated to 1 or 0
    # if the $policy belongs in that theme.  For example:
    #
    # 'bugs && (pbp || core)'  ...could become... '1 && (0 || 1)'

    my $as_code = $model; #Making a copy, so $model is preserved
    $as_code =~ s/ ( [\w\d]+ ) /exists $themes{$1} || 0/gemx;
    my $is_thematic = eval $as_code;  ## no critic (ProhibitStringyEval)
    die qq{Syntax error in theme "$model"\n} if $EVAL_ERROR;
    return $is_thematic;
}

#-----------------------------------------------------------------------------

sub _cook_model {
    my ($raw_model) = @_;
    return if not defined $raw_model;

    #Translate logical operators
    $raw_model =~ s{\b not \b}{!}ixmg;     # "not" -> "!"
    $raw_model =~ s{\b and \b}{&&}ixmg;    # "and" -> "&&"
    $raw_model =~ s{\b or  \b}{||}ixmg;    # "or"  -> "||"

    #Translate algebra operators (for backward compatibility)
    $raw_model =~ s{\A [-] }{!}ixmg;     # "-" -> "!"     e.g. difference
    $raw_model =~ s{   [-] }{&& !}ixmg;  # "-" -> "&& !"  e.g. difference
    $raw_model =~ s{   [*] }{&&}ixmg;    # "*" -> "&&"    e.g. intersection
    $raw_model =~ s{   [+] }{||}ixmg;    # "+" -> "||"    e.g. union

    my $cooked_model = $raw_model;  #Is now cooked!
    return $cooked_model;
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Theme - Construct thematic sets of policies

=head1 DESCRIPTION

This is a helper class for evaluating theme expressions into sets of Policy
objects.  There are no user-serviceable parts here.

=head1 METHODS

=over 8

=item C<< new( -model => $model_expression >>

Returns a reference to a new Perl::Critic::Theme object.  C<-model> is a
string expression that defines how to construct the Theme. See L<"THEME
MODELS"> for more information.

Returns a list of Policy objects that comprise this Theme.

=item C<< policy_is_thematic( -policy => $policy ) >>

Given a reference to a L<Perl::Critic::Policy> object, this method returns
true if the Policy belongs in this Theme.

=item C< model() >

Returns the model expression that was used to construct this Theme.  The model
may have been translated into a normalized expression.  See L<"THEME MODELS">
for more information.

=back

=head2 THEME MODELS

A theme model is a simple mathematical expressions, where the operands are the
names of any of the themes associated with the Perl::Critic::Polices.

Theme names can be combined with logical operators to form arbitrarily complex
expressions.  Precedence is the same as normal mathematics, but you can use
parens to enforce precedence as well.  Supported operators are:

   Operator    Altertative    Example
   ----------------------------------------------------------------------------
   &&          and            'pbp && core'
   ||          or             'pbp || (bugs && security)'
   !           not            'pbp && ! (portability || complexity)

See L<Perl::Critic/"CONFIGURATION"> for more information about customizing the
themes for each Policy.


=head1 AUTHOR

Jeffrey Thalhammer  <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006 Jeffrey Thalhammer

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
