package Perl::Critic::Policy::ValuesAndExpressions::ProhibitEmptyQuotes;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EMPTY_RX => qr{\A ["'] \s* ['"] \z}xms;
Readonly::Scalar my $DESC     => q<Quotes used with a string containing no non-whitespace characters>;
Readonly::Scalar my $EXPL     => [ 53 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                    }
sub default_severity     { return $SEVERITY_LOW         }
sub default_themes       { return qw(core pbp cosmetic) }
sub applies_to           { return 'PPI::Token::Quote'   }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    if ( $elem =~ $EMPTY_RX ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }
    return;    #ok!
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitEmptyQuotes - Write C<q{}> instead of C<''>.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Don't use quotes for an empty string or any string that is pure
whitespace.  Instead, use C<q{}> to improve legibility.  Better still,
created named values like this.  Use the C<x> operator to repeat
characters.

    $message = '';      #not ok
    $message = "";      #not ok
    $message = "     "; #not ok

    $message = q{};     #better
    $message = q{     } #better

    $EMPTY = q{};
    $message = $EMPTY;      #best

    $SPACE = q{ };
    $message = $SPACE x 5;  #best


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 SEE ALSO

L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitNoisyStrings|Perl::Critic::Policy::ValuesAndExpressions::ProhibitNoisyStrings>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>

=head1 COPYRIGHT

Copyright (c) 2005-2011 Imaginative Software Systems.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
