package Perl::Critic::Policy::InputOutput::ProhibitOneArgSelect;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.13';
$VERSION = eval $VERSION; ## no critic

my $desc = q{One-argument 'select' used};
my $expl = [224];

#--------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;
    $elem->isa('PPI::Token::Word') && $elem eq 'select' || return;
    return if is_method_call($elem);
    return if is_hash_key($elem);
    
    if( scalar parse_arg_list($elem) == 1 ) {
	return Perl::Critic::Violation->new($desc, $expl, $elem->location() );
    }
    return; #ok!
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::InputOutput::ProhibitOneArgSelect

=head1 DESCRIPTION

Conway discurages the use of a raw C<select()> when setting
autoflushes.  We'll extend that further by simply prohibiting the
one-arg form of C<select()> entirely; if you really need it you should
know when/where/why that is.  For performing autoflushes, Conway
recommends the use of C<IO::Handle> instead.

  select((select($fh), $|=1)[0]);     # not ok
  select $fh;                         # not ok

   use IO::Handle;
   $fh->autoflush();                   # ok
   *STDOUT->autoflush();               # ok

=head1 SEE ALSO

L<IO::Handle>.

=head1 AUTHOR

Graham TerMarsch <graham@howlingfrog.com>

=head1 COPYRIGHT

Copyright (C) 2005 Graham TerMarsch.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
