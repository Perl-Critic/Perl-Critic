package Perl::Critic::Policy::BuiltinFunctions::ProhibitSleepViaSelect;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.13';
$VERSION = eval $VERSION; ## no critic;

my $desc = q{'select' used to emmulate 'sleep'};
my $expl = [168];

#------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;
    $elem->isa('PPI::Token::Word') && $elem eq 'select' || return;
    return if is_method_call($elem);
    return if is_hash_key($elem);

    if ( 3 == grep {$_->[0] eq 'undef' } parse_arg_list($elem) ){
	return Perl::Critic::Violation->new($desc, $expl, $elem->location() );
    }
    return; #ok!
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::BuiltinFunctions::ProhibitSleepViaSelect

=head1 DESCRIPTION

Conway discourages the use of C<select()> for performing non-integer
sleeps.  Although its documented in L<perlfunc>, its something that
generally requires the reader to RTFM to figure out what C<select()>
is supposed to be doing.  Instead, Conway recommends that you use the
C<Time::HiRes> module when you want to sleep.

  select undef, undef, undef, 0.25;         # not ok

  use Time::HiRes;
  sleep( 0.25 );                            # ok

=head1 SEE ALSO

L<Time::HiRes>.

=head1 AUTHOR

Graham TerMarsch <graham@howlingfrog.com>

=head1 COPYRIGHT

Copyright (C) 2005 Graham TerMarsch.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
