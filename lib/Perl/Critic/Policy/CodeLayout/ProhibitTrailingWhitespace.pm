##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::CodeLayout::ProhibitTrailingWhitespace;

use strict;
use warnings;

use English qw(-no_match_vars);

use charnames qw{};

use PPI::Token::Whitespace;
use Perl::Critic::Utils qw{ :characters :severities };

use base 'Perl::Critic::Policy';

our $VERSION = 1.04;

#-----------------------------------------------------------------------------

my $description = q{Don't use whitespace at the end of lines};

## no critic (RequireInterpolationOfMetachars)
my %c_style_escapes =
    (
        ord "\t" => q{\t},
        ord "\n" => q{\n},
        ord "\r" => q{\r},
        ord "\f" => q{\f},
        ord "\b" => q{\b},
        ord "\a" => q{\a},
        ord "\e" => q{\e},
    );
## use critic

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                       }
sub default_severity     { return $SEVERITY_LOWEST         }
sub default_themes       { return qw( core maintenance )   }
sub applies_to           { return 'PPI::Token::Whitespace' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $token, undef ) = @_;

    my $content = $token->content();
    return if length($content) < 2;

    my @characters = split $EMPTY, $content;

    return if qq{\n} ne pop @characters;

    my $explanation = q{Found "};
    $explanation .= join $EMPTY, map { _escape($_) } @characters;
    $explanation .= q{" at the end of the line};

    return $self->violation( $description, $explanation, $token );
}

sub _escape {
    my $character = shift;
    my $ordinal = ord $character;

    if (my $c_escape = $c_style_escapes{$ordinal}) {
        return $c_escape;
    }

    return q/\N{/ . charnames::viacode($ordinal) . q/}/; ## no critic (RequireInterpolationOfMetachars)
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=for stopwords

=head1 NAME

Perl::Critic::Policy::CodeLayout::ProhibitTrailingWhitespace

=head1 DESCRIPTION

Anything that is not readily visually detectable is a bad thing in
general, and more specifically, as different people edit the same
code, their editors may automatically strip out trailing whitespace,
causing spurious differences between different versions of the same
file (i.e. code in a source control system).

=head1 AUTHOR

Elliot Shank C<< <perl@galumph.com> >>

=head1 COPYRIGHT

Copyright (c) 2007 Elliot Shank.  All rights reserved.

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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
