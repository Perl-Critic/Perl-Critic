#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::ThemeManager;

use strict;
use warnings;
use Carp qw(confess);
use English qw(-no_match_vars);
use List::MoreUtils qw(any);
use Set::Scalar;

our $VERSION = 0.21;

#-----------------------------------------------------------------------------

sub new {
    my ($class, $request, @policy_objects) = @_;
    my $self = bless {}, $class;
    $self->_init( $request, @policy_objects );
    return $self;
}

#-----------------------------------------------------------------------------

sub _init {
    my ($self, $request, @policy_objects) = @_;
    my $tmap = _make_theme_map( @policy_objects );
    $self->{_policies} = _evaluate_request($request, $tmap);
    return $self;
}

#-----------------------------------------------------------------------------

sub _evaluate_request {
    my ($request, $tmap) = @_;
    my %tmap = %{ $tmap };
    $request = _validate_request( $request );
    $request = _translate_request( $request );
    $request = _interpolate_request( $request, 'tmap' );
    return if not length $request;

    my $wanted_set = eval $request;  ## no critic ProhibitStringyEval;
    confess  q{Something went wrong} if ref $wanted_set ne 'Set::Scalar';
    confess qq{Invalid theme expression: $EVAL_ERROR} if $EVAL_ERROR;
    return $wanted_set->members();
}

#-----------------------------------------------------------------------------

sub _make_theme_map {

    my @policy_objects = @_;
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

sub _validate_request {
    my ($request) = @_;
    return if not length $request;
    if ( $request !~ m/\A    [()\s\w\d\+\-\*]+ \z/mx ) {
        $request  =~ m/   ( [^()\s\w\d\+\-\*] )  /mx;
        confess qq{Illegal character "$1" in theme expression};
    }
    return 1;
}

#-----------------------------------------------------------------------------

sub _translate_request {
    my ($request) = @_;
    $request =~ s{\b and \b}{\*}ixmg; # "and" -> "*" e.g. intersection
    $request =~ s{\b not \b}{\-}ixmg; # "not" -> "-" e.g. difference
    $request =~ s{\b or  \b}{\+}ixmg; # "or"  -> "+" e.g. union
    return $request;
}

#-----------------------------------------------------------------------------

sub _interpolate_request {
    my ($request, $map_name) = @_;
    $request =~ s/\b ([\w\d]+) \b/\$$map_name\{"$1"\}/ixmg;
    return $request;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::ThemeManager - Evaluate theme boolean expressions

=head1 DESCRIPTION

=head1 METHODS

=over 8

=item C< new( @polcies ) >

=item C< evaluate( $expression ) >

=back

=head1 AUTHOR

Jeffrey Thalhammer  <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006 Jeffrey Thalhammer

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

