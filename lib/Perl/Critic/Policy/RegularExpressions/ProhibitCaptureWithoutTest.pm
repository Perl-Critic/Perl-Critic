##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::RegularExpressions::ProhibitCaptureWithoutTest;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :data_conversion :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.099_001';

#-----------------------------------------------------------------------------

Readonly::Hash my %CONDITIONAL_OPERATOR => hashify( qw{ && || ? and or xor } );

Readonly::Scalar my $DESC => q{Capture variable used outside conditional};
Readonly::Scalar my $EXPL => [ 253 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return (
        {
            name        => 'exception_source',
            description => 'Names of ways to generate exceptions',
            behavior    => 'string list',
            list_always_present_values => [ qw{ die croak confess } ],
        }
    );
}
sub default_severity     { return $SEVERITY_MEDIUM         }
sub default_themes       { return qw(core pbp maintenance) }
sub applies_to           { return 'PPI::Token::Magic'      }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;
    # TODO named capture variables
    return if $elem !~ m/\A \$[1-9] \z/xms;
    return if _is_in_conditional_expression($elem);
    return if $self->_is_in_conditional_structure($elem);
    return $self->violation( $DESC, $EXPL, $elem );
}

sub _is_in_conditional_expression {
    my $elem = shift;

    # simplistic check: is there a conditional operator between a match and
    # the capture var?
    my $psib = $elem->sprevious_sibling;
    while ($psib) {
        if ($psib->isa('PPI::Token::Operator')) {
            my $op = $psib->content();
            if ( $CONDITIONAL_OPERATOR{ $op } ) {
                $psib = $psib->sprevious_sibling;
                while ($psib) {
                    return 1 if ($psib->isa('PPI::Token::Regexp::Match'));
                    return 1 if ($psib->isa('PPI::Token::Regexp::Substitute'));
                    $psib = $psib->sprevious_sibling;
                }
                return; # false
            }
        }
        $psib = $psib->sprevious_sibling;
    }

    return; # false
}

sub _is_in_conditional_structure {
    my ( $self, $elem ) = @_;

    my $stmt = $elem->statement();
    while ($stmt && $elem->isa('PPI::Statement::Expression')) {
       #return if _is_in_conditional_expression($stmt);
       $stmt = $stmt->statement();
    }
    return if !$stmt;

    # Check if any previous statements in the same scope have regexp matches
    my $psib = $stmt->sprevious_sibling;
    while ($psib) {
        if ( $psib->isa( 'PPI::Node' ) and
            my $match = _find_exposed_match_or_substitute( $psib ) ) {
            # If a regexp match is found, we succeed if a match failure
            # appears to throw an exception, and fail otherwise. RT 36081
            my $oper = $match->snext_sibling() or return;   # fail
            my $oper_content = $oper->content();
            q{or} eq $oper_content
                or q{||} eq $oper_content
                or return;                                  # fail
            my $next = $oper->snext_sibling() or return;    # fail
            return $self->{_exception_source}{ $next->content() };
        }
        $psib = $psib->sprevious_sibling;
    }

    # Check for an enclosing 'if', 'unless', 'endif', or 'else'
    my $parent = $stmt->parent;
    while ($parent) { # never false as long as we're inside a PPI::Document
        if ($parent->isa('PPI::Statement::Compound')) {
            return 1;
        }
        elsif ($parent->isa('PPI::Structure')) {
           return 1 if _is_in_conditional_expression($parent);
           return 1 if $self->_is_in_conditional_structure($parent);
           $parent = $parent->parent;
        }
        else {
           last;
        }
    }

    return; # fail
}

# Given a PPI::Node, find the last regexp match or substitution that is
# in-scope to the node's next sibling.
sub _find_exposed_match_or_substitute { # RT 36081
    my $elem = shift;
FIND_REGEXP_NOT_IN_BLOCK:
    foreach my $regexp ( reverse @{ $elem->find(
            sub {
                return $_[1]->isa( 'PPI::Token::Regexp::Substitute' )
                    || $_[1]->isa( 'PPI::Token::Regexp::Match' );
            }
        ) || [] } ) {
        my $parent = $regexp->parent();
        while ( $parent != $elem ) {
            $parent->isa( 'PPI::Structure::Block' )
                and next FIND_REGEXP_NOT_IN_BLOCK;
            $parent = $parent->parent()
                or next FIND_REGEXP_NOT_IN_BLOCK;
        }
        return $regexp;
    }
    return;
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Critic::Policy::RegularExpressions::ProhibitCaptureWithoutTest - Capture variable used outside conditional.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

If a regexp match fails, then any capture variables (C<$1>, C<$2>,
...) will be undefined.  Therefore it's important to check the return
value of a match before using those variables.

This policy checks that the previous regexp for which the capture variable is
in-scope is either in a conditional or causes an exception if the match fails.

This policy does not check whether that conditional is actually
testing a regexp result, nor does it check whether a regexp actually
has a capture in it.  Those checks are too hard.


=head1 CONFIGURATION

By default, this policy considers C<die>, C<croak>, and C<confess> to
throw exceptions. If you have additional routines that may be used in
lieu of one of these, you can configure them in your perlcriticrc as
follows:

 [RegularExpressions::ProhibitCaptureWithoutTest]
 exception_source = my_exception_generator

=head1 BUGS

Needs to allow this construct:

    for ( ... ) {
        next unless /(....)/;
        if ( $1 ) {
            ....
        }
    }

Right now, Perl::Critic thinks that the C<$1> isn't legal to use
because it's "outside" of the match.  The thing is, we can only get to
the C<if> if the regex matched.

    while ( $str =~ /(expression)/ )

This policy does not recognize named capture variables. Yet.

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2006-2009 Chris Dolan.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
