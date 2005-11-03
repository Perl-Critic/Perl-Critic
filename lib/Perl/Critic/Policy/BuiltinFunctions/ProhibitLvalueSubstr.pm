package Perl::Critic::Policy::BuiltinFunctions::ProhibitLvalueSubstr;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.13';
$VERSION = eval $VERSION; ## no critic;

my $desc = q{Lvalue form of 'substr' used};
my $expl = [165];

#----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;
    $elem->isa('PPI::Token::Word') && $elem eq 'substr' || return;
    return if is_method_call($elem);
    return if is_hash_key($elem);

    my $sib = $elem;
    while ($sib = $sib->snext_sibling()) {
	next if ! ( $sib->isa( 'PPI::Token::Operator') && $sib eq q{=} );
	return Perl::Critic::Violation->new($desc, $expl, $sib->location() );
    }
    return; #ok!
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::BuiltinFunctions::ProhibitLValueSubstr

=head1 DESCRIPTION

Conway discourages the use of C<substr()> as an lvalue, instead
recommending that the 4-arg version of C<substr()> be used instead.

  substr($something, 1, 2) = $newvalue;     # not ok
  substr($something, 1, 2, $newvalue);      # ok

=head1 AUTHOR

Graham TerMarsch <graham@howlingfrog.com>

=head1 COPYRIGHT

Copyright (C) 2005 Graham TerMarsch.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
