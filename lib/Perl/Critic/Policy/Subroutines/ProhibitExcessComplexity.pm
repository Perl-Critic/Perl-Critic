##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::Subroutines::ProhibitExcessComplexity;

use strict;
use warnings;

use Perl::Critic::Utils qw{ :severities :data_conversion :classification };
use Perl::Critic::Utils::McCabe qw{ &calculate_mccabe_of_sub };

use base 'Perl::Critic::Policy';

our $VERSION = 1.052;

#-----------------------------------------------------------------------------

my $expl = q{Consider refactoring};

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'max_mccabe',
            description     => 'The maximum complexity score allowed.',
            default_string  => '20',
            behavior        => 'integer',
            integer_minimum => 1,
        },
    );
}

sub default_severity  { return $SEVERITY_MEDIUM                }
sub default_themes    { return qw(core complexity maintenance) }
sub applies_to        { return 'PPI::Statement::Sub'           }

#-----------------------------------------------------------------------------

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;
    $self->{_max_mccabe} = $args{max_mccabe} || 20;
    return $self;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    my $score = calculate_mccabe_of_sub( $elem );

    # Is it too complex?
    return if $score <= $self->{_max_mccabe};

    my $desc = qq{Subroutine with high complexity score ($score)};
    return $self->violation( $desc, $expl, $elem );
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords McCabe

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

=head1 CONFIGURATION

The maximum acceptable McCabe can be set with the C<max_mccabe>
configuration item.  Any subroutine with a McCabe score higher than
this number will generate a policy violation.  The default is 20.  An
example section for a F<.perlcriticrc>:

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

Copyright (c) 2005-2007 Jeffrey Ryan Thalhammer.  All rights reserved.

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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
