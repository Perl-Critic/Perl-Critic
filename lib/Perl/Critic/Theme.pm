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
use Set::Scalar qw();

our $VERSION = 0.22;

#-----------------------------------------------------------------------------

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;
    $self->_init( %args );
    return $self;
}

#-----------------------------------------------------------------------------

sub members {
    my $self = shift;
    return @{ $self->{_members} };
}

#-----------------------------------------------------------------------------

sub expression {
    my $self = shift;
    return $self->{_expression};
}

#-----------------------------------------------------------------------------

sub _init {
    my ( $self, %args ) = @_;
    my $policies = $args{-policies} || [];
    my $theme_expression = $args{-theme} || $EMPTY;
    $self->{_expression} = $theme_expression;

    if ( $theme_expression eq $EMPTY ) {
        $self->{_members} = [ map {ref $_} @{ $policies } ];
        return $self;
    }

    my $tmap = _make_theme_map( @{$policies} );
    $self->{_members} = [ _evaluate_expression( $theme_expression, $tmap ) ];
    return $self;
}

#-----------------------------------------------------------------------------

sub _evaluate_expression {
    my ( $expression, $tmap ) = @_;

    my %tmap = %{ $tmap };
    _validate_expression( $expression );
    $expression = _translate_expression( $expression );
    $expression = _interpolate_expression( $expression, 'tmap' );

    no warnings 'uninitialized'; ## no critic (ProhibitNoWarnings)
    my $wanted = eval $expression; ## no critic (ProhibitStringyEval)
    confess qq{Invalid theme expression: "$expression"} if $EVAL_ERROR;
    return if not defined $wanted;

    # If one of the operands in the expression evaluated to undef,
    # then the Set could end up with an undef member.  So we toss
    # it out to avoid 'uninitialized' warnings downstream;
    $wanted->delete(undef);

    # Ick. Set::Scalar::members will return a one-element list under
    # some circumstances.  This is probably a bug.
    my @members = $wanted->members();
    return if @members == 1 and not defined $members[0];
    return @members;
}

#-----------------------------------------------------------------------------

sub _make_theme_map {

    my (@policy_objects) = @_;
    my %theme_map = ();

    for my $policy (@policy_objects){
        my $policy_name = ref $policy || confess q{Not a policy object};
        for my $theme ( $policy->get_themes() ) {
            $theme_map{$theme} ||= Set::Scalar->new();
            $theme_map{$theme}->insert( $policy_name );
        }
    }
    return \%theme_map;
}

#-----------------------------------------------------------------------------

sub _validate_expression {
    my ($expression) = @_;
    return 1 if not defined $expression;
    if ( $expression !~ m/\A    [()\s\w\d\+\-\*]* \z/mx ) {
        $expression  =~ m/   ( [^()\s\w\d\+\-\*] )  /mx;
        confess qq{Illegal character "$1" in theme expression};
    }
    return 1;
}

#-----------------------------------------------------------------------------

sub _translate_expression {
    my ($expression) = @_;
    return if not defined $expression;
    $expression =~ s{\b and \b}{\*}ixmg; # "and" -> "*" e.g. intersection
    $expression =~ s{\b not \b}{\-}ixmg; # "not" -> "-" e.g. difference
    $expression =~ s{\b or  \b}{\+}ixmg; # "or"  -> "+" e.g. union
    return $expression;
}

#-----------------------------------------------------------------------------

sub _interpolate_expression {
    my ($expression, $map_name) = @_;
    $expression =~ s/\b ([\w\d]+) \b/\$$map_name\{"$1"\}/ixmg;
    return $expression;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Theme - Construct thematic sets of policies

=head1 DESCRIPTION

This is a helper class for evalutating theme expressions into sets of Policy
objects.  There are no user-servicable parts here.

=head1 METHODS

=over 8

=item C<< new( -theme => $theme_expression, -policies => \@polcies ) >>

Returns a reference to a new Perl::Critic::Theme object.  C<-theme> is a
string exrpession that defines how to construct the Theme. C<-policies> is a
reference to an array of L<Perl::Critic::Policy> objects, from which the Theme
will be constructed.  See L<"THEME EXPRESSIONS"> for more information.

=item C< members() >

Returns a list of Policy objects that comprise this Theme.

=item C< expression() >

Returns the theme expression that was used to consruct this Theme.  See
L<"THEME EXPRESSIONS"> for more information.

=back

=head2 THEME EXPRESSIONS

Theme expressions are simple mathematical expressions, where the operands are
the names of any of the themes associated with the Perl::Critic::Polices.
Each operand represents the set of all Policies that are declared with or
configured with that paricular theme.

Theme names can be combined with basic mathematical operators into arbitrarily
complex expressions.  Precedence is the same as normal mathematics, but you
can use parens to enforce precedence as well.  Supported operators are:

   Operator       Altertative         Meaning
   ----------------------------------------------------------------------------
   *              and                 Intersection
   -              not                 Difference
   +              or                  Union

See <Perl::Critic/"CONFIGURATION"> for more information about customizing the
themes.


=head1 AUTHOR

Jeffrey Thalhammer  <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006 Jeffrey Thalhammer

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
# ex: set ts=8 sts=4 sw=4 expandtab :
