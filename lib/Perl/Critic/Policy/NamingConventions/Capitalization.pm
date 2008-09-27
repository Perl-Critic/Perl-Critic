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

use Readonly;

use Perl::Critic::Utils qw{ :severities };
use Perl::Critic::Exception::Fatal::Internal qw{ throw_internal };

use base 'Perl::Critic::Policy';

our $VERSION = '1.093_01';

#-----------------------------------------------------------------------------

# Don't worry about leading digits-- let perl/PPI do that.
Readonly::Scalar my $ALL_LOWER_REGEX         => qr/ \A [[:lower:]_\d]+ \z /xms;
Readonly::Scalar my $ALL_UPPER_REGEX         => qr/ \A [[:upper:]_\d]+ \z /xms;
Readonly::Scalar my $STARTS_WITH_LOWER_REGEX => qr/ \A [[:lower:]_]       /xms;
Readonly::Scalar my $STARTS_WITH_UPPER_REGEX => qr/ \A [[:upper:]_]       /xms;
Readonly::Scalar my $NO_RESTRICTION_REGEX    => qr/ .                     /xms;

Readonly::Hash my %CAPITALIZATION_SCHEMES    => (
    all_lower           => {
        regex       => $ALL_LOWER_REGEX,
        description => 'is not all lower case',
    },
    all_upper           => {
        regex       => $ALL_UPPER_REGEX,
        description => 'is not all upper case',
    },
    starts_with_lower   => {
        regex       => $STARTS_WITH_LOWER_REGEX,
        description => 'does not start with a lower case letter',
    },
    starts_with_upper   => {
        regex       => $STARTS_WITH_UPPER_REGEX,
        description => 'does not start with a upper case letter',
    },
    no_restriction      => {
        regex       => $NO_RESTRICTION_REGEX,
        description => 'there is a bug in Perl::Critic if you are reading this',
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
            description        => 'How package names should be capitalized.',
            default_string     => 'starts_with_upper',
            behavior           => 'enumeration',
            enumeration_values => [ sort keys %CAPITALIZATION_SCHEMES ],
            enumeration_allow_multiple_values => 0,
        },
        {
            name               => 'subroutines',
            description        => 'How subroutine names should be capitalized.',
            default_string     => 'all_lower',
            behavior           => 'enumeration',
            enumeration_values => [ sort keys %CAPITALIZATION_SCHEMES ],
            enumeration_allow_multiple_values => 0,
        },
        {
            name               => 'local_lexical_variables',
            description        => 'How local lexical variables names should be capitalized.',
            default_string     => 'all_lower',
            behavior           => 'enumeration',
            enumeration_values => [ sort keys %CAPITALIZATION_SCHEMES ],
            enumeration_allow_multiple_values => 0,
        },
        {
            name               => 'non_subroutine_lexical_variables',
            description        => 'How lexical variables outside of subroutines should be capitalized.',
            default_string     => 'all_lower',
            behavior           => 'enumeration',
            enumeration_values => [ sort keys %CAPITALIZATION_SCHEMES ],
            enumeration_allow_multiple_values => 0,
        },
        {
            name               => 'global_variables',
            description        => 'How global (package) variables should be capitalized.',
            default_string     => 'all_lower',  # Matches ProhibitMixedCase*
            behavior           => 'enumeration',
            enumeration_values => [ sort keys %CAPITALIZATION_SCHEMES ],
            enumeration_allow_multiple_values => 0,
        },
        {
            name               => 'constants',
            description        => 'How constant names should be capitalized.',
            default_string     => 'all_upper',
            behavior           => 'enumeration',
            enumeration_values => [ sort keys %CAPITALIZATION_SCHEMES ],
            enumeration_allow_multiple_values => 0,
        },
    )
}

sub default_severity     { return $SEVERITY_LOWEST              }
sub default_themes       { return qw( core pbp cosmetic )       }

sub applies_to {
    return
        'PPI::Statement::Variable',
        'PPI::Statement::Package',
        'PPI::Statement::Sub';
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    my @violations;
    if ( $elem->isa('PPI::Statement::Variable') ) {
        @violations = $self->_variable_capitalization($elem);
    }
    elsif ( $elem->isa('PPI::Statement::Package') ) {
        @violations = $self->_package_capitalization($elem);
    }
    elsif ( $elem->isa('PPI::Statement::Sub') ) {
        @violations = $self->_subroutine_capitalization($elem);
    }
    else {
        throw_internal 'Should never reach this point';
    }

    return @violations;
}

sub _variable_capitalization {
    my ($self, $elem) = @_;

    my @violations;
    for my $name ( $elem->variables() ) {
        # Fully qualified names are exempt because we can't be responsible for
        # other people's sybols.
        next if $elem->type() eq 'local' && $name =~ m/$PACKAGE_REGEX/xms;

    }

    return @violations;
}

sub _package_capitalization {
    my ($self, $elem) = @_;

    my $namespace = $elem->namespace();
    my @components = split m/::/xms, $namespace;

    foreach my $component (@components) {
        my $violation =
            $self->_check_capitalization(
                $component, $component, 'packages', $elem,
            );
        return $violation if $violation;
    }

    return;
}

sub _subroutine_capitalization {
    my ($self, $elem) = @_;

    my $name = $elem->name();

    return $self->_check_capitalization($name, $name, 'subroutines', $elem);
}

sub _check_capitalization {
    my ($self, $to_match, $full_name, $name_type, $elem) = @_;

    my $scheme_name = $self->{"_$name_type"};
    my $scheme = $CAPITALIZATION_SCHEMES{$scheme_name};
    my ($regex, $description) = @{$scheme}{ qw< regex description > };

    if ($to_match !~ m/$regex/xms) {
        return $self->violation("$full_name $description", $EXPL, $elem);
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
