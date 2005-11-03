package Perl::Critic::Policy::Subroutines::ProhibitBuiltinHomonyms;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use List::MoreUtils qw(any);
use base 'Perl::Critic::Policy';

our $VERSION = '0.13';
$VERSION = eval $VERSION;    ## no critic

my %allow = ( import => 1 );
my $desc  = q{Subroutine name is a homonym for builtin function};
my $expl  = [177];

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;
    $elem->isa('PPI::Statement::Sub') || return;
    return if exists $allow{ $elem->name() };
    if ( any { $elem->name() eq $_ } @BUILTINS ) {
        return Perl::Critic::Violation->new( $desc, $expl, $elem->location() );
    }
    return;    #ok!
}

1;

__END__

=head1 NAME

Perl::Critic::Policy::Subroutines::ProhibitBuiltinHomonyms

=head1 DESCRIPTION

Common sense dictates that you shouldn't declare subroutines with the
same name as one of Perl's built-in functions. See C<perldoc perlfunc>
for a list of built-ins.

  sub open {}  #not ok
  sub exit {}  #not ok
  sub print {} #not ok

  #You get the idea...

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.
