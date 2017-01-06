package Perl::Critic::Policy::ValuesAndExpressions::ProhibitImplicitNewlines;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Literal line breaks in a string};
Readonly::Scalar my $EXPL => [60,61];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                     }
sub default_severity     { return $SEVERITY_MEDIUM       }
sub default_themes       { return qw( core pbp cosmetic ) }
sub applies_to           { return 'PPI::Token::Quote'    }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem->string !~ m/\n/xms;

    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitImplicitNewlines - Use concatenation or HEREDOCs instead of literal line breaks in strings.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Strings with embedded line breaks are hard to read.  Use concatenation
or HEREDOCs instead.

    my $foo = "Line one is quite long
    Line two";                                    # Bad

    my $foo = "Line one is quite long\nLine two"; # Better, but still hard to read

    my $foo = "Line one is quite long\n"
        . "Line two";                               # Better still

    my $foo = <<'EOF';                            # Use heredoc for longer passages
    Line one is quite long
    Line two
    Line three breaks the camel's back
    EOF


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>


=head1 CREDITS

Initial development of this policy was supported by a grant from the
Perl Foundation.


=head1 COPYRIGHT


Copyright (c) 2007-2011 Chris Dolan.  Many rights reserved.

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
