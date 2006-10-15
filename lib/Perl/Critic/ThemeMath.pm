#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::ThemeMath;

use warnings;
use strict;
use Carp;
use English qw(-no_match_vars);
use PPI::Document;
use Set::Scalar;

our $VERSION = 0.21;

#######################################################################
## This package is still under construction, so don't bother critiquing
## When development is complete, you can remove this comment block.
##
## no critic
#######################################################################

sub parse_themes {
    my $pkg      = shift;
    my $request  = shift;
    my @policies = @_;

    # Build a hash of C<< theme_name => [@matching_policies] >>
    my %themes;
    for my $policy (@policies) {
        for my $theme_name ($policy->get_themes()) {
            push @{$themes{$theme_name}}, $policy;
        }
    }
    $themes{all} = [@policies];

    return $pkg->_parse_themes($request, \%themes);
}

sub _parse_themes {
    my $pkg     = shift;
    my $request = shift;
    my $themes  = shift;
    
    # Handle the easy cases first (those that don't have booleans)
    return @{$themes->{all}} if !defined $request;
    return if $request eq q{};
    if ( $request !~ m/\W/xms ) {
        return if !$themes->{$request};
        return @{$themes->{$request}};
    }

    # Filter characters
    if ( $request =~ m/[^\w ()]/ ) {
        croak "Invalid theme request: invalid characters\n";
    }
    # Parse as Perl
    my $parsed = PPI::Document->new(\$request);
    if ( !$parsed ) {
        croak "Invalid theme request: parse error\n";
    }

    # Filter tokens
    for my $token ( $parsed->tokens() ) {
        next if $token->isa('PPI::Token::Word');
        next if $token->isa('PPI::Token::Whitespace');
        next if $token->isa('PPI::Token::Structure') &&
            ($token eq '(' || $token eq ')');
        next if $token->isa('PPI::Token::Operator') && 
            ($token eq 'and' || $token eq 'or' || $token eq 'not');

        croak 'Invalid theme request: illegal token ' . ref($token) . ", '$token'\n";
    }

    #use PPI::Dumper;
    #my $dumper = PPI::Dumper->new($parsed);
    #$dumper->print();

    # Evaluate the booleans
    my $set = eval { $pkg->_evaluate_node($parsed, $themes); };
    if ( $EVAL_ERROR ) {
        croak $EVAL_ERROR;
    }
    return $set->size ? $set->elements : ();
}

sub _evaluate_node {
    my $pkg = shift;
    my $node = shift;
    my $themes = shift;

    my $elem = $node->schild(0);
    if ( !$elem ) {
        return Set::Scalar->new();
    }

    my $set;
    ($elem, $set) = $pkg->_evaluate_or_operand($elem, $themes);

    while ( $elem = $elem->snext_sibling ) {
        if ( $elem->isa('PPI::Token::Operator') && $elem eq 'or' ) {
            $elem = $elem->snext_sibling;
            if (!$elem) {
                croak "Invalid theme request: expected something after 'or'\n";
            }
            my $set2;
            ($elem, $set2) = $pkg->_evaluate_or_operand($elem, $themes);
            $set = $set->union($set2);
        }
    }

    return $set;
}

sub _evaluate_or_operand {
    my $pkg = shift;
    my $elem = shift;
    my $themes = shift;

    my $set;
    ($elem, $set) = $pkg->_evaluate_term($elem, $themes);

    while ( 1 ) {
        my $next_elem = $elem->snext_sibling;
        last if !$next_elem;
        last if !$next_elem->isa('PPI::Token::Operator');
        last if $next_elem ne 'and';

        $elem = $next_elem->snext_sibling;
        if ( !$elem ) {
            croak "Invalid theme request: expected something after 'and'\n";
        }
        my $set2;
        ($elem, $set2) = $pkg->_evaluate_term($elem, $themes);
        $set = $set->intersection($set2);
    }
    return ($elem, $set);
}   

sub _evaluate_term {
    my $pkg = shift;
    my $elem = shift;
    my $themes = shift;

    if ( $elem->isa('PPI::Token::Word') ) {
        my $themes = $themes->{$elem};
        if ( !$themes ) {
            croak "Invalid theme request: unknown theme '$elem'\n";
        }
        my $set = Set::Scalar->new(@{$themes});
        return ($elem, $set);
    }
    elsif ( $elem->isa('PPI::Token::Operator') && $elem eq 'not' ) {
        $elem = $elem->snext_sibling;
        if ( !$elem ) {
            croak "Invalid theme request: expected something after 'not'\n";
        }
        my $set;
        ($elem, $set) = $pkg->_evaluate_term($elem, $themes);
        $set = Set::Scalar->new(@{$themes->{all}})->difference($set);
        return ($elem, $set);
    }
    elsif ( $elem->isa('PPI::Structure::List') ||
            $elem->isa('PPI::Statement') ) {
        return ($elem, $pkg->_evaluate_node($elem, $themes));
    }

    croak "Invalid theme request: expected a theme, got ".ref($elem).", '$elem'\n";
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::ThemeMath - Evaluate theme boolean expressions

=head1 DESCRIPTION

=head1 METHODS

=over 8

=item @policies = Perl::Critic::ThemeMath->parse_themes($request, @all_policies)

Given a string theme request and a list of all policy module
instances, parse the boolean request and apply the boolean math to the
policy list.  This returns a subset of the total list of policies.

Examples of requests and the lists they return:

  undef     => @all_policies
  ''        => ()
  'all'     => @all_policies
  'pbp'     => grep {any {$_ eq 'pbp'} $_->get_themes} @all_policies
  'not pbp' => grep {!any {$_ eq 'pbp'} $_->get_themes} @all_policies
  'pbp and risky' =>
     grep { 2 == grep {$_ eq 'pbp' || $_ eq 'risky' } $_->get_themes
          } @all_policies

=back

=head1 AUTHOR

Chris Dolan <cpan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006 Chris Dolan

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
