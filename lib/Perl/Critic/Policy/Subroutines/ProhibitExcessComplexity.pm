#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::Subroutines::ProhibitExcessComplexity;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.19;

#---------------------------------------------------------------------------

my $expl = q{Consider refactoring};

my @logic_ops = qw( && || ||= &&= or and xor ? <<= >>= );
my %logic_ops = hashify( @logic_ops );

my @logic_keywords = qw( if else elsif unless until while );
my %logic_keywords = hashify( @logic_keywords );

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_MEDIUM }
sub applies_to { return 'PPI::Statement::Sub' }

#---------------------------------------------------------------------------

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;
    $self->{_max_mccabe} = $args{max_mccabe} || 20;
    return $self;
}

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    my $count = 1;

    # Count up all the logic keywords, weed out hash keys
    my $keywords_ref = $elem->find('PPI::Token::Word');
    if ( $keywords_ref ) { # should always be true due to "sub" keyword, I think
       my @filtered = grep { ! is_hash_key($_) } @{ $keywords_ref };
       $count += grep { exists $logic_keywords{$_} } @filtered;
    }

    # Count up all the logic operators
    my $operators_ref = $elem->find('PPI::Token::Operator');
    if ( $operators_ref ) {
       $count += grep { exists $logic_ops{$_} }  @{ $operators_ref };
    }

    if ( $count > $self->{_max_mccabe} ) {
        my $desc = qq{Subroutine with high complexity score ($count)};
        return $self->violation( $desc, $expl, $elem );
    }
    return; #ok!
}

1;

__END__

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::ProhibitExcessComplexity

=head1 DESCRIPTION

All else being equal, complicated code is more error-prone and more
expensive to maintain than simpler code.  The first step towards
managing complexity is to establish formal complexity metrics.  One
such metric is the McCabe score, which describes the number of
possible paths through a subroutine.  This Policy approximates the
McCabe score by summing the number of conditional statements and
operators within a subroutine.  Research has shown that a McCabe score
higher than 20 is a sign of high-risk, potentially untestable code.
See L<http://www.sei.cmu.edu/str/descriptions/cyclomatic_body.html>
for some discussion about the McCabe number and other complexity
metrics.

The usual prescription for reducing complexity is to refactor code
into smaller subroutines.  Mark Dominus book "Higher Order Perl" also
describes callbacks, recursion, memoization, iterators, and other
techniques that help create simple and extensible Perl code.

=head1 CONSTRUCTOR

This Policy accepts an additional key-value pair in the C<new> method.
The key is 'max_mccabe' and the value is the maximum acceptable McCabe
score.  Any subroutine with a McCabe score higher than this number
will generate a policy violation.  The default is 20.  Users of the
Perl::Critic engine can configure this in their F<.perlcriticrc> like
this:

  [Subroutines::ProhibitExcessComplexity]
  max_mccabe = 30

=head1 NOTES


  "Everything should be made as simple as possible, but no simpler."

                                                  -- Albert Einstein


Complexity is subjective, but formal complexity metrics are still
incredibly valuable.  Every problem has an inherent level of
complexity, so it is not necessarily optimal to minimize the McCabe
number.  So don't get offended if your code triggers this Policy.
Just consider if there B<might> be a simpler way to get the job done.


=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
