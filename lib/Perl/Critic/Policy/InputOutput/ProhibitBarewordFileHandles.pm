package Perl::Critic::Policy::InputOutput::ProhibitBarewordFileHandles;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.13';
$VERSION = eval $VERSION; ## no critic

my $desc = q{Bareword file handle opened};
my $expl = [ 224 ];

#--------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;
    $elem->isa('PPI::Token::Word') && $elem eq 'open' || return;
    return if is_method_call($elem);
    return if is_hash_key($elem);
    
    my $first = ( parse_arg_list($elem) )[0] || return;
    $first = $first->[0] || return; #Ick!

    if( $first->isa('PPI::Token::Word') && !($first eq 'my') ) {
	return Perl::Critic::Violation->new($desc, $expl, $elem->location() );
    }
    return; #ok!
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::InputOutput::ProhibitBarewordFileHandles

=head1 DESCRIPTION

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
