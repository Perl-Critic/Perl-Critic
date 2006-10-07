#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::ValuesAndExpressions::ProhibitMixedBooleanOperators;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.20;

#---------------------------------------------------------------------------

my @low_booleans  = qw( not or and );
my %low_booleans  = hashify( @low_booleans );

my @high_booleans = qw( ! || && );
my %high_booleans = hashify( @high_booleans );

my @exempt_types = qw(
    PPI::Statement::Block
    PPI::Statement::Scheduled
    PPI::Statement::Package
    PPI::Statement::Include
    PPI::Statement::Sub
    PPI::Statement::Variable
    PPI::Statement::Compound
    PPI::Statement::Data
    PPI::Statement::End
);

#---------------------------------------------------------------------------

my $desc = q{Mixed high and low-precedence booleans};
my $expl = [ 70 ];

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGH   }
sub default_themes    { return qw( risky pbp )  }
sub applies_to       { return 'PPI::Statement' }

#---------------------------------------------------------------------------

sub violates {

    my ( $self, $elem, undef ) = @_;

    # PPI::Statement is the ancestor of several types of PPI elements.
    # But for this policy, we only want the ones that generally
    # represent a single statement or expression.  There might be
    # better ways to do this, such as scanning for a semi-colon or
    # some other marker.

    for my $type (@exempt_types) {
        return if $elem->isa($type);
    }


    if (    $elem->find_first(\&_low_boolean)
         && $elem->find_first(\&_high_boolean) ) {

        return $self->violation( $desc, $expl, $elem );
    }
    return;    #ok!
}


sub _low_boolean {
    my (undef, $elem) = @_;
    $elem->isa('PPI::Token::Operator') || return 0;
    return exists $low_booleans{$elem};
}

sub _high_boolean {
    my (undef, $elem) = @_;
    $elem->isa('PPI::Token::Operator') || return 0;
    return exists $high_booleans{$elem};
}

1;

__END__

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitMixedBooleanOperators

=head1 DESCRIPTION

Conway advises against combining the low-precedence booleans ( C<and
or not> ) with the high-precedence boolean operators ( C<&& || !> )
in the same expression.  Unless you fully understand the differences
between the high and low-precedence operators, it is easy to
misinterpret expressions that use both.  And even if you do understand
them, it is not always clear if the author actually intended it.

  next if not $foo || $bar;  #not ok
  next if !$foo || $bar;     #ok
  next if !( $foo || $bar ); #ok

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
