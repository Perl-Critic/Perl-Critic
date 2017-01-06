package Perl::Critic::Policy::NamingConventions::Capitalization;

use 5.006001;
use strict;
use warnings;

use English qw< -no_match_vars >;
use Readonly;

use List::MoreUtils qw< any >;

use Perl::Critic::Exception::AggregateConfiguration;
use Perl::Critic::Exception::Configuration::Option::Policy::ParameterValue;
use Perl::Critic::Utils qw<
    :booleans :characters :severities
    hashify is_perl_global
>;
use Perl::Critic::Utils::Perl qw< symbol_without_sigil >;
use Perl::Critic::Utils::PPI qw<
    is_in_subroutine
>;
use PPIx::Utilities::Statement qw<
    get_constant_name_elements_from_declaring_statement
>;

use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

# Don't worry about leading digits-- let perl/PPI do that.
Readonly::Scalar my $ALL_ONE_CASE_REGEX      =>
    qr< \A [@%\$]? (?: [[:lower:]_\d]+ | [[:upper:]_\d]+ ) \z >xms;
Readonly::Scalar my $ALL_LOWER_REGEX         => qr< \A [[:lower:]_\d]+ \z >xms;
Readonly::Scalar my $ALL_UPPER_REGEX         => qr< \A [[:upper:]_\d]+ \z >xms;
Readonly::Scalar my $STARTS_WITH_LOWER_REGEX => qr< \A _* [[:lower:]\d]   >xms;
Readonly::Scalar my $STARTS_WITH_UPPER_REGEX => qr< \A _* [[:upper:]\d]   >xms;
Readonly::Scalar my $NO_RESTRICTION_REGEX    => qr< .                     >xms;

Readonly::Hash my %CAPITALIZATION_SCHEME_TAGS    => (
    ':single_case'          => {
        regex               => $ALL_ONE_CASE_REGEX,
        regex_violation     => 'is not all lower case or all upper case',
    },
    ':all_lower'            => {
        regex               => $ALL_LOWER_REGEX,
        regex_violation     => 'is not all lower case',
    },
    ':all_upper'            => {
        regex               => $ALL_UPPER_REGEX,
        regex_violation     => 'is not all upper case',
    },
    ':starts_with_lower'    => {
        regex               => $STARTS_WITH_LOWER_REGEX,
        regex_violation     => 'does not start with a lower case letter',
    },
    ':starts_with_upper'    => {
        regex               => $STARTS_WITH_UPPER_REGEX,
        regex_violation     => 'does not start with a upper case letter',
    },
    ':no_restriction'       => {
        regex               => $NO_RESTRICTION_REGEX,
        regex_violation     => 'there is a bug in Perl::Critic if you are reading this',
    },
);

Readonly::Scalar my $PACKAGE_REGEX          => qr/ :: | ' /xms;

Readonly::Hash my %NAME_FOR_TYPE => (
    package                 => 'Package',
    subroutine              => 'Subroutine',
    local_lexical_variable  => 'Local lexical variable',
    scoped_lexical_variable => 'Scoped lexical variable',
    file_lexical_variable   => 'File lexical variable',
    global_variable         => 'Global variable',
    constant                => 'Constant',
    label                   => 'Label',
);

Readonly::Hash my %IS_COMMA => hashify( $COMMA, $FATCOMMA );

Readonly::Scalar my $EXPL                   => [ 45, 46 ];

#-----------------------------------------------------------------------------

# Can't handle named parameters yet.
sub supported_parameters {
    return (
        {
            name               => 'packages',
            description        => 'How package name components should be capitalized.  Valid values are :single_case, :all_lower, :all_upper:, :starts_with_lower, :starts_with_upper, :no_restriction, or a regex.',
            default_string     => ':starts_with_upper',
            behavior           => 'string',
        },
        {
            name               => 'package_exemptions',
            description        => 'Package names that are exempt from capitalization rules.  The values here are regexes that will be surrounded by \A and \z.',
            default_string     => 'main',
            behavior           => 'string list',
        },
        {
            name               => 'subroutines',
            description        => 'How subroutine names should be capitalized.  Valid values are :single_case, :all_lower, :all_upper, :starts_with_lower, :starts_with_upper, :no_restriction, or a regex.',
            default_string     => ':single_case',  # Matches ProhibitMixedCaseSubs
            behavior           => 'string',
        },
        {
            name               => 'subroutine_exemptions',
            description        => 'Subroutine names that are exempt from capitalization rules.  The values here are regexes that will be surrounded by \A and \z.',
            default_string     =>
                join (
                    $SPACE,
                    qw<

                        AUTOLOAD  BUILD     BUILDARGS CLEAR   CLOSE
                        DELETE    DEMOLISH  DESTROY   EXISTS  EXTEND
                        FETCH     FETCHSIZE FIRSTKEY  GETC    NEXTKEY
                        POP       PRINT     PRINTF    PUSH    READ
                        READLINE  SCALAR    SHIFT     SPLICE  STORE
                        STORESIZE TIEARRAY  TIEHANDLE TIEHASH TIESCALAR
                        UNSHIFT   UNTIE     WRITE

                    >,
                ),
            behavior           => 'string list',
        },
        {
            name               => 'local_lexical_variables',
            description        => 'How local lexical variables names should be capitalized.  Valid values are :single_case, :all_lower, :all_upper, :starts_with_lower, :starts_with_upper, :no_restriction, or a regex.',
            default_string     => ':single_case',  # Matches ProhibitMixedCaseVars
            behavior           => 'string',
        },
        {
            name               => 'local_lexical_variable_exemptions',
            description        => 'Local lexical variable names that are exempt from capitalization rules.  The values here are regexes that will be surrounded by \A and \z.',
            default_string     => $EMPTY,
            behavior           => 'string list',
        },
        {
            name               => 'scoped_lexical_variables',
            description        => 'How lexical variables that are scoped to a subset of subroutines, should be capitalized.  Valid values are :single_case, :all_lower, :all_upper, :starts_with_lower, :starts_with_upper, :no_restriction, or a regex.',
            default_string     => ':single_case',  # Matches ProhibitMixedCaseVars
            behavior           => 'string',
        },
        {
            name               => 'scoped_lexical_variable_exemptions',
            description        => 'Names for variables in anonymous blocks that are exempt from capitalization rules.  The values here are regexes that will be surrounded by \A and \z.',
            default_string     => $EMPTY,
            behavior           => 'string list',
        },
        {
            name               => 'file_lexical_variables',
            description        => 'How lexical variables at the file level should be capitalized.  Valid values are :single_case, :all_lower, :all_upper, :starts_with_lower, :starts_with_upper, :no_restriction, or a regex.',
            default_string     => ':single_case',  # Matches ProhibitMixedCaseVars
            behavior           => 'string',
        },
        {
            name               => 'file_lexical_variable_exemptions',
            description        => 'File-scope lexical variable names that are exempt from capitalization rules.  The values here are regexes that will be surrounded by \A and \z.',
            default_string     => $EMPTY,
            behavior           => 'string list',
        },
        {
            name               => 'global_variables',
            description        => 'How global (package) variables should be capitalized.  Valid values are :single_case, :all_lower, :all_upper, :starts_with_lower, :starts_with_upper, :no_restriction, or a regex.',
            default_string     => ':single_case',  # Matches ProhibitMixedCaseVars
            behavior           => 'string',
        },
        {
            name               => 'global_variable_exemptions',
            description        => 'Global variable names that are exempt from capitalization rules.  The values here are regexes that will be surrounded by \A and \z.',
            default_string     => '\$VERSION @ISA @EXPORT(?:_OK)? %EXPORT_TAGS \$AUTOLOAD %ENV %SIG \$TODO',  ## no critic (RequireInterpolation)
            behavior           => 'string list',
        },
        {
            name               => 'constants',
            description        => 'How constant names should be capitalized.  Valid values are :single_case, :all_lower, :all_upper, :starts_with_lower, :starts_with_upper, :no_restriction, or a regex.',
            default_string     => ':all_upper',
            behavior           => 'string',
        },
        {
            name               => 'constant_exemptions',
            description        => 'Constant names that are exempt from capitalization rules.  The values here are regexes that will be surrounded by \A and \z.',
            default_string     => $EMPTY,
            behavior           => 'string list',
        },
        {
            name               => 'labels',
            description        => 'How labels should be capitalized.  Valid values are :single_case, :all_lower, :all_upper, :starts_with_lower, :starts_with_upper, :no_restriction, or a regex.',
            default_string     => ':all_upper',
            behavior           => 'string',
        },
        {
            name               => 'label_exemptions',
            description        => 'Labels that are exempt from capitalization rules.  The values here are regexes that will be surrounded by \A and \z.',
            default_string     => $EMPTY,
            behavior           => 'string list',
        },
    );
}

sub default_severity    { return $SEVERITY_LOWEST                       }
sub default_themes      { return qw< core pbp cosmetic >                }
sub applies_to          { return qw< PPI::Statement PPI::Token::Label > }

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    my ($self, $config) = @_;

    my $configuration_exceptions =
        Perl::Critic::Exception::AggregateConfiguration->new();

    KIND:
    foreach my $kind_of_name ( qw<
        package                 subroutine
        local_lexical_variable  scoped_lexical_variable
        file_lexical_variable   global_variable
        constant                label
    > ) {
        my ($capitalization_regex, $message) =
            $self->_derive_capitalization_test_regex_and_message(
                $kind_of_name, $configuration_exceptions,
            );
        my $exemption_regexes =
            $self->_derive_capitalization_exemption_test_regexes(
                $kind_of_name, $configuration_exceptions,
            );

        # Keep going, despite problems, so that all problems can be reported
        # at one go, rather than the user fixing one problem, receiving a new
        # error, etc..
        next KIND if $configuration_exceptions->has_exceptions();

        $self->{"_${kind_of_name}_test"} = sub {
            my ($name) = @_;

            return if _name_is_exempt($name, $exemption_regexes);

            return $message if $name !~ m/$capitalization_regex/xms;
            return;
        }
    }

    if ( $configuration_exceptions->has_exceptions() ) {
        $configuration_exceptions->throw();
    }

    return $TRUE;
}

sub _derive_capitalization_test_regex_and_message {
    my ($self, $kind_of_name, $configuration_exceptions) = @_;

    my $capitalization_option = "${kind_of_name}s";
    my $capitalization = $self->{"_$capitalization_option"};

    if ( my $tag_properties = $CAPITALIZATION_SCHEME_TAGS{$capitalization} ) {
        return @{$tag_properties}{ qw< regex regex_violation > };
    }
    elsif ($capitalization =~ m< \A : >xms) {
        $configuration_exceptions->add_exception(
            Perl::Critic::Exception::Configuration::Option::Policy::ParameterValue->new(
                policy          => $self,
                option_name     => $capitalization_option,
                option_value    => $capitalization,
                message_suffix  =>
                        'is not a known capitalization scheme tag. Valid tags are: '
                    .   (join q<, >, sort keys %CAPITALIZATION_SCHEME_TAGS)
                    .   $PERIOD,
            )
        );
        return;
    }

    my $regex;
    eval { $regex = qr< \A $capitalization \z >xms; }
        or do {
            $configuration_exceptions->add_exception(
                Perl::Critic::Exception::Configuration::Option::Policy::ParameterValue->new(
                    policy          => $self,
                    option_name     => $capitalization_option,
                    option_value    => $capitalization,
                    message_suffix  =>
                        "is not a valid regular expression: $EVAL_ERROR",
                )
            );
            return;
        };

    return $regex, qq<does not match "\\A$capitalization\\z".>;
}

sub _derive_capitalization_exemption_test_regexes {
    my ($self, $kind_of_name, $configuration_exceptions) = @_;

    my $exemptions_option = "${kind_of_name}_exemptions";
    my $exemptions = $self->{"_$exemptions_option"};

    my @regexes;

    PATTERN:
    foreach my $pattern ( keys %{$exemptions} ) {
        my $regex;
        eval { $regex = qr< \A $pattern \z >xms; }
            or do {
                $configuration_exceptions->add_exception(
                    Perl::Critic::Exception::Configuration::Option::Policy::ParameterValue->new(
                        policy          => $self,
                        option_name     => $exemptions_option,
                        option_value    => $pattern,
                        message_suffix  =>
                            "is not a valid regular expression: $EVAL_ERROR",
                    )
                );
                next PATTERN;
            };

        push @regexes, $regex;
    }

    return \@regexes;
}

sub _name_is_exempt {
    my ($name, $exemption_regexes) = @_;

    foreach my $regex ( @{$exemption_regexes} ) {
        return $TRUE if $name =~ m/$regex/xms;
    }

    return $FALSE;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    # Want given.  Want 5.10.  Gimme gimme gimme.  :]
    if ( $elem->isa('PPI::Statement::Variable') ) {
        return $self->_variable_capitalization($elem);
    }

    if ( $elem->isa('PPI::Statement::Sub') ) {
        return $self->_subroutine_capitalization($elem);
    }

    if (
        my @names = get_constant_name_elements_from_declaring_statement($elem)
    ) {
        return ( grep { $_ }
            map { $self->_constant_capitalization( $elem, $_ ) } @names )
    }

    if ( $elem->isa('PPI::Statement::Package') ) {
        return $self->_package_capitalization($elem);
    }

    if (
        $elem->isa('PPI::Statement::Compound') and $elem->type() eq 'foreach'
    ) {
        return $self->_foreach_variable_capitalization($elem);
    }

    if ( $elem->isa('PPI::Token::Label') ) {
        return $self->_label_capitalization($elem);
    }

    return;
}

sub _variable_capitalization {
    my ($self, $elem) = @_;

    my @violations;

    NAME:
    for my $name ( map { $_->symbol() } $elem->symbols() ) {
        if ($elem->type() eq 'local') {
            # Fully qualified names are exempt because we can't be responsible
            # for other people's symbols.
            next NAME if $name =~ m/$PACKAGE_REGEX/xms;
            next NAME if is_perl_global($name);

            push
                @violations,
                $self->_check_capitalization(
                    symbol_without_sigil($name),
                    $name,
                    'global_variable',
                    $elem,
                );
        }
        elsif ($elem->type() eq 'our') {
            push
                @violations,
                $self->_check_capitalization(
                    symbol_without_sigil($name),
                    $name,
                    'global_variable',
                    $elem,
                );
        }
        else {
            # Got my or state
            my $parent = $elem->parent();
            if ( not $parent or $parent->isa('PPI::Document') ) {
                push
                    @violations,
                    $self->_check_capitalization(
                        symbol_without_sigil($name),
                        $name,
                        'file_lexical_variable',
                        $elem,
                    );
            }
            else {
                if ( _is_directly_in_scope_block($elem) ) {
                    push
                        @violations,
                        $self->_check_capitalization(
                            symbol_without_sigil($name),
                            $name,
                            'scoped_lexical_variable',
                            $elem,
                        );
                }
                else {
                    push
                        @violations,
                        $self->_check_capitalization(
                            symbol_without_sigil($name),
                            $name,
                            'local_lexical_variable',
                            $elem,
                        );
                }
            }
        }
    }

    return @violations;
}

sub _subroutine_capitalization {
    my ($self, $elem) = @_;

    # These names are fixed and you've got no choice what to call them.
    return if $elem->isa('PPI::Statement::Scheduled');

    my $name = $elem->name();
    $name =~ s{ .* :: }{}smx;  # Allow for "sub Some::Package::foo {}"

    return $self->_check_capitalization($name, $name, 'subroutine', $elem);
}

sub _constant_capitalization {
    my ($self, $elem, $name) = @_;

    return $self->_check_capitalization(
        symbol_without_sigil($name), $name, 'constant', $elem,
    );
}

sub _package_capitalization {
    my ($self, $elem) = @_;

    my $namespace = $elem->namespace();
    my @components = split m/::/xms, $namespace;

    foreach my $component (@components) {
        my $violation =
            $self->_check_capitalization(
                $component, $namespace, 'package', $elem,
            );
        return $violation if $violation;
    }

    return;
}

sub _foreach_variable_capitalization {
    my ($self, $elem) = @_;

    my $type;
    my $symbol;
    my $second_element = $elem->schild(1);
    return if not $second_element;

    if ($second_element->isa('PPI::Token::Word')) {
        $type = $second_element->content();
        $symbol = $second_element->snext_sibling();
    } else {
        $type = 'my';
        $symbol = $second_element;
    }

    return if not $symbol;
    return if not $symbol->isa('PPI::Token::Symbol');

    my $name = $symbol->symbol();

    if ($type eq 'local') {
        # Fully qualified names are exempt because we can't be responsible
        # for other people's symbols.
        return if $name =~ m/$PACKAGE_REGEX/xms;
        return if is_perl_global($name);

        return $self->_check_capitalization(
            symbol_without_sigil($name), $name, 'global_variable', $elem,
        );
    }
    elsif ($type eq 'our') {
        return $self->_check_capitalization(
            symbol_without_sigil($name), $name, 'global_variable', $elem,
        );
    }

    # Got my or state: treat as local lexical variable
    return $self->_check_capitalization(
        symbol_without_sigil($name), $name, 'local_lexical_variable', $elem,
    );
}

sub _label_capitalization {
    my ($self, $elem, $name) = @_;

    return if _is_not_real_label($elem);
    ( my $label = $elem->content() ) =~ s< \s* : \z ><>xms;
    return $self->_check_capitalization($label, $label, 'label', $elem);
}

sub _check_capitalization {
    my ($self, $to_match, $full_name, $name_type, $elem) = @_;

    my $test = $self->{"_${name_type}_test"};
    if ( my $message = $test->($to_match) ) {
        return $self->violation(
            qq<$NAME_FOR_TYPE{$name_type} "$full_name" $message>,
            $EXPL,
            $elem,
        );
    }

    return;
}


# { my $x } parses as
#       PPI::Document
#           PPI::Statement::Compound
#               PPI::Structure::Block   { ... }
#                   PPI::Statement::Variable
#                       PPI::Token::Word        'my'
#                       PPI::Token::Symbol      '$x'
#                       PPI::Token::Structure   ';'
#
# Also, type() on the PPI::Statement::Compound returns "continue".  *sigh*
#
# The parameter is expected to be the PPI::Statement::Variable.
sub _is_directly_in_scope_block {
    my ($elem) = @_;


    return if is_in_subroutine($elem);

    my $parent = $elem->parent();
    return if not $parent->isa('PPI::Structure::Block');

    my $grand_parent = $parent->parent();
    return $TRUE if not $grand_parent;
    return $TRUE if $grand_parent->isa('PPI::Document');

    return if not $grand_parent->isa('PPI::Statement::Compound');

    my $type = $grand_parent->type();
    return if not $type;
    return if $type ne 'continue';

    my $great_grand_parent = $grand_parent->parent();
    return if
        $great_grand_parent and not $great_grand_parent->isa('PPI::Document');

    # Make sure we aren't really in a continue block.
    my $prior_to_grand_parent = $grand_parent->sprevious_sibling();
    return $TRUE if not $prior_to_grand_parent;
    return $TRUE if not $prior_to_grand_parent->isa('PPI::Token::Word');
    return $prior_to_grand_parent->content() ne 'continue';
}

sub _is_not_real_label {
    my $elem = shift;

    # PPI misparses part of a ternary expression as a label
    # when the token to the left of the ":" is a bareword.
    # See http://rt.cpan.org/Ticket/Display.html?id=41170
    # For example...
    #
    # $foo = $condition ? undef : 1;
    #
    # PPI thinks that "undef" is a label.  To workaround this,
    # I'm going to check that whatever PPI thinks is the label,
    # actually is the first token in the statement.  I believe
    # this should be true for all real labels.

    my $stmnt = $elem->statement() || return;
    my $first_child = $stmnt->schild(0) || return;
    return $first_child ne $elem;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords pbp perlstyle Schwern THINGY

=head1 NAME

Perl::Critic::Policy::NamingConventions::Capitalization - Distinguish different program components by case.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic> distribution.


=head1 DESCRIPTION

Conway recommends to distinguish different program components by case.

Normal subroutines, methods and variables are all in lower case.

    my $foo;            # ok
    my $foo_bar;        # ok
    sub foo {}          # ok
    sub foo_bar {}      # ok

    my $Foo;            # not ok
    my $foo_Bar;        # not ok
    sub Foo     {}      # not ok
    sub foo_Bar {}      # not ok

Package and class names are capitalized.

    package IO::Thing;     # ok
    package Web::FooBar    # ok

    package foo;           # not ok
    package foo::Bar;      # not ok

Constants are in all-caps.

    Readonly::Scalar my $FOO = 42;  # ok

    Readonly::Scalar my $foo = 42;  # not ok

There are other opinions on the specifics, for example, in
L<perlstyle|perlstyle>.  This
policy can be configured to match almost any style that you can think of.


=head1 CONFIGURATION

You can specify capitalization rules for the following things:
C<packages>, C<subroutines>, C<local_lexical_variables>,
C<scoped_lexical_variables>, C<file_lexical_variables>,
C<global_variables>, C<constants>, and C<labels>.

C<constants> are things declared via L<constant|constant> or
L<Readonly|Readonly>.

    use constant FOO => 193;
    Readonly::Array my @BAR => qw< a b c >;

C<global_variables> are anything declared using C<local>, C<our>, or
L<vars|vars>.  C<file_lexical_variables> are variables declared at the
file scope.

C<scoped_lexical_variables> are variables declared inside bare blocks
that are outside of any subroutines or other control structures; these
are usually created to limit scope of variables to a given subset of
subroutines.  E.g.

    sub foo { ... }

    {
        my $thingy;

        sub bar { ... $thingy ... }
        sub baz { ... $thingy ... }
    }

All other variable declarations are considered
C<local_lexical_variables>.

Each of the C<packages>, C<subroutines>, C<local_lexical_variables>,
C<scoped_lexical_variables>, C<file_lexical_variables>,
C<global_variables>, C<constants>, and C<labels> options can be
specified as one of C<:single_case>, C<:all_lower>, C<:all_upper:>,
C<:starts_with_lower>, C<:starts_with_upper>, or C<:no_restriction> or
a regular expression; any value that does not start with a colon,
C<:>, is considered to be a regular expression.  The C<:single_case>
tag means a name can be all lower case or all upper case.  If a
regular expression is specified, it is surrounded by C<\A> and C<\z>.

C<packages> defaults to C<:starts_with_upper>.  C<subroutines>,
C<local_lexical_variables>, C<scoped_lexical_variables>,
C<file_lexical_variables>, and C<global_variables> default to
C<:single_case>.  And C<constants> and C<labels> default to
C<:all_upper>.

There are corresponding C<package_exemptions>,
C<subroutine_exemptions>, C<local_lexical_variable_exemptions>,
C<scoped_lexical_variable_exemptions>,
C<file_lexical_variable_exemptions>, C<global_variable_exemptions>,
C<constant_exemptions>, and C<label_exemptions> options that are lists
of regular expressions to exempt from the corresponding capitalization
rule.  These values also end up being surrounded by C<\A> and C<\z>.

C<package_exemptions> defaults to C<main>.  C<global_variable_exemptions>
defaults to
C<\$VERSION @ISA @EXPORT(?:_OK)? %EXPORT_TAGS \$AUTOLOAD %ENV %SIG \$TODO>.
C<subroutine_exemptions> defaults to
C<AUTOLOAD BUILD BUILDARGS CLEAR CLOSE DELETE DEMOLISH DESTROY EXISTS EXTEND FETCH FETCHSIZE FIRSTKEY GETC NEXTKEY POP PRINT PRINTF PUSH READ READLINE SCALAR SHIFT SPLICE STORE STORESIZE TIEARRAY TIEHANDLE TIEHASH TIESCALAR UNSHIFT UNTIE WRITE>
which should cover all the standard Perl subroutines plus those from
L<Moose|Moose>.

For example, if you want all local variables to be in all lower-case
and global variables to start with "G_" and otherwise not contain
underscores, but exempt any variable with a name that contains
"THINGY", you could put the following in your F<.perlcriticrc>:

    [NamingConventions::Capitalization]
    local_lexical_variables = :all_lower
    global_variables = G_(?:(?!_)\w)+
    global_variable_exemptions = .*THINGY.*


=head1 TODO

Handle C<use vars>.  Treat constant subroutines like constant
variables.  Handle bareword file handles.  There needs to be "schemes"
or ways of specifying "perlstyle" or "pbp".  Differentiate lexical
L<Readonly|Readonly> constants in scopes.


=head1 BUGS

This policy won't catch problems with the declaration of C<$y> below:

    for (my $x = 3, my $y = 5; $x < 57; $x += 3) {
        ...
    }


=head1 AUTHOR

Multiple people


=head1 COPYRIGHT

Copyright (c) 2008-2011 Michael G Schwern.  All rights reserved.

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
