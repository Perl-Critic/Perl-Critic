package Perl::Critic::Policy::ValuesAndExpressions::ProhibitMagicNumbers;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.21;

#----------------------------------------------------------------------------

my $desc = q{Numeric literals make code less maintainable};
my %allowed = hashify( 0, 1, 2 );   # Should be configurable

#----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_LOW        }
sub default_themes   { return qw( readability )    }
sub applies_to       { return 'PPI::Token::Number' }

#----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if _element_is_in_an_include_or_readonly_statement($elem);

    my @violation = ( $desc, undef, $elem );

    my $literal = $elem->literal();
    return $self->violation(@violation)
        if defined $literal and not defined $allowed{ $literal };

    if (
            $elem->isa('PPI::Token::Number::Binary')
        or  $elem->isa('PPI::Token::Number::Hex')
        or  $elem->isa('PPI::Token::Number::Octal')
        or  $elem->isa('PPI::Token::Number::Version')
    ) {
        return $self->violation(@violation);
    } # end if

    if (
            $elem->isa('PPI::Token::Number::Exp')
        and $elem->content() ne '0E0'
        and $elem->content() ne '0e0'
    ) {
        return $self->violation(@violation);
    } # end if

    return;
} # end violates()

sub _element_is_in_an_include_or_readonly_statement {
    my $elem = shift;

    my $parent = $elem->parent();
    while ($parent) {
        if ($parent->isa('PPI::Statement')) {
            return 1 if $parent->isa('PPI::Statement::Include');

            my $first_token = $parent->first_token();
            if (
                    $first_token->isa('PPI::Token::Word')
                and $first_token eq 'Readonly'
            ) {
                return 1;
            } # end if
# Uncomment once PPI bug fixed.
#        } elsif ($parent->isa('PPI::Structure::Block')) {
#            return 0;
        } # end if

        $parent = $parent->parent();
    } # end while

    return 0;
} # end _element_is_in_an_include_or_readonly_statement()


1;

__END__

#----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitMagicNumbers

=head1 DESCRIPTION

Numeric literals other than C<0> or C<1> in the middle of code make it hard to
maintain because one cannot understand their significance or where they were
derived from.  Use the L<constant> pragma or the L<Readonly> module to give a
descriptive name to the number.

Numeric literals are allowed in C<use> and C<require> statements to allow for
things like Perl version restrictions and L<Test::More> plans.

The rule is relaxed in that C<2> is permitted to allow for things like
alternation, the STDERR file handle, etc..

Use of binary, hexadecimal, octal, and version numbers, even for C<0> and C<1>
outside of C<use>/C<require>/C<Readonly> statements aren't permitted.  This
applies for exponential numbers as well, with the exception of the "zero but
true" value, "C<0e0>".


  $x = 0;                                   #ok
  $x = 0.0;                                 #ok
  $x = 1;                                   #ok
  $x = 1.0;                                 #ok
  $x = 1.5;                                 #not ok
  $x = 0b0                                  #not ok
  $x = 0b1                                  #not ok
  $x = 0x00                                 #not ok
  $x = 0x01                                 #not ok
  $x = 000                                  #not ok
  $x = 001                                  #not ok
  $x = 0e1                                  #not ok
  $x = 1e1                                  #not ok
  $x = 0e0                                  #ok

  $frobnication_factor = 42;                #not ok
  use constant FROBNICATION_FACTOR => 42;   #ok


  use 5.6.1;                                #ok
  use Test::More plan => 57;                #ok


  foreach my $solid (1..5) {                #not ok
      ...
  }


  use Readonly;

  Readonly my $REGULAR_GEOMETRIC_SOLIDS => 5;

  foreach my $solid (1..$REGULAR_GEOMETRIC_SOLIDS) {  #ok
      ...
  }


=head1 AUTHOR

Elliot Shank C<< <perl@galumph.com> >>

=head1 COPYRIGHT

Copyright (c) 2006 Elliot Shank.  All rights reserved.

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
# ex: set ts=8 sts=4 sw=4 expandtab
