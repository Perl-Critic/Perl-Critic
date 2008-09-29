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
Readonly::Scalar my $ALL_LOWER_REGEX         => qr/ \A [@%\$]? [[:lower:]_\d]+ \z /xms;
Readonly::Scalar my $ALL_UPPER_REGEX         => qr/ \A [@%\$]? [[:upper:]_\d]+ \z /xms;
Readonly::Scalar my $STARTS_WITH_LOWER_REGEX => qr/ \A [@%\$]? _? [[:lower:]]     /xms;
Readonly::Scalar my $STARTS_WITH_UPPER_REGEX => qr/ \A [@%\$]? _? [[:upper:]]     /xms;
Readonly::Scalar my $NO_RESTRICTION_REGEX    => qr/ .                            /xms;

Readonly::Hash my %CAPITALIZATION_SCHEME_TAGS    => (
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

Readonly::Scalar my $EXPL                   => [ 45 ];

#-----------------------------------------------------------------------------

# Can't handle named parameters yet.
sub supported_parameters {
    return (
        {
            name               => 'packages',
            description        => 'How package names should be capitalized.  Valid values are :all_lower, :all_upper:, :starts_with_lower, :starts_with_upper, :no_restriction, or a regex.',
            default_string     => ':starts_with_upper',
            behavior           => 'string',
        },
        {
            name               => 'package_exemptions',
            description        => 'Package names that are exempt from capitalization rules.  The values here are regexes.',
            default_string     => $EMPTY,
            behavior           => 'string list',
        },
        {
            name               => 'subroutines',
            description        => 'How subroutine names should be capitalized.  Valid values are :all_lower, :all_upper:, :starts_with_lower, :starts_with_upper, :no_restriction, or a regex.',
            default_string     => ':all_lower',
            behavior           => 'string',
        },
        {
            name               => 'subroutine_exemptions',
            description        => 'Subroutine names that are exempt from capitalization rules.  The values here are regexes.',
            default_string     => $EMPTY,
            behavior           => 'string list',
        },
        {
            name               => 'local_lexical_variables',
            description        => 'How local lexical variables names should be capitalized.  Valid values are :all_lower, :all_upper:, :starts_with_lower, :starts_with_upper, :no_restriction, or a regex.',
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
            description        => 'How lexical variables that are scoped to a subset of subroutines, should be capitalized.  Valid values are :all_lower, :all_upper:, :starts_with_lower, :starts_with_upper, :no_restriction, or a regex.',
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
            description        => 'How lexical variables at the file level should be capitalized.  Valid values are :all_lower, :all_upper:, :starts_with_lower, :starts_with_upper, :no_restriction, or a regex.',
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
            description        => 'How global (package) variables should be capitalized.  Valid values are :all_lower, :all_upper:, :starts_with_lower, :starts_with_upper, :no_restriction, or a regex.',
            default_string     => ':all_lower',  # Matches ProhibitMixedCase*
            behavior           => 'string',
        },
        {
            name               => 'global_variable_exemptions',
            description        => 'Global variable names that are exempt from capitalization rules.  The values here are regexes.',
            default_string     => '\$VERSION @ISA @EXPORT(?:_OK)? %EXPORT_TAGS',
            behavior           => 'string list',
        },
        {
            name               => 'constants',
            description        => 'How constant names should be capitalized.
            Valid values are :all_lower, :all_upper:, :starts_with_lower,
            :starts_with_upper, :no_restriction, or a regex.',
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
    for my $name ( $elem->variables() ) {
        if ($elem->type() eq 'local') {
            # Fully qualified names are exempt because we can't be responsible
            # for other people's sybols.
            next NAME if $name =~ m/$PACKAGE_REGEX/xms;
            next NAME if any { $_ eq $name } @B::Keywords::Symbols;

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
        return $self->violation("$full_name $message", $EXPL, $elem);
    }

    return;
}

1;

__END__

#-----------------------------------------------------------------------------

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

This Policy is not configurable except for the standard options.


=head1 BUGS

The policy cannot currently tell that a variable is being declared as
a constant, thus any variable may be made all-caps.


=head1 SEE ALSO

To control use of camelCase see
L<Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseSubs|Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseSubs>
and
L<Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseVars|Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseVars>.


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
