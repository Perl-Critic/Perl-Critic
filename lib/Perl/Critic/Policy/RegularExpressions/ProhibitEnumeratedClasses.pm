##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::RegularExpressions::ProhibitEnumeratedClasses;

use 5.006001;
use strict;
use warnings;
use Readonly;

use English qw(-no_match_vars);
use List::MoreUtils qw(all);
use Carp qw(carp);

use Perl::Critic::Utils qw{ :booleans :severities hashify };
use Perl::Critic::Utils::PPIRegexp qw{ ppiify parse_regexp get_modifiers };

use base 'Perl::Critic::Policy';

our $VERSION = '1.104';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Use named character classes};
Readonly::Scalar my $EXPL => [248];

Readonly::Array my @PATTERNS => (  # order matters: most to least specific
   [q{ },'\\t','\\r','\\n']      => ['\\s', '\\S'],
   ['A-Z','a-z','_']             => ['\\w', '\\W'],
   ['A-Z','a-z']                 => ['[[:alpha:]]','[[:^alpha:]]'],
   ['A-Z']                       => ['[[:upper:]]','[[:^upper:]]'],
   ['a-z']                       => ['[[:lower:]]','[[:^lower:]]'],
   ['0-9']                       => ['\\d','\\D'],
   ['\w']                        => [undef, '\\W'],
   ['\s']                        => [undef, '\\S'],
);

#-----------------------------------------------------------------------------

sub supported_parameters { return qw()                    }
sub default_severity     { return $SEVERITY_LOWEST        }
sub default_themes       { return qw( core pbp cosmetic unicode ) }
sub applies_to           { return qw(PPI::Token::Regexp::Match
                                     PPI::Token::Regexp::Substitute
                                     PPI::Token::QuoteLike::Regexp) }

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    return eval { require Regexp::Parser; 1 } ? $TRUE : $FALSE;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    # optimization: don't bother parsing the regexp if there are no character classes
    return if $elem !~ m/\[/xms;

    my $re = ppiify(parse_regexp($elem));
    return if !$re;

    # Must pass a sub to find() because our node classes don't start with PPI::
    my $anyofs = $re->find(sub {$_[1]->isa('Perl::Critic::PPIRegexp::anyof')});
    return if !$anyofs;
    for my $anyof (@{$anyofs}) {
        my $violation = $self->_get_character_class_violations($elem, $anyof);
        return $violation if $violation;
    }
    return;  # OK
}

sub _get_character_class_violations {
    my ($self, $elem, $anyof) = @_;

    my %elements;
    for my $element ($anyof->children) {
        if ($element->isa('Perl::Critic::PPIRegexp::exact')) {
            my @tokens = split m/(\\.[^\\]*)/xms, $element->content;
            for my $token (map { split m/\A (\\[nrf])/xms, _fixup($_); } @tokens) {
                $elements{$token} = 1;
            }
        } elsif ($element->isa('Perl::Critic::PPIRegexp::anyof_char') ||
                 $element->isa('Perl::Critic::PPIRegexp::anyof_range') ||
                 $element->isa('Perl::Critic::PPIRegexp::anyof_class')) {
            for my $token (split m/\A (\\[nrf])/xms, _fixup($element->content)) {
                $elements{$token} = 1;
            }
        } else {
            # no known way to get to this branch; just for forward compatibility
            carp 'Unexpected type inside a character class: ' . (ref $element) . " '$element'";
        }
    }
    for (my $i = 0; $i < @PATTERNS; $i += 2) {  ##no critic (CStyleForLoop)
        if (all { exists $elements{$_} } @{$PATTERNS[$i]}) {
            my $neg = $anyof->re->neg;
            my $improvement = $PATTERNS[$i + 1]->[$neg ? 1 : 0];
            next if !defined $improvement;

            if ($neg && ! defined $PATTERNS[$i + 1]->[0]) {
                # the [^\w] => \W rule only applies if \w is the only token.
                # that is it does not apply to [^\w\s]
                next if 1 != scalar keys %elements;
            }

            my $orig = join q{}, '[', ($neg ? q{^} : ()), @{$PATTERNS[$i]}, ']';
            return $self->violation( $DESC . " ($orig vs. $improvement)", $EXPL, $elem );
        }
    }

    return;  # OK
}

Readonly::Hash my %HEX => (  # Note: this is ASCII specific!
   '0a' => '\\n',
   '0c' => '\\f',
   '0d' => '\\r',
   '20' => q{ },
);
sub _fixup {
   my ($chars) = @_;

   # \x0a -> \x{0a}
   $chars =~ s/\A \\x([\da-fA-F]{2})/\\x{$1}/gxms;

   # '\ ' -> q{ }
   $chars =~ s/\A \\[ ]/ /gxms;

   # \012 -> \x{0a}
   $chars =~ s/\A \\0([0-7]{2})/'\\x{'.(sprintf "%02x", oct $1).'}'/egxms;

   # \x{0a} -> \n
   $chars =~ s/\A (\\x [{] ([\da-fA-F]+) [}] ) /exists $HEX{$2} ? $HEX{$2} : $1/egxms;

   return $chars;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::RegularExpressions::ProhibitEnumeratedClasses - Use named character classes instead of explicit character lists.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

This policy is not for everyone!  If you are working in pure ASCII,
then disable it now or you may see some false violations.

On the other hand many of us are working in a multilingual world with
an extended character set, probably Unicode.  In that world, patterns
like C<m/[A-Z]/> can be a source of bugs when you really meant
C<m/\p{IsUpper}/>.  This policy catches a selection of possible
incorrect character class usage.

Specifically, the patterns are:

B<C<[\t\r\n\f\ ]>> vs. B<C<\s>>

B<C<[\t\r\n\ ]>> vs. B<C<\s>>   (because many people forget C<\f>)

B<C<[A-Za-z_]>> vs. B<C<\w>>

B<C<[A-Za-z]>> vs. B<C<\p{IsAlphabetic}>>

B<C<[A-Z]>> vs. B<C<\p{IsUpper}>>

B<C<[a-z]>> vs. B<C<\p{IsLower}>>

B<C<[0-9]>> vs. B<C<\d>>

B<C<[^\w]>> vs. B<C<\W>>

B<C<[^\s]>> vs. B<C<\S>>


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 PREREQUISITES

This policy will disable itself if L<Regexp::Parser|Regexp::Parser> is not
installed.


=head1 CREDITS

Initial development of this policy was supported by a grant from the
Perl Foundation.


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2007-2009 Chris Dolan.  Many rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
