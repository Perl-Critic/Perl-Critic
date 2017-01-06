package Perl::Critic::Policy::Modules::ProhibitEvilModules;

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);
use Readonly;

use Perl::Critic::Exception::Configuration::Option::Policy::ParameterValue
    qw{ throw_policy_value };
use Perl::Critic::Utils qw{
    :booleans :characters :severities :data_conversion
};

use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL => q{Find an alternative module};

Readonly::Scalar my $MODULE_NAME_REGEX =>
    qr<
        \b
        [[:alpha:]_]
        (?:
            (?: \w | :: )*
            \w
        )?
        \b
    >xms;
Readonly::Scalar my $REGULAR_EXPRESSION_REGEX => qr< [/] ( [^/]+ ) [/] >xms;
Readonly::Scalar my $DESCRIPTION_REGEX => qr< [{] ( [^}]+ ) [}] >xms;

# It's kind of unfortunate that I had to put capturing parentheses in the
# component regexes above, because they're not visible here and so make
# figuring out the positions of captures hard.  Too bad we can't make the
# minimum perl version 5.10. :]
Readonly::Scalar my $MODULES_REGEX =>
    qr<
        \A
        \s*
        (?:
                ( $MODULE_NAME_REGEX )
            |   $REGULAR_EXPRESSION_REGEX
        )
        (?: \s* $DESCRIPTION_REGEX )?
        \s*
    >xms;

Readonly::Scalar my $MODULES_FILE_LINE_REGEX =>
    qr<
        \A
        \s*
        (?:
                ( $MODULE_NAME_REGEX )
            |   $REGULAR_EXPRESSION_REGEX
        )
        \s*
        ( \S (?: .* \S )? )?
        \s*
        \z
    >xms;

Readonly::Scalar my $DEFAULT_MODULES =>
    join
        $SPACE,
        map { "$_ {Found use of $_. This module is deprecated by the Perl 5 Porters.}" }
            qw< Class::ISA Pod::Plainer Shell Switch >;

# Indexes in the arrays of regexes for the "modules" option.
Readonly::Scalar my $INDEX_REGEX        => 0;
Readonly::Scalar my $INDEX_DESCRIPTION  => 1;

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'modules',
            description     => 'The names of or patterns for modules to forbid.',
            default_string  => $DEFAULT_MODULES,
            parser          => \&_parse_modules,
        },
        {
            name            => 'modules_file',
            description     => 'A file containing names of or patterns for modules to forbid.',
            default_string  => $EMPTY,
            parser          => \&_parse_modules_file,
        },
    );
}

sub default_severity  { return $SEVERITY_HIGHEST         }
sub default_themes    { return qw( core bugs certrule )           }
sub applies_to        { return 'PPI::Statement::Include' }

#-----------------------------------------------------------------------------

sub _parse_modules {
    my ($self, $parameter, $config_string) = @_;

    my $module_specifications =
        defined $config_string
            ? $config_string
            : $parameter->get_default_string();

    return if not $module_specifications;
    return if $module_specifications =~ m< \A \s* \z >xms;

    while ( $module_specifications =~ s< $MODULES_REGEX ><>xms ) {
        my ($module, $regex_string, $description) = ($1, $2, $3);

        $self->_handle_module_specification(
            module                  => $module,
            regex_string            => $regex_string,
            description             => $description,
            option_name             => 'modules',
            option_value            => $config_string,
        );
    }

    if ($module_specifications) {
        throw_policy_value
            policy         => $self->get_short_name(),
            option_name    => 'modules',
            option_value   => $config_string,
            message_suffix =>
                qq{contains unparseable data: "$module_specifications"};
    }

    return;
}

sub _parse_modules_file {
    my ($self, $parameter, $config_string) = @_;

    return if not $config_string;
    return if $config_string =~ m< \A \s* \z >xms;

    open my $handle, '<', $config_string
        or throw_policy_value
            policy         => $self->get_short_name(),
            option_name    => 'modules_file',
            option_value   => $config_string,
            message_suffix =>
                qq<refers to a file that could not be opened: $OS_ERROR>;
    while ( my $line = <$handle> ) {
        $self->_handle_module_specification_on_line($line, $config_string);
    }
    close $handle or warn qq<Could not close "$config_string": $OS_ERROR\n>;

    return;
}

sub _handle_module_specification_on_line {
    my ($self, $line, $config_string) = @_;

    $line =~ s< [#] .* \z ><>xms;
    $line =~ s< \s+ \z ><>xms;
    $line =~ s< \A \s+ ><>xms;

    return if not $line;

    if ( $line =~ s< $MODULES_FILE_LINE_REGEX ><>xms ) {
        my ($module, $regex_string, $description) = ($1, $2, $3);

        $self->_handle_module_specification(
            module                  => $module,
            regex_string            => $regex_string,
            description             => $description,
            option_name             => 'modules_file',
            option_value            => $config_string,
        );
    }
    else {
        throw_policy_value
            policy         => $self->get_short_name(),
            option_name    => 'modules_file',
            option_value   => $config_string,
            message_suffix =>
                qq{contains unparseable data: "$line"};
    }

    return;
}

sub _handle_module_specification {
    my ($self, %arguments) = @_;

    my $description = $arguments{description} || $EMPTY;

    if ( my $regex_string = $arguments{regex_string} ) {
        # These are module name patterns (e.g. /Acme/)
        my $actual_regex;

        eval { $actual_regex = qr/$regex_string/; 1 }  ## no critic (ExtendedFormatting, LineBoundaryMatching, DotMatchAnything)
            or throw_policy_value
                policy         => $self->get_short_name(),
                option_name    => $arguments{option_name},
                option_value   => $arguments{option_value},
                message_suffix =>
                    qq{contains an invalid regular expression: "$regex_string"};

        # Can't use a hash due to stringification, so this is an AoA.
        $self->{_evil_modules_regexes} ||= [];

        push
            @{ $self->{_evil_modules_regexes} },
            [ $actual_regex, $description ];
    }
    else {
        # These are literal module names (e.g. Acme::Foo)
        $self->{_evil_modules} ||= {};
        $self->{_evil_modules}{ $arguments{module} } = $description;
    }

    return;
}

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    my ($self, $config) = @_;

    # Disable if no modules are specified; there's no point in running if
    # there aren't any.
    return
            exists $self->{_evil_modules}
        ||  exists $self->{_evil_modules_regexes};
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    my $module = $elem->module();
    return if not $module;

    my $evil_modules = $self->{_evil_modules};
    my $evil_modules_regexes = $self->{_evil_modules_regexes};
    my $description;

    if ( exists $evil_modules->{$module} ) {
        $description = $evil_modules->{ $module };
    }
    else {
        REGEX:
        foreach my $regex ( @{$evil_modules_regexes} ) {
            if ( $module =~ $regex->[$INDEX_REGEX] ) {
                $description = $regex->[$INDEX_DESCRIPTION];
                last REGEX;
            }
        }
    }

    if (defined $description) {
        $description ||= qq<Prohibited module "$module" used>;

        return $self->violation( $description, $EXPL, $elem );
    }

    return;    # ok!
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Modules::ProhibitEvilModules - Ban modules that aren't blessed by your shop.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Use this policy if you wish to prohibit the use of specific modules.
These may be modules that you feel are deprecated, buggy, unsupported,
insecure, or just don't like.


=head1 CONFIGURATION

The set of prohibited modules is configurable via the C<modules> and
C<modules_file> options.

The value of C<modules> should be a string of space-delimited, fully
qualified module names and/or regular expressions.  An example of
prohibiting two specific modules in a F<.perlcriticrc> file:

    [Modules::ProhibitEvilModules]
    modules = Getopt::Std Autoload

Regular expressions are identified by values beginning and ending with
slashes.  Any module with a name that matches C<m/pattern/> will be
forbidden.  For example:

    [Modules::ProhibitEvilModules]
    modules = /Acme::/

would cause all modules that match C<m/Acme::/> to be forbidden.

In addition, you can override the default message ("Prohibited module
"I<module>" used") with your own, in order to give suggestions for
alternative action.  To do so, put your message in curly braces after
the module name or regular expression.  Like this:

    [Modules::ProhibitEvilModules]
    modules = Fatal {Found use of Fatal. Use autodie instead} /Acme::/ {We don't use joke modules}

Similarly, the C<modules_file> option gives the name of a file
containing specifications for prohibited modules.  Only one module
specification is allowed per line and comments start with an octothorp
and run to end of line; no curly braces are necessary for delimiting
messages:

    Evil     # Prohibit the "Evil" module and use the default message.

    # Prohibit the "Fatal" module and give a replacement message.
    Fatal Found use of Fatal. Use autodie instead.

    # Use a regular expression.
    /Acme::/     We don't use joke modules.

By default, the modules that have been deprecated by the Perl 5 Porters are
reported; at the time of writing these are L<Class::ISA|Class::ISA>,
L<Pod::Plainer|Pod::Plainer>, L<Shell|Shell>, and L<Switch|Switch>.
Specifying a value for the C<modules> option will override this.


=head1 NOTES

Note that this policy doesn't apply to pragmas.


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2005-2011 Imaginative Software Systems.  All rights reserved.

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
