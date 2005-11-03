package Perl::Critic::Policy::RegularExpressions::RequireExtendedFormatting;

use strict;
use warnings;
use Perl::Critic::Violation;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = '0.13';
$VERSION = eval $VERSION;    ## no critic

my $desc = q{Regular expression without '/x' flag};
my $expl = [ 236 ];

#----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;
    $elem->isa('PPI::Token::Regexp') || return;

    #Note: as of PPI 1.103, 'modifiers' is not part of the published
    #API.  I'm cheating by accessing it here directly.

    if ( ! defined $elem->{modifiers}->{x} ) {
	return Perl::Critic::Violation->new( $desc, $expl, $elem->location() );
    }
    return; #ok!;
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::RegularExpressions::RequireExtendedFormatting

=head1 DESCRIPTION

Extended regular expression formatting allows you mix whitespace and
comments into the pattern, thus making them much more readable.

    # Match a single-quoted string efficiently...

    m{'[^\\']*(?:\\.[^\\']*)*'};  #Huh?

    #Same thing with extended format...

    m{ '           #an opening single quote
       [^\\']      #any non-special chars (i.e. not backslash or single quote)
       (?:         #then all of...
          \\ .     #   any explicitly backslashed char
          [^\\']*  #   followed by an non-special chars
       )*          #...repeated zero or more times
       '           # a closing single quote
     }x; 

=head1 NOTES

For common regular expessions like e-mail addresses, phone numbers,
dates, etc., have a look at the L<Regex::Common> module.  Also, be
cautions about slapping modifier flags onto existing regular
expressions, as they can drastically alter their meaning.  See
L<http://www.perlmonks.org/?node_id=484238> for an interesting
discussion on the effects of blindly modifying regular expression
flags.

=head1 AUTHOR

Jeffrey Ryan Thalhammer  <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005 Jeffrey Ryan Thalhammer. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
