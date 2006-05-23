package Perl::Critic::Policy::ControlStructures::ProhibitUnreachableCode;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.17';
$VERSION = eval $VERSION; ## no critic

my %terminals = (
    'die'     => 1,
    'exit'    => 1,
    'croak'   => 1,
    'confess' => 1,
);

my %conditionals = (
    'if'      => 1,
    'unless'  => 1,
    'foreach' => 1,
    'while'   => 1,
    'for'     => 1,
);

my %operators = (
    q{&&}  => 1,
    q{||}  => 1,
    q{and} => 1,
    q{or}  => 1,
    q{?}   => 1,
);

#---------------------------------------------------------------------------

my $desc = q{Unreachable code};
my $expl = q{Consider removing it};

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGH }
sub applies_to { return 'PPI::Token::Word' }

#----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;
    return if is_hash_key($elem);
    return if is_method_call($elem);
    return if is_subroutine_name($elem);

    my $stmnt = $elem->statement() || return;
    return if ( !exists $terminals{$elem} ) &&
        ( !$stmnt->isa('PPI::Statement::Break') );

    # Scan the enclosing statement for conditional keywords or logical
    # operators.  If any are found, then this the folowing statements
    # could _potentially_ be executed, so this policy is satisfied.

    # NOTE: When the first operand in an boolean expression is
    # C<croak> or C<die>, etc., the second operand is technically
    # unreachable.  But this policy doesn't catch that situation.

    for my $child ( $stmnt->schildren() ) {
        return if $child->isa('PPI::Token::Operator') && exists $operators{$child};
        return if $child->isa('PPI::Token::Word') && exists $conditionals{$child};
    }

    # If we get here, then the statement contained an unconditional
    # die or exit or return.  Then all the subsequent sibling
    # statements are unreachable, except for those that have labels,
    # which could be reached from anywhere using C<goto>.  Subroutine
    # declarations are also exempt for the same reason.

    my @viols = ();
    while ( $stmnt = $stmnt->snext_sibling() ) {
        last if $stmnt->schildren() && $stmnt->schild( 0 )->isa('PPI::Token::Label');
        next if $stmnt->isa('PPI::Statement::Sub');

        my $sev = $self->get_severity();
        push @viols, Perl::Critic::Violation->new( $desc, $expl, $stmnt, $sev );
    }

    return @viols;
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

