package Perl::Critic::Policy::ControlStructures::ProhibitUnreachableCode;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.15_03';
$VERSION = eval $VERSION; ## no critic

my %include_stmnt = (
    'die'     => 1,
    'exit'    => 1,
    'croak'   => 1,
    'confess' => 1
);

my %conditionals = (
    'if'     => 1,
    'unless' => 1
);

my %operators = (
    '&&'  => 1,
    '||'  => 1,
    'and' => 1,
    'or'  => 1
);

#---------------------------------------------------------------------------

my $desc = q{Unreachable code};

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGH }
sub applies_to { return 'PPI::Token::Word', 'PPI::Statement' }

#----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;
    return if is_hash_key($elem);
    return if is_method_call($elem);
    return if is_subroutine_name($elem);

  	return if !$elem->isa('PPI::Statement::Break') && !defined $include_stmnt{ $elem };

    # Skip compound statements
    my $stmnt = $elem->statement() || return;
    return if $stmnt->isa('PPI::Statement::Compound');

    my $child_count = $stmnt->schildren() || return;
    my $seen_elem = 0;

    for my $child_idx ( 0 .. $child_count - 1 ) {
        my $child = $stmnt->schild( $child_idx );

        # We have seen the original element so operators are no longer permitted
        if ($child eq $elem) {
            $seen_elem = 1;
            next;
        }

        # Allow flow-altering elements after an operator or if a conditional is present
        return if $child->isa('PPI::Token::Operator') && exists $operators{ $child } && !$seen_elem;
        return if exists $conditionals{ $child };
    }

    # Check statements following original element
    while ( $stmnt = $stmnt->snext_sibling() ) {

        # Subroutines are reachable from anywhere
        if ( !$stmnt->isa('PPI::Statement::Sub') ) {
            # If a label is present, it is possible to reach this code
            return if $stmnt->schildren() && $stmnt->schild( 0 )->isa('PPI::Token::Label');
            # For all other scenarios, this code is unreachable
            my $sev = $self->get_severity();
            return Perl::Critic::Violation->new( $desc, undef, $stmnt, $sev );
        }

    }

    return;
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::ControlStructures::ProhibitUnreachableCode

=head1 DESCRIPTION

This policy prohibits code following a statement which unconditionally alters
the program flow.  This includes calls to C<exit>, C<die>, C<return>, C<next>,
C<last> and C<goto>.  Due to common usage, C<croak> and C<confess> from
L<Carp> are also included.

Code is reachable if any of the following conditions are true:

  * Flow-altering statement has a conditional attached to it
  * Statement is on the right side of an operator C<&&>, C<||>, C<and>, or C<or>.
  * Code is prefixed with a label (can potentially be reached via C<goto>)
  * Code is a subroutine
  *

=head1 EXAMPLES

  # not ok

  exit;
  print "123\n";

  # ok

  exit if !$xyz;
  print "123\n";

  # not ok

  for ( 1 .. 10 ) {
      next;
      print 1;
  }

  # ok

  for ( 1 .. 10 ) {
      next if $_ == 5;
      print 1;
  }

  # not ok

  sub foo {
      my $bar = shift;
      return;
      print 1;
  }

  # ok

  sub foo {
      my $bar = shift;
      return if $bar->baz();
      print 1;
  }


  # not ok

  die;
  print "123\n";

  # ok

  die;
  LABEL: print "123\n";

  # not ok

  croak;
  do_something();

  # ok

  croak;
  sub do_something {}

=head1 SEE ALSO

L<Perl::Critic::Policy::ControlStructures::ProhibitPostfixControls>

=head1 AUTHOR

Peter Guzis <pguzis@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006 Peter Guzis.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

