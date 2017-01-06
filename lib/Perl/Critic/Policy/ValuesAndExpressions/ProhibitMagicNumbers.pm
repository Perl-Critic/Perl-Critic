package Perl::Critic::Policy::ValuesAndExpressions::ProhibitMagicNumbers;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw{ :booleans :characters :severities :data_conversion };

use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#----------------------------------------------------------------------------

Readonly::Scalar my $EXPL =>
    q{Unnamed numeric literals make code less maintainable};
Readonly::Scalar my $USE_READONLY_OR_CONSTANT =>
    ' Use the Readonly or Const::Fast module or the "constant" pragma instead';
Readonly::Scalar my $TYPE_NOT_ALLOWED_SUFFIX =>
    ") are not allowed.$USE_READONLY_OR_CONSTANT";

Readonly::Scalar my $UNSIGNED_NUMBER =>
    qr{
            \d+ (?: [$PERIOD] \d+ )?  # 1, 1.5, etc.
        |   [$PERIOD] \d+             # .3, .7, etc.
    }xms;
Readonly::Scalar my $SIGNED_NUMBER => qr/ [-+]? $UNSIGNED_NUMBER /xms;

Readonly::Scalar my $RANGE =>
    qr{
        \A
        ($SIGNED_NUMBER)
        [$PERIOD] [$PERIOD]
        ($SIGNED_NUMBER)
        (?:
            [$COLON] by [$LEFT_PAREN]
            ($UNSIGNED_NUMBER)
            [$RIGHT_PAREN]
        )?
        \z
    }xms;

Readonly::Scalar my $SPECIAL_ARRAY_SUBSCRIPT_EXEMPTION => -1;

#----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name           => 'allowed_values',
            description    => 'Individual and ranges of values to allow, and/or "all_integers".',
            default_string => '0 1 2',
            parser         => \&_parse_allowed_values,
        },
        {
            name               => 'allowed_types',
            description        => 'Kind of literals to allow.',
            default_string     => 'Float',
            behavior           => 'enumeration',
            enumeration_values => [ qw{ Binary Exp Float Hex Octal } ],
            enumeration_allow_multiple_values => 1,
        },
        {
            name           => 'allow_to_the_right_of_a_fat_comma',
            description    =>
                q[Should anything to the right of a "=>" be allowed?],
            default_string => '1',
            behavior           => 'boolean',
        },
        {
            name            => 'constant_creator_subroutines',
            description     => q{Names of subroutines that create constants},
            behavior        => 'string list',
            list_always_present_values => [
                qw<
                    Readonly Readonly::Scalar Readonly::Array Readonly::Hash
                    const
                >,
            ],
        },
    );
}

sub default_severity { return $SEVERITY_LOW          }
sub default_themes   { return qw( core maintenance certrec ) }
sub applies_to       { return 'PPI::Token::Number'   }

sub default_maximum_violations_per_document { return 10; }

#----------------------------------------------------------------------------

sub initialize_if_enabled {
    my ($self, $config) = @_;

    $self->_determine_checked_types();

    return $TRUE;
}

sub _parse_allowed_values {
    my ($self, $parameter, $config_string) = @_;

    my ( $all_integers_allowed, $allowed_values )
        = _determine_allowed_values($config_string);

    my $allowed_string = ' is not one of the allowed literal values (';
    if ($all_integers_allowed) {
        $allowed_string .= 'all integers';

        if ( %{$allowed_values} ) {
            $allowed_string .= ', ';
        }
    }
    $allowed_string
        .= ( join ', ', sort { $a <=> $b } keys %{$allowed_values} ) . ').'
        . $USE_READONLY_OR_CONSTANT;

    $self->{_allowed_values}       = $allowed_values;
    $self->{_all_integers_allowed} = $all_integers_allowed;
    $self->{_allowed_string}       = $allowed_string;

    return;
}

sub _determine_allowed_values {
    my ($config_string) = @_;

    my @allowed_values;
    my @potential_allowed_values;
    my $all_integers_allowed = 0;

    if ( defined $config_string ) {
        my @allowed_values_strings =
            grep {$_} split m/\s+/xms, $config_string;

        foreach my $value_string (@allowed_values_strings) {
            if ($value_string eq 'all_integers') {
                $all_integers_allowed = 1;
            } elsif ( $value_string =~ m/ \A $SIGNED_NUMBER \z /xms ) {
                push @potential_allowed_values, $value_string + 0;
            } elsif ( $value_string =~ m/$RANGE/xms ) {
                my ( $minimum, $maximum, $increment ) = ($1, $2, $3);
                $increment ||= 1;

                $minimum += 0;
                $maximum += 0;
                $increment += 0;

                for (                       ## no critic (ProhibitCStyleForLoops)
                    my $value = $minimum;
                    $value <= $maximum;
                    $value += $increment
                ) {
                    push @potential_allowed_values, $value;
                }
            } else {
                die q{Invalid value for allowed_values: }, $value_string,
                    q{. Must be a number, a number range, or},
                    qq{ "all_integers".\n};
            }
        }

        if ($all_integers_allowed) {
            @allowed_values = grep { $_ != int $_ } @potential_allowed_values; ## no critic ( BuiltinFunctions::ProhibitUselessTopic )
        } else {
            @allowed_values = @potential_allowed_values;
        }
    } else {
        @allowed_values = (2);
    }

    if ( not $all_integers_allowed ) {
        push @allowed_values, 0, 1;
    }
    my %allowed_values = hashify(@allowed_values);

    return ( $all_integers_allowed, \%allowed_values );
}

sub _determine_checked_types {
    my ($self) = @_;

    my %checked_types = (
        'PPI::Token::Number::Binary'  => 'Binary literals (',
        'PPI::Token::Number::Float'   => 'Floating-point literals (',
        'PPI::Token::Number::Exp'     => 'Exponential literals (',
        'PPI::Token::Number::Hex'     => 'Hexadecimal literals (',
        'PPI::Token::Number::Octal'   => 'Octal literals (',
        'PPI::Token::Number::Version' => 'Version literals (',
    );

    # This will be set by the enumeration behavior specified in
    # supported_parameters() above.
    my $allowed_types = $self->{_allowed_types};

    foreach my $allowed_type ( keys %{$allowed_types} ) {
        delete $checked_types{"PPI::Token::Number::$allowed_type"};

        if ( $allowed_type eq 'Exp' ) {

            # because an Exp isa(Float).
            delete $checked_types{'PPI::Token::Number::Float'};
        }
    }

    $self->{_checked_types} = \%checked_types;

    return;
}


sub violates {
    my ( $self, $elem, undef ) = @_;

    if ( $self->{_allow_to_the_right_of_a_fat_comma} ) {
        return if _element_is_to_the_right_of_a_fat_comma($elem);
    }

    return if _element_is_in_an_include_readonly_or_version_statement(
        $self, $elem,
    );
    return if _element_is_in_a_plan_statement($elem);
    return if _element_is_in_a_constant_subroutine($elem);
    return if _element_is_a_package_statement_version_number($elem);

    my $literal = $elem->literal();
    if (
            defined $literal
        and not (
                    $self->{_all_integers_allowed}
                and int $literal == $literal
            )
        and not defined $self->{_allowed_values}{$literal}
        and not (
                    _element_is_sole_component_of_a_subscript($elem)
                and $literal == $SPECIAL_ARRAY_SUBSCRIPT_EXEMPTION
            )
    ) {
        return
            $self->violation(
                $elem->content() . $self->{_allowed_string},
                $EXPL,
                $elem,
            );
    }


    my ( $number_type, $type_string );

    while (
        ( $number_type, $type_string ) = ( each %{ $self->{_checked_types} } )
    ) {
        if ( $elem->isa($number_type) ) {
            return
                $self->violation(
                    $type_string . $elem->content() . $TYPE_NOT_ALLOWED_SUFFIX,
                    $EXPL,
                    $elem,
                );
        }
    }

    return;
}

sub _element_is_to_the_right_of_a_fat_comma {
    my ($elem) = @_;

    my $previous = $elem->sprevious_sibling() or return;

    $previous->isa('PPI::Token::Operator') or return;

    return $previous->content() eq q[=>];
}

sub _element_is_sole_component_of_a_subscript {
    my ($elem) = @_;

    my $parent = $elem->parent();
    if ( $parent and $parent->isa('PPI::Statement::Expression') ) {
        if ( $parent->schildren() > 1 ) {
            return 0;
        }

        my $grandparent = $parent->parent();
        if (
                $grandparent
            and $grandparent->isa('PPI::Structure::Subscript')
        ) {
            return 1;
        }
    }

    return 0;
}

sub _element_is_in_an_include_readonly_or_version_statement {
    my ($self, $elem) = @_;

    my $parent = $elem->parent();
    while ($parent) {
        if ( $parent->isa('PPI::Statement') ) {
            return 1 if $parent->isa('PPI::Statement::Include');

            if ( $parent->isa('PPI::Statement::Variable') ) {
                if ( $parent->type() eq 'our' ) {
                    my @variables = $parent->variables();
                    if (
                            scalar @variables == 1
                        and $variables[0] eq '$VERSION' ## no critic (RequireInterpolationOfMetachars)
                    ) {
                        return 1;
                    }
                }

                return 0;
            }

            my $first_token = $parent->first_token();
            if ( $first_token->isa('PPI::Token::Word') ) {
                if ( $self->{_constant_creator_subroutines}{
                        $first_token->content() } ) {
                    return 1;
                }
            } elsif ($parent->isa('PPI::Structure::Block')) {
                return 0;
            }
        }

        $parent = $parent->parent();
    }

    return 0;
}

# Allow "plan tests => 39;".

Readonly::Scalar my $PLAN_STATEMENT_MINIMUM_TOKENS => 4;

sub _element_is_in_a_plan_statement {
    my ($elem) = @_;

    my $parent = $elem->parent();
    return 0 if not $parent;

    return 0 if not $parent->isa('PPI::Statement');

    my @children = $parent->schildren();
    return 0 if @children < $PLAN_STATEMENT_MINIMUM_TOKENS;

    return 0 if not $children[0]->isa('PPI::Token::Word');
    return 0 if $children[0]->content() ne 'plan';

    return 0 if not $children[1]->isa('PPI::Token::Word');
    return 0 if $children[1]->content() ne 'tests';

    return 0 if not $children[2]->isa('PPI::Token::Operator');
    return 0 if $children[2]->content() ne '=>';

    return 1;
}

sub _element_is_in_a_constant_subroutine {
    my ($elem) = @_;

    my $parent = $elem->parent();
    return 0 if not $parent;

    return 0 if not $parent->isa('PPI::Statement');

    my $following = $elem->snext_sibling();
    if ($following) {
        return 0 if not $following->isa('PPI::Token::Structure');
        return 0 if $following->content() ne $SCOLON;
        return 0 if $following->snext_sibling();
    }

    my $preceding = $elem->sprevious_sibling();
    if ($preceding) {
        return 0 if not $preceding->isa('PPI::Token::Word');
        return 0 if $preceding->content() ne 'return';
        return 0 if $preceding->sprevious_sibling();
    }

    return 0 if $parent->snext_sibling();
    return 0 if $parent->sprevious_sibling();

    my $grandparent = $parent->parent();
    return 0 if not $grandparent;

    return 0 if not $grandparent->isa('PPI::Structure::Block');

    my $greatgrandparent = $grandparent->parent();
    return 0 if not $greatgrandparent;
    return 0 if not $greatgrandparent->isa('PPI::Statement::Sub');

    return 1;
}

sub _element_is_a_package_statement_version_number {
    my ($elem) = @_;

    my $parent = $elem->statement()
        or return 0;

    $parent->isa( 'PPI::Statement::Package' )
        or return 0;

    my $version = $parent->schild( 2 )
        or return 0;

    return $version == $elem;
}

1;

__END__

#----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitMagicNumbers - Don't use values that don't explain themselves.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

What is a "magic number"?  A magic number is a number that appears in
code without any explanation; e.g.  C<$bank_account_balance *=
57.492;>.  You look at that number and have to wonder where that
number came from.  Since you don't understand the significance of the
number, you don't understand the code.

In general, numeric literals other than C<0> or C<1> in should not be used.
Use the L<constant|constant> pragma or the L<Readonly|Readonly> or
L<Const::Fast|Const::Fast> modules to give a descriptive name to the number.

There are, of course, exceptions to when this rule should be applied.
One good example is positioning of objects in some container like
shapes on a blueprint or widgets in a user interface.  In these cases,
the significance of a number can readily be determined by context.

The maximum number of violations per document for this policy defaults
to 10.


=head2 Ways in which this module applies this rule.

By default, this rule is relaxed in that C<2> is permitted to allow
for common things like alternation, the STDERR file handle, etc..

Numeric literals are allowed in C<use> and C<require> statements to
allow for things like Perl version restrictions and
L<Test::More|Test::More> plans.  Declarations of C<$VERSION> package
variables are permitted.  Use of C<Readonly>, C<Readonly::Scalar>,
C<Readonly::Array>, and C<Readonly::Hash> from the
L<Readonly|Readonly> module are obviously valid, but use of
C<Readonly::Scalar1>, C<Readonly::Array1>, and C<Readonly::Hash1> are
specifically not supported.

Use of binary, exponential, hexadecimal, octal, and version numbers,
even for C<0> and C<1>, outside of C<use>/C<require>/C<Readonly>
statements aren't permitted (but you can change this).

There is a special exemption for accessing the last element of an
array, i.e. C<$x[-1]>.


    $x = 0;                                   # ok
    $x = 0.0;                                 # ok
    $x = 1;                                   # ok
    $x = 1.0;                                 # ok
    $x = 1.5;                                 # not ok
    $x = 0b0                                  # not ok
    $x = 0b1                                  # not ok
    $x = 0x00                                 # not ok
    $x = 0x01                                 # not ok
    $x = 000                                  # not ok
    $x = 001                                  # not ok
    $x = 0e1                                  # not ok
    $x = 1e1                                  # not ok

    $frobnication_factor = 42;                # not ok
    use constant FROBNICATION_FACTOR => 42;   # ok


    use 5.6.1;                                # ok
    use Test::More plan => 57;                # ok
    plan tests => 39;                         # ok
    our $VERSION = 0.22;                      # ok


    $x = $y[-1]                               # ok
    $x = $y[-2]                               # not ok



    foreach my $solid (1..5) {                # not ok
        ...
    }


    use Readonly;

    Readonly my $REGULAR_GEOMETRIC_SOLIDS => 5;

    foreach my $solid (1..$REGULAR_GEOMETRIC_SOLIDS) {  #ok
        ...
    }


=head1 CONFIGURATION

This policy has four options: C<allowed_values>, C<allowed_types>,
C<allow_to_the_right_of_a_fat_comma>, and C<constant_creator_subroutines>.


=head2 C<allowed_values>

The C<allowed_values> parameter is a whitespace delimited set of
permitted number I<values>; this does not affect the permitted formats
for numbers.  The defaults are equivalent to having the following in
your F<.perlcriticrc>:

    [ValuesAndExpressions::ProhibitMagicNumbers]
    allowed_values = 0 1 2

Note that this policy forces the values C<0> and C<1> into the
permitted values.  Thus, specifying no values,

    allowed_values =

is the same as simply listing C<0> and C<1>:

    allowed_values = 0 1

The special C<all_integers> value, not surprisingly, allows all
integral values to pass, subject to the restrictions on number types.

Ranges can be specified as two (possibly fractional) numbers separated
by two periods, optionally suffixed with an increment using the Perl 6
C<:by()> syntax.  E.g.

    allowed_values = 7..10

will allow 0, 1, 7, 8, 9, and 10 as literal values.  Using fractional
values like so

    allowed_values = -3.5..-0.5:by(0.5)

will permit -3.5, -3, -2.5, -2, -2.5, -1, -0.5, 0, and 1.
Unsurprisingly, the increment defaults to 1, which means that

    allowed_values = -3.5..-0.5

will make -3.5, -2.5, -2.5, -0.5, 0, and 1 valid.

Ranges are not lazy, i.e. you'd better have a lot of memory available
if you use a range of C<1..1000:by(0.01)>.  Also remember that all of
this is done using floating-point math, which means that
C<1..10:by(0.3333)> is probably not going to be very useful.

Specifying an upper limit that is less than the lower limit will
result in no values being produced by that range.  Negative increments
are not permitted.

Multiple ranges are permitted.

To put this all together, the following is a valid, though not likely
to be used, F<.perlcriticrc> entry:

    [ValuesAndExpressions::ProhibitMagicNumbers]
    allowed_values = 3.1415269 82..103 -507.4..57.8:by(0.2) all_integers


=head2 C<allowed_types>

The C<allowed_types> parameter is a whitespace delimited set of
subclasses of L<PPI::Token::Number|PPI::Token::Number>.

Decimal integers are always allowed.  By default, floating-point
numbers are also allowed.

For example, to allow hexadecimal literals, you could configure this
policy like

    [ValuesAndExpressions::ProhibitMagicNumbers]
    allowed_types = Hex

but without specifying anything for C<allowed_values>, the allowed
hexadecimal literals will be C<0x00>, C<0x01>, and C<0x02>.  Note,
also, as soon as you specify a value for this parameter, you must
include C<Float> in the list to continue to be able to use floating
point literals.  This effect can be used to restrict literals to only
decimal integers:

    [ValuesAndExpressions::ProhibitMagicNumbers]
    allowed_types =

If you permit exponential notation, you automatically also allow
floating point values because an exponential is a subclass of
floating-point in L<PPI|PPI>.


=head2 C<allow_to_the_right_of_a_fat_comma>

If this is set, you can put any number to the right of a fat comma.

    my %hash =     ( a => 4512, b => 293 );         # ok
    my $hash_ref = { a => 4512, b => 293 };         # ok
    some_subroutine( a => 4512, b => 293 );         # ok

Currently, this only means I<directly> to the right of the fat comma.  By
default, this value is I<true>.


=head2 C<constant_creator_subroutines>

This parameter allows you to specify the names of subroutines that create
constants, in addition to C<Readonly>, C<Const::Fast>, and friends.  For
example, if you use a custom C<Const::Fast>-like module that supports a
C<create_constant> subroutine to create constants, you could add something
like the following to your F<.perlcriticrc>:

    [ValuesAndExpressions::ProhibitMagicNumbers]
    constant_creator_subroutines = create_constant

If you have more than one name to add, separate them by whitespace.

The subroutine name should appear exactly as it is in your code.  For example,
if your code does not import the creating subroutine
subroutine, you would need to configure this policy as something like

    [ValuesAndExpressions::ProhibitMagicNumbers]
    constant_creator_subroutines = create_constant Constant::Create::create_constant


=head1 BUGS

There is currently no way to permit version numbers in regular code,
even if you include them in the C<allowed_types>.  Some may actually
consider this a feature.


=head1 AUTHOR

Elliot Shank C<< <perl@galumph.com> >>


=head1 COPYRIGHT

Copyright (c) 2006-2011 Elliot Shank.

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
