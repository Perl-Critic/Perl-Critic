package Perl::Critic::Policy::ValuesAndExpressions::ProhibitMagicNumbers;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.21;

#----------------------------------------------------------------------------

my $DESC = q{Numeric literals make code less maintainable};
my $USE_READONLY_OR_CONSTANT =
    ' Use the Readonly module or the "constant" pragma instead';
my $TYPE_NOT_ALLOWED_SUFFIX = ") are not allowed.$USE_READONLY_OR_CONSTANT";

my %allowed         = hashify( 0, 1, 2 );   # Should be configurable
my $allowed_string  =
      ' is not one of the allowed literal values ('
    . ( join ', ', sort { $a <=> $b } keys %allowed )
    . ').'
    . $USE_READONLY_OR_CONSTANT;


#----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_LOW        }
sub default_themes   { return qw( readability )    }
sub applies_to       { return 'PPI::Token::Number' }

#----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if _element_is_in_an_include_readonly_or_version_statement($elem);

    my $literal = $elem->literal();
    if ( defined $literal and not defined $allowed{ $literal } ) {
        return
            $self->violation(
                $DESC,
                $elem->content() . $allowed_string,
                $elem,
            );
    } # end if

    if ($elem->isa('PPI::Token::Number::Binary')) {
        return
            $self->violation(
                $DESC,
                'Binary literals (' . $elem->content() . $TYPE_NOT_ALLOWED_SUFFIX,
                $elem,
            );
    } # end if
    if ($elem->isa('PPI::Token::Number::Exp')) {
        return
            $self->violation(
                $DESC,
                'Exponential literals (' . $elem->content() . $TYPE_NOT_ALLOWED_SUFFIX,
                $elem,
            );
    } # end if
    if ($elem->isa('PPI::Token::Number::Hex')) {
        return
            $self->violation(
                $DESC,
                'Hexadecimal literals (' . $elem->content() . $TYPE_NOT_ALLOWED_SUFFIX,
                $elem,
            );
    } # end if
    if ($elem->isa('PPI::Token::Number::Octal')) {
        return
            $self->violation(
                $DESC,
                'Octal literals (' . $elem->content() . $TYPE_NOT_ALLOWED_SUFFIX,
                $elem,
            );
    } # end if
    if ($elem->isa('PPI::Token::Number::Version')) {
        return
            $self->violation(
                $DESC,
                'Version literals (' . $elem->content() . $TYPE_NOT_ALLOWED_SUFFIX,
                $elem,
            );
    } # end if

    return;
} # end violates()

sub _element_is_in_an_include_readonly_or_version_statement {
    my $elem = shift;

    my $parent = $elem->parent();
    while ($parent) {
        if ($parent->isa('PPI::Statement')) {
            return 1 if $parent->isa('PPI::Statement::Include');

            if ( $parent->isa('PPI::Statement::Variable') ) {
                if ( $parent->type() eq 'our' ) {
                    my @variables = $parent->variables();
                    if ( scalar (@variables) == 1 and $variables[0] eq '$VERSION') {
                        return 1;
                    } # end if
                } # end if

                return 0;
            } # end if

            my $first_token = $parent->first_token();
            if ( $first_token->isa('PPI::Token::Word') ) {
                if ( $first_token eq 'Readonly' ) {
                    return 1;
                } # end if
            } # end if
# Uncomment once PPI bug fixed.
#        } elsif ($parent->isa('PPI::Structure::Block')) {
#            return 0;
        } # end if

        $parent = $parent->parent();
    } # end while

    return 0;
} # end _element_is_in_an_include_readonly_or_version_statement()


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
things like Perl version restrictions and L<Test::More> plans.  Uses of the
Readonly module are obviously valid.  Declarations of C<$VERSION> package
variables are permitted.

The rule is relaxed in that C<2> is permitted to allow for things like
alternation, the STDERR file handle, etc..

Use of binary, exponential, hexadecimal, octal, and version numbers, even for
C<0> and C<1> outside of C<use>/C<require>/C<Readonly> statements aren't
permitted.



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

  $frobnication_factor = 42;                #not ok
  use constant FROBNICATION_FACTOR => 42;   #ok


  use 5.6.1;                                #ok
  use Test::More plan => 57;                #ok
  our $VERSION = 0.21;                      #ok


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
