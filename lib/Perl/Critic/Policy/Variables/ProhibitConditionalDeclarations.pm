#######################################################################
#      $URL$
#     $Date: 2006-01-30 19:49:47 -0800 (Mon, 30 Jan 2006) $
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::Variables::ProhibitConditionalDeclarations;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.20;

#---------------------------------------------------------------------------

my $desc = q{Variable declared in conditional statement};
my $expl = q{Declare variables outside of the condition};

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGHEST          }
sub default_themes    { return qw( danger )               }
sub applies_to       { return 'PPI::Statement::Variable' }

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    if ( $elem->find(\&_is_conditional) ) {
        return $self->violation( $desc, $expl, $elem );
    }
    return;    #ok!
}

my @conditionals = qw( if while foreach for until unless );
my %conditionals = hashify( @conditionals );

sub _is_conditional {
    my (undef, $elem) = @_;

    return if !$conditionals{$elem};
    return if ! $elem->isa('PPI::Token::Word');
    return if is_hash_key($elem);
    return if is_method_call($elem);

    return 1;
}

1;

__END__

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Variables::ProhibitConditionalDeclarations

=head1 DESCRIPTION

Declaring a variable with a postfix conditional is really confusing.
If the conditional is false, its not clear if the variable will
be false, undefined, undeclared, or what.  It's much more straightforward
to make variable declarations separately.

  my $foo = $baz if $bar;          #not ok
  my $foo = $baz unless $bar;      #not ok
  our $foo = $baz for @list;       #not ok
  local $foo = $baz foreach @list; #not ok

=head1 AUTHOR

Jeffrey R. Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006 Chris Dolan.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
