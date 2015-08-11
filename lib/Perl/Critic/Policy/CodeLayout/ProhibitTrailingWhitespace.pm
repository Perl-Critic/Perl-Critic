package Perl::Critic::Policy::CodeLayout::ProhibitTrailingWhitespace;

use 5.006001;
use strict;
use warnings;
use English qw(-no_match_vars);
use Readonly;

use charnames qw{};

use PPI::Token::Whitespace;
use Perl::Critic::Utils qw{ :characters :severities };

use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL => q{Don't use whitespace at the end of lines};

## no critic (RequireInterpolationOfMetachars)
Readonly::Hash my %C_STYLE_ESCAPES =>
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

sub supported_parameters { return qw{ }                    }
sub default_severity     { return $SEVERITY_LOWEST         }
sub default_themes       { return qw( core maintenance )   }
sub applies_to           { return 'PPI::Token::Whitespace' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $token, undef ) = @_;

    if ( $token->content() =~ m< ( (?! \n) \s )+ \n >xms ) {
        my $extra_whitespace = $1;

        my $description = q{Found "};
        $description .=
            join
                $EMPTY,
                map { _escape($_) } split $EMPTY, $extra_whitespace;
        $description .= q{" at the end of the line};

        return $self->violation( $description, $EXPL, $token );
    }

    return;
}

sub _escape {
    my $character = shift;
    my $ordinal = ord $character;

    if (my $c_escape = $C_STYLE_ESCAPES{$ordinal}) {
        return $c_escape;
    }


    # Apparently, the charnames.pm that ships with older perls does not
    # support the C<viacode> function, and newer versions of the module are
    # not distributed separately from perl itself So if the C<viacode> method
    # is not supported, then just substitute something.


    ## no critic (RequireInterpolationOfMetachars)
    if ( charnames->can( 'viacode' ) ) {
        return q/\N{/ . charnames::viacode($ordinal) . q/}/;
    }
    else {
        return '\N{WHITESPACE CHAR}';
    }
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=for stopwords

=head1 NAME

Perl::Critic::Policy::CodeLayout::ProhibitTrailingWhitespace - Don't use whitespace at the end of lines.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Anything that is not readily visually detectable is a bad thing in
general, and more specifically, as different people edit the same
code, their editors may automatically strip out trailing whitespace,
causing spurious differences between different versions of the same
file (i.e. code in a source control system).


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 AUTHOR

Elliot Shank C<< <perl@galumph.com> >>

=head1 COPYRIGHT

Copyright (c) 2007-2011 Elliot Shank.

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
