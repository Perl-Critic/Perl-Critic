package Perl::Critic::Policy::ControlStructures::ProhibitUnreachableCode;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :data_conversion :classification };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

Readonly::Array my @TERMINALS => qw( die exit croak confess );
Readonly::Hash  my %TERMINALS => hashify( @TERMINALS );

Readonly::Array my @CONDITIONALS => qw( if unless foreach while until for );
Readonly::Hash  my %CONDITIONALS => hashify( @CONDITIONALS );

Readonly::Array my @OPERATORS => qw( && || // and or err ? );
Readonly::Hash  my %OPERATORS => hashify( @OPERATORS );

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Unreachable code};
Readonly::Scalar my $EXPL => q{Consider removing it};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                 }
sub default_severity     { return $SEVERITY_HIGH     }
sub default_themes       { return qw( core bugs certrec )    }
sub applies_to           { return 'PPI::Token::Word' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    my $statement = $elem->statement();
    return if not $statement;

    # We check to see if this is an interesting token before calling
    # is_function_call().  This weeds out most candidate tokens and
    # prevents us from having to make an expensive function call.

    return if ( !exists $TERMINALS{$elem} ) &&
        ( !$statement->isa('PPI::Statement::Break') );

    return if not is_function_call($elem);

    # Scan the enclosing statement for conditional keywords or logical
    # operators.  If any are found, then this the following statements
    # could _potentially_ be executed, so this policy is satisfied.

    # NOTE: When the first operand in an boolean expression is
    # C<croak> or C<die>, etc., the second operand is technically
    # unreachable.  But this policy doesn't catch that situation.

    for my $child ( $statement->schildren() ) {
        return if $child->isa('PPI::Token::Operator') && exists $OPERATORS{$child};
        return if $child->isa('PPI::Token::Word') && exists $CONDITIONALS{$child};
    }

    return $self->_gather_violations($statement);
}

sub _gather_violations {
    my ($self, $statement) = @_;

    # If we get here, then the statement contained an unconditional
    # die or exit or return.  Then all the subsequent sibling
    # statements are unreachable, except for those that have labels,
    # which could be reached from anywhere using C<goto>.  Subroutine
    # declarations are also exempt for the same reason.  "use" and
    # "our" statements are exempt because they happen at compile time.

    my @violations = ();
    while ( $statement = $statement->snext_sibling() ) {
        my @children = $statement->schildren();
        last if @children && $children[0]->isa('PPI::Token::Label');
        next if $statement->isa('PPI::Statement::Sub');
        next if $statement->isa('PPI::Statement::End');
        next if $statement->isa('PPI::Statement::Data');
        next if $statement->isa('PPI::Statement::Package');

        next if $statement->isa('PPI::Statement::Include') &&
            $statement->type() ne 'require';

        next if $statement->isa('PPI::Statement::Variable') &&
            $statement->type() eq 'our';

        push @violations, $self->violation( $DESC, $EXPL, $statement );
    }

    return @violations;
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::ControlStructures::ProhibitUnreachableCode - Don't write code after an unconditional C<die, exit, or next>.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

This policy prohibits code following a statement which unconditionally
alters the program flow.  This includes calls to C<exit>, C<die>,
C<return>, C<next>, C<last> and C<goto>.  Due to common usage,
C<croak> and C<confess> from L<Carp|Carp> are also included.

Code is reachable if any of the following conditions are true:

=over

=item * Flow-altering statement has a conditional attached to it

=item * Statement is on the right side of an operator C<&&>, C<||>, C<//>, C<and>, C<or>, or C<err>.

=item * Code is prefixed with a label (can potentially be reached via C<goto>)

=item * Code is a subroutine

=back

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


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 SEE ALSO

L<Perl::Critic::Policy::ControlStructures::ProhibitPostfixControls|Perl::Critic::Policy::ControlStructures::ProhibitPostfixControls>

=head1 AUTHOR

Peter Guzis <pguzis@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006-2011 Peter Guzis.  All rights reserved.

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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
