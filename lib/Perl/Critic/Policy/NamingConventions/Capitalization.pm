##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::NamingConventions::Capitalization;

use 5.006001;
use strict;
use warnings;

use English qw< -no_match_vars >;
use Readonly;

use B::Keywords qw< >;
use List::MoreUtils qw< any >;

use Perl::Critic::Exception::AggregateConfiguration;
use Perl::Critic::Exception::Configuration::Option::Policy::ParameterValue;
use Perl::Critic::Utils qw< :booleans :characters :severities >;
use Perl::Critic::Utils::PPI qw<
    is_in_subroutine
    get_constant_name_element_from_declaring_statement
>;

use base 'Perl::Critic::Policy';

our $VERSION = '1.093_01';

#-----------------------------------------------------------------------------

# Don't worry about leading digits-- let perl/PPI do that.
Readonly::Scalar my $ALL_ONE_CASE_REGEX      =>
    qr< \A [@%\$]? (?: [[:lower:]_\d]+ | [[:upper:]_\d]+ ) \z >xms;
Readonly::Scalar my $ALL_LOWER_REGEX         => qr< \A [@%\$]? [[:lower:]_\d]+ \z >xms;
Readonly::Scalar my $ALL_UPPER_REGEX         => qr< \A [@%\$]? [[:upper:]_\d]+ \z >xms;
Readonly::Scalar my $STARTS_WITH_LOWER_REGEX => qr< \A [@%\$]? _? [[:lower:]]     >xms;
Readonly::Scalar my $STARTS_WITH_UPPER_REGEX => qr< \A [@%\$]? _? [[:upper:]]     >xms;
Readonly::Scalar my $NO_RESTRICTION_REGEX    => qr< .                             >xms;

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
);

Readonly::Scalar my $EXPL                   => [ 45 ];

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
            description        => 'Package names that are exempt from capitalization rules.  The values here are regexes.',
            default_string     => 'main',
            behavior           => 'string list',
        },
        {
            name               => 'subroutines',
            description        => 'How subroutine names should be capitalized.  Valid values are :single_case, :all_lower, :all_upper, :starts_with_lower, :starts_with_upper, :no_restriction, or a regex.',
            default_string     => ':all_lower',
            behavior           => 'string',
        },
        {
            name               => 'subroutine_exemptions',
            description        => 'Subroutine names that are exempt from capitalization rules.  The values here are regexes.',
            default_string     => 'AUTOLOAD CLEAR CLOSE DELETE DESTROY EXISTS EXTEND FETCH FETCHSIZE FIRSTKEY GETC NEXTKEY POP PRINT PRINTF PUSH READ READLINE SCALAR SHIFT SPLICE STORE STORESIZE TIEARRAY TIEHANDLE TIEHASH TIESCALAR UNSHIFT UNTIE WRITE',
            behavior           => 'string list',
        },
        {
            name               => 'local_lexical_variables',
            description        => 'How local lexical variables names should be capitalized.  Valid values are :single_case, :all_lower, :all_upper, :starts_with_lower, :starts_with_upper, :no_restriction, or a regex.',
            default_string     => ':all_lower',
            behavior           => 'string',
        },
        {
            name               => 'local_lexical_variable_exemptions',
            description        => 'Local lexical variable names that are exempt from capitalization rules.  The values here are regexes.',
            default_string     => $EMPTY,
            behavior           => 'string list',
        },
        {
            name               => 'scoped_lexical_variables',
            description        => 'How lexical variables that are scoped to a subset of subroutines, should be capitalized.  Valid values are :single_case, :all_lower, :all_upper, :starts_with_lower, :starts_with_upper, :no_restriction, or a regex.',
            default_string     => ':all_lower',
            behavior           => 'string',
        },
        {
            name               => 'scoped_lexical_variable_exemptions',
            description        => 'Names for variables in anonymous blocks that are exempt from capitalization rules.  The values here are regexes.',
            default_string     => $EMPTY,
            behavior           => 'string list',
        },
        {
            name               => 'file_lexical_variables',
            description        => 'How lexical variables at the file level should be capitalized.  Valid values are :single_case, :all_lower, :all_upper, :starts_with_lower, :starts_with_upper, :no_restriction, or a regex.',
            default_string     => ':all_lower',
            behavior           => 'string',
        },
        {
            name               => 'file_lexical_variable_exemptions',
            description        => 'File-scope lexical variable names that are exempt from capitalization rules.  The values here are regexes.',
            default_string     => $EMPTY,
            behavior           => 'string list',
        },
        {
            name               => 'global_variables',
            description        => 'How global (package) variables should be capitalized.  Valid values are :single_case, :all_lower, :all_upper, :starts_with_lower, :starts_with_upper, :no_restriction, or a regex.',
            default_string     => ':all_lower',  # Matches ProhibitMixedCase*
            behavior           => 'string',
        },
        {
            name               => 'global_variable_exemptions',
            description        => 'Global variable names that are exempt from capitalization rules.  The values here are regexes.',
            default_string     => '\$VERSION @ISA @EXPORT(?:_OK)? %EXPORT_TAGS \$AUTOLOAD %ENV %SIG',  ## no critic (RequireInterpolation)
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
            description        => 'Constant names that are exempt from capitalization rules.  The values here are regexes.',
            default_string     => $EMPTY,
            behavior           => 'string list',
        },
    );
}

sub default_severity    { return $SEVERITY_LOWEST           }
sub default_themes      { return qw< core pbp cosmetic >    }
sub applies_to          { return 'PPI::Statement'           }

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
        constant
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
        my $name = get_constant_name_element_from_declaring_statement($elem)
    ) {
        return $self->_constant_capitalization($elem, $name);
    }

    if ( $elem->isa('PPI::Statement::Package') ) {
        return $self->_package_capitalization($elem);
    }

    return;
}

sub _variable_capitalization {
    my ($self, $elem) = @_;

    my @violations;

    NAME:
    for my $name (
        map { $_->symbol() } _ppi_statement_variable_symbols($elem)
    ) {
        if ($elem->type() eq 'local') {
            # Fully qualified names are exempt because we can't be responsible
            # for other people's sybols.
            next NAME if $name =~ m/$PACKAGE_REGEX/xms;
            next NAME if any { $_ eq $name } @B::Keywords::Symbols;  ## no critic (ProhibitPackageVars)

            push
                @violations,
                $self->_check_capitalization(
                    $name, $name, 'global_variable', $elem,
                );
        }
        elsif ($elem->type() eq 'our') {
            push
                @violations,
                $self->_check_capitalization(
                    $name, $name, 'global_variable', $elem,
                );
        }
        else {
            # Got my or state
            my $parent = $elem->parent();
            if ( not $parent or $parent->isa('PPI::Document') ) {
                push
                    @violations,
                    $self->_check_capitalization(
                        $name, $name, 'file_lexical_variable', $elem,
                    );
            }
            else {
                my $grand_parent;
                if (
                        not is_in_subroutine($elem)
                    and $parent->isa('PPI::Structure::Block')
                    and (
                            not ( $grand_parent = $parent->parent() )
                        or  $grand_parent->isa('PPI::Document')
                    )
                ) {
                    push
                        @violations,
                        $self->_check_capitalization(
                            $name, $name, 'scoped_lexical_variable', $elem,
                        );
                }
                else {
                    push
                        @violations,
                        $self->_check_capitalization(
                            $name, $name, 'local_lexical_variable', $elem,
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

    return $self->_check_capitalization($name, $name, 'subroutine', $elem);
}

sub _constant_capitalization {
    my ($self, $elem, $name) = @_;

    return $self->_check_capitalization($name, $name, 'constant', $elem);
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


# This code taken from unreleased PPI.  Delete this once next version of PPI
# is released.  "$self" is not this Policy, but a PPI::Statement::Variable.
sub _ppi_statement_variable_symbols {
    my $self = shift;

    # Get the children we care about
    my @schild = grep { $_->significant } $self->children;
    if ($schild[0]->isa('PPI::Token::Label')) { shift @schild; }

    # If the second child is a symbol, return its name
    if ( $schild[1]->isa('PPI::Token::Symbol') ) {
        return $schild[1];
    }

    # If it's a list, return as a list
    if ( $schild[1]->isa('PPI::Structure::List') ) {
        my $expression = $schild[1]->schild(0);
        $expression and
        $expression->isa('PPI::Statement::Expression') or return ();

        # my and our are simpler than local
        if (
                $self->type eq 'my'
            or  $self->type eq 'our'
            or  $self->type eq 'state'
        ) {
            return
                grep { $_->isa('PPI::Token::Symbol') }
                $expression->schildren;
        }

        # Local is much more icky (potentially).
        # Not that we are actually going to deal with it now,
        # but having this seperate is likely going to be needed
        # for future bug reports about local() things.

        # This is a slightly better way to check.
        return
            grep { $self->_local_variable($_)    }
            grep { $_->isa('PPI::Token::Symbol') }
            $expression->schildren;
    }

    # erm... this is unexpected
    return ();
}

sub _local_variable {
    my ($self, $el) = @_;

    # The last symbol should be a variable
    my $n = $el->snext_sibling or return 1;
    my $p = $el->sprevious_sibling;
    if ( !$p || $p eq $COMMA ) {
        # In the middle of a list
        return 1 if $n eq $COMMA;

        # The first half of an assignment
        return 1 if $n eq $EQUAL;
    }

    # Lets say no for know... additional work
    # should go here.
    return $EMPTY;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords Schwern

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


=head1 CONFIGURATION

You can specify capitalization rules for the following things:
C<packages>, C<subroutines>, C<local_lexical_variables>,
C<scoped_lexical_variables>, C<file_lexical_variables>,
C<global_variables>, and C<constants>.

C<constants> are things declared via L<constant|constant> or
L<Readonly|Readonly>.

    use constant FOO => 193;
    Readonly::Array my @BAR => qw< a b c >;

C<global_variables> are anything declared using C<local> or C<our>.
C<file_lexical_variables> are variables declared at the file scope.

C<scoped_lexical_variables> are variables declared inside bare blocks that
are outside of any subroutines or other control structures; these are
usually created to limit scope of variables to a given subset of
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
C<global_variables>, and C<constants> options can be specified as one
of C<:single_case>, C<:all_lower>, C<:all_upper:>,
C<:starts_with_lower>, C<:starts_with_upper>, or C<:no_restriction> or
a regular expression.  The C<:single_case> tag means a name can be all
lower case or all upper case.  If a regular expression is specified,
it is surrounded by C<\A> and C<\z>.

C<packages> defaults to C<:starts_with_upper>.  C<subroutines>,
C<local_lexical_variables>, C<scoped_lexical_variables>,
C<file_lexical_variables>, and C<global_variables> default to
C<:all_lower>.  And C<constants> defaults to C<:all_upper>.

There are corresponding C<package_exemptions>,
C<subroutine_exemptions>, C<local_lexical_variable_exemptions>,
C<scoped_lexical_variable_exemptions>,
C<file_lexical_variable_exemptions>, C<global_variable_exemptions>,
and C<constant_exemptions> options that are lists of regular
expressions to exempt from the corresponding capitalization rule.
These values also end up being surrounded by C<\A> and C<\z>.

C<package_exemptions> defaults to C<main>.
C<global_variable_exemptions> defaults to C<\$VERSION @ISA
@EXPORT(?:_OK)? %EXPORT_TAGS>.


=head1 TODO

Handle C<use vars>.  Treat constant subroutines like constant
variables.


=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>


=head1 COPYRIGHT

Copyright (c) 2008 Michael G Schwern.  All rights reserved.

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
