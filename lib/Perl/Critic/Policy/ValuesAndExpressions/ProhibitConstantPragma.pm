package Perl::Critic::Policy::ValuesAndExpressions::ProhibitConstantPragma;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.13';
$VERSION = eval $VERSION;    ## no critic

my $desc = q{Pragma 'constant' used};
my $expl = [55];

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;
    $elem->isa('PPI::Statement::Include') || return;
    if ( $elem->type() eq 'use' && $elem->pragma() eq 'constant' ) {
        return Perl::Critic::Violation->new( $desc, $expl, $elem->location() );
    }
    return;    #ok!
}

1;

__END__

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitConstantPragma

=head1 DESCRIPTION

Named constants are a good thing.  But don't use the C<constant>
pragma because barewords don't interpolate.  Instead use the
L<Readonly> module.

  use constant FOOBAR => 42;  #not ok

  use Readonly;
  Readonly  my $FOOBAR => 42;  #ok 

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.
