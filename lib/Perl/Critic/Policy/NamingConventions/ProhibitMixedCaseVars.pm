package Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseVars;

use strict;
use warnings;
use List::MoreUtils qw(any);
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.13';
$VERSION = eval $VERSION;    ## no critic

my $mixed_rx = qr/ [A-Z][a-z] | [a-z][A-Z]  /x;
my $desc     = 'Mixed-case variable name(s)';
my $expl     = [44];

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;
    $elem->isa('PPI::Statement::Variable') || return;
    if ( _has_mixed_case_vars($elem) ) {
        return Perl::Critic::Violation->new( $desc, $expl, $elem->location() );
    }
    return;    #ok!
}

sub _has_mixed_case_vars {
    my $elem = shift;
    return any { $_ =~ $mixed_rx } $elem->variables();
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseVars

=head1 DESCRIPTION

Conway's recommended naming convention is to use lower-case words
separated by underscores.  Well-recognized acronyms can be in ALL
CAPS, but must be separated by underscores from other parts of the
name.

  my $foo_bar   #ok
  my $foo_BAR   #ok
  my @FOO_bar   #ok
  my %FOO_BAR   #ok

  my $FooBar   #not ok
  my $FOObar   #not ok
  my @fooBAR   #not ok
  my %fooBar   #not ok

=head1 SEE ALSO

L<Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseSubs>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.
