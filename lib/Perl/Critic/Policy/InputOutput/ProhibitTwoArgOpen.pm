package Perl::Critic::Policy::InputOutput::ProhibitTwoArgOpen;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.13';
$VERSION = eval $VERSION; ## no critic

my $desc = q{Two-argument 'select' used};
my $expl = [224];

#--------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;
    $elem->isa('PPI::Token::Word') && $elem eq 'open' || return;
    return if is_method_call($elem);
    return if is_hash_key($elem);
    
    if( scalar parse_arg_list($elem) == 2 ) {
	return Perl::Critic::Violation->new($desc, $expl, $elem->location() );
    }
    return; #ok!
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::InputOutput::ProhibitTwoArgOpen

=head1 DESCRIPTION

The three-argument form of C<open> (introduced in Perl 5.6) prevents
subtle bugs that occur when the filename starts with funny characters
like '>' or '<'.  The L<IO::File> module provides a nice OO interface
to filehanldes, which I think is more elegant anyway.

  open( $fh, '>output.txt' );          # not ok
  open( $fh, q{>}, 'output.txt );      # ok

  use IO::File;
  my $fh = IO::File->new( 'output.txt', q{>} ); # even better!

=head1 NOTES

The only time you should use the two-argument form is when you re-open
STDIN, STDOUT, or STDERR.  But for now, this Policy doesn't provide
that loophole.

=head1 SEE ALSO

L<IO::Handle>

L<IO::File>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
