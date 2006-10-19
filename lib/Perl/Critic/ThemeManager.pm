##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
##############################################################################

package Perl::Critic::ThemeManager;

use strict;
use warnings;
use Carp qw(confess);
use English qw(-no_match_vars);
use List::MoreUtils qw(any);
use Perl::Critic::Utils;
use Set::Scalar qw();

our $VERSION = 0.21;

#-----------------------------------------------------------------------------

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;
    $self->_init( %args );
    return $self;
}

#-----------------------------------------------------------------------------

sub thematic_policy_names {
    my $self = shift;
    return @{ $self->{_policy_names} };
}

#-----------------------------------------------------------------------------

sub _init {
    my ( $self, %args ) = @_;
    my $theme_rule = $args{-theme};
    my $policies   = $args{-policies} || [];

    if ( !defined $theme_rule || $theme_rule eq $EMPTY ) {
        $self->{_policy_names} = [ map {ref $_} @{ $policies } ];
        return $self;
    }

    my $tmap = _make_theme_map( @{$policies} );
    $self->{_policy_names} = [ _evaluate_rule( $theme_rule, $tmap ) ];
    return $self;
}

#-----------------------------------------------------------------------------

sub _evaluate_rule {
    my ( $rule, $tmap ) = @_;

    my %tmap = %{ $tmap };
    _validate_rule( $rule );
    $rule = _translate_rule( $rule );
    $rule = _interpolate_rule( $rule, 'tmap' );

    no warnings 'uninitialized'; ## no critic (ProhibitNoWarnings)
    my $wanted = eval $rule || return; ## no critic (ProhibitStringyEval)
    confess qq{Invalid theme rule: $EVAL_ERROR} if $EVAL_ERROR;
    return $wanted->members();
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

sub _validate_rule {
    my ($rule) = @_;
    return 1 if not defined $rule;
    if ( $rule !~ m/\A    [()\s\w\d\+\-\*]* \z/mx ) {
        $rule  =~ m/   ( [^()\s\w\d\+\-\*] )  /mx;
        confess qq{Illegal character "$1" in theme rule};
    }
    return 1;
}

#-----------------------------------------------------------------------------

sub _translate_rule {
    my ($rule) = @_;
    return if not defined $rule;
    $rule =~ s{\b and \b}{\*}ixmg; # "and" -> "*" e.g. intersection
    $rule =~ s{\b not \b}{\-}ixmg; # "not" -> "-" e.g. difference
    $rule =~ s{\b or  \b}{\+}ixmg; # "or"  -> "+" e.g. union
    return $rule;
}

#-----------------------------------------------------------------------------

sub _interpolate_rule {
    my ($rule, $map_name) = @_;
    $rule =~ s/\b ([\w\d]+) \b/\$$map_name\{"$1"\}/ixmg;
    return $rule;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::ThemeManager - Evaluate theme rules

=head1 DESCRIPTION

=head1 METHODS

=over 8

=item C< new( -theme => $theme_rule, -policies => @polcies ) >

=item C< thematic_policy_names() >

=back

=head1 AUTHOR

Jeffrey Thalhammer  <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006 Jeffrey Thalhammer

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

