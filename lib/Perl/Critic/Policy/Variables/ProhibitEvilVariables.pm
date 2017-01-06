package Perl::Critic::Policy::Variables::ProhibitEvilVariables;

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);
use Readonly;

use Perl::Critic::Exception::Configuration::Option::Policy::ParameterValue
    qw{ throw_policy_value };
use Perl::Critic::Utils qw{
    :characters :severities :data_conversion
};
use Perl::Critic::Utils::DataConversion qw{ dor };

use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL => q{Find an alternative variable};

Readonly::Hash my %SUBSCRIPTED_TYPE => hashify(qw{@ %});

Readonly::Scalar my $VARIABLE_NAME_REGEX => qr< [\$\@%] \S+ >xms;
Readonly::Scalar my $REGULAR_EXPRESSION_REGEX =>
    qr< [/] ( [^/]+ ) [/] >xms;
Readonly::Array my @DESCRIPTION_REGEXES =>
    qr< [{] ( [^}]+ ) [}] >xms,
    qr{  <  ( [^>]+ )  >  }xms,
    qr{ [[] ( [^]]+ ) []] }xms,
    qr{ [(] ( [^)]+ ) [)] }xms,
;
Readonly::Scalar my $DESCRIPTION_REGEX =>
    qr< @{[join '|', @DESCRIPTION_REGEXES]} >xms;

# It's kind of unfortunate that I had to put capturing parentheses in the
# component regexes above, because they're not visible here and so make
# figuring out the positions of captures hard.  Too bad we can't make the
# minimum perl version 5.10. :]
Readonly::Scalar my $VARIABLES_REGEX =>
    qr<
        \A
        \s*
        (?:
                ( $VARIABLE_NAME_REGEX )
            |   $REGULAR_EXPRESSION_REGEX
        )
        (?: \s* $DESCRIPTION_REGEX )?
        \s*
    >xms;

Readonly::Scalar my $VARIABLES_FILE_LINE_REGEX =>
    qr<
        \A
        \s*
        (?:
                ( $VARIABLE_NAME_REGEX )
            |   $REGULAR_EXPRESSION_REGEX
        )
        \s*
        ( \S (?: .* \S )? )?
        \s*
        \z
    >xms;

# Indexes in the arrays of regexes for the "variables" option.
Readonly::Scalar my $INDEX_REGEX        => 0;
Readonly::Scalar my $INDEX_DESCRIPTION  => 1;

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'variables',
            description     => 'The names of or patterns for variables to forbid.',
            default_string  => $EMPTY,
            parser          => \&_parse_variables,
        },
        {
            name            => 'variables_file',
            description     => 'A file containing names of or patterns for variables to forbid.',
            default_string  => $EMPTY,
            parser          => \&_parse_variables_file,
        },
    );
}

sub default_severity  { return $SEVERITY_HIGHEST         }
sub default_themes    { return qw( core bugs )           }
sub applies_to        { return qw{PPI::Token::Symbol}    }

#-----------------------------------------------------------------------------

sub _parse_variables {
    my ($self, $parameter, $config_string) = @_;

    return if not $config_string;
    return if $config_string =~ m< \A \s* \z >xms;

    my $variable_specifications = $config_string;

    while ( my ($variable, $regex_string, @descrs) =
        $variable_specifications =~ m< $VARIABLES_REGEX >xms) {

        substr $variable_specifications, 0, $LAST_MATCH_END[0], $EMPTY;
        my $description = dor(@descrs);

        $self->_handle_variable_specification(
            variable                => $variable,
            regex_string            => $regex_string,
            description             => $description,
            option_name             => 'variables',
            option_value            => $config_string,
        );
    }

    if ($variable_specifications) {
        throw_policy_value
            policy         => $self->get_short_name(),
            option_name    => 'variables',
            option_value   => $config_string,
            message_suffix =>
                qq{contains unparseable data: "$variable_specifications"};
    }

    return;
}

sub _parse_variables_file {
    my ($self, $parameter, $config_string) = @_;

    return if not $config_string;
    return if $config_string =~ m< \A \s* \z >xms;

    open my $handle, '<', $config_string
        or throw_policy_value
            policy         => $self->get_short_name(),
            option_name    => 'variables_file',
            option_value   => $config_string,
            message_suffix =>
                qq<refers to a file that could not be opened: $OS_ERROR>;
    while ( my $line = <$handle> ) {
        $self->_handle_variable_specification_on_line($line, $config_string);
    }
    close $handle or warn qq<Could not close "$config_string": $OS_ERROR\n>;

    return;
}

sub _handle_variable_specification_on_line {
    my ($self, $line, $config_string) = @_;

    $line =~ s< [#] .* \z ><>xms;
    $line =~ s< \s+ \z ><>xms;
    $line =~ s< \A \s+ ><>xms;

    return if not $line;

    if ( my ($variable, $regex_string, $description) =
        $line =~ m< $VARIABLES_FILE_LINE_REGEX >xms) {

        $self->_handle_variable_specification(
            variable                => $variable,
            regex_string            => $regex_string,
            description             => $description,
            option_name             => 'variables_file',
            option_value            => $config_string,
        );
    }
    else {
        throw_policy_value
            policy         => $self->get_short_name(),
            option_name    => 'variables_file',
            option_value   => $config_string,
            message_suffix =>
                qq{contains unparseable data: "$line"};
    }

    return;
}

sub _handle_variable_specification {
    my ($self, %arguments) = @_;

    my $description = $arguments{description} || $EMPTY;

    if ( my $regex_string = $arguments{regex_string} ) {
        # These are variable name patterns (e.g. /acme/)
        my $actual_regex;

        eval { $actual_regex = qr/$regex_string/sm; ## no critic (ExtendedFormatting)
            1 }
            or throw_policy_value
                policy         => $self->get_short_name(),
                option_name    => $arguments{option_name},
                option_value   => $arguments{option_value},
                message_suffix =>
                    qq{contains an invalid regular expression: "$regex_string"};

        # Can't use a hash due to stringification, so this is an AoA.
        push
            @{ $self->{_evil_variables_regexes} ||= [] },
            [ $actual_regex, $description ];
    }
    else {
        # These are literal variable names (e.g. $[)
        $self->{_evil_variables} ||= {};
        my $name = $arguments{variable};
        $self->{_evil_variables}{$name} = $description;
    }

    return;
}

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    my ($self, $config) = @_;

    # Disable if no variables are specified; there's no point in running if
    # there aren't any.
    return
            exists $self->{_evil_variables}
        ||  exists $self->{_evil_variables_regexes};
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    return if not $elem;

    my @names = $self->_compute_symbol_names( $elem )
        or return;

    my $evil_variables = $self->{_evil_variables};
    my $evil_variables_regexes = $self->{_evil_variables_regexes};

    foreach my $variable (@names) {
        exists $evil_variables->{$variable}
            and return $self->_make_violation(
                $variable,
                $evil_variables->{$variable},
                $elem,
            );
    }

    foreach my $variable (@names) {
        foreach my $regex ( @{$evil_variables_regexes} ) {
            $variable =~ $regex->[$INDEX_REGEX]
                and return $self->_make_violation(
                    $variable,
                    $regex->[$INDEX_DESCRIPTION],
                    $elem,
                );
        }
    }

    return;    # ok!
}

#-----------------------------------------------------------------------------

# We are unconditionally interested in the names of the symbol itself. If the
# symbol is subscripted, we are interested in the subscripted form as well.

sub _compute_symbol_names {
    my ($self, $elem) = @_;

    my @names;

    my $name = $elem->symbol();
    push @names, $name;

    if ($SUBSCRIPTED_TYPE{$elem->symbol_type()}) {
        $name = $elem->content();
        my $next = $elem->snext_sibling();
        my @subscr;
        while ($next and $next->isa('PPI::Structure::Subscript')) {
            push @subscr, $next->content();
            $next = $next->snext_sibling();
        }
        if (@subscr) {
            push @names, join $EMPTY, $name, @subscr;
        }
    }

    return @names;
}

#-----------------------------------------------------------------------------

sub _make_violation {
    my ($self, $variable, $description, $elem) = @_;
    return $self->violation(
        $description || qq<Prohibited variable "$variable" used>,
        $EXPL,
        $elem,
    );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords subscripted

=head1 NAME

Perl::Critic::Policy::Variables::ProhibitEvilVariables - Ban variables that aren't blessed by your shop.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Use this policy if you wish to prohibit the use of specific variables. These
may be global variables warned against in C<perlvar>, or just variables whose
names you do not like.


=head1 CONFIGURATION

The set of prohibited variables is configurable via the C<variables> and
C<variables_file> options.

The value of C<variables> should be a string of space-delimited, fully
qualified variable names and/or regular expressions.  An example of
prohibiting two specific variables in a F<.perlcriticrc> file:

    [Variables::ProhibitEvilVariables]
    variables = $[ $^S $SIG{__DIE__}

If you prohibit an array or hash (e.g. C<@INC>), use of elements of the array
or hash will be prohibited as well. If you specify a subscripted variable (e.g.
C<$SIG{__DIE__}>), only the literal subscript specified will be detected. The
above <.perlcritic> file, for example, will cause C<perlcritic (1)> to detect
C<$SIG{__DIE__} = \&foo>, but not

    my $foo = '__DIE__';
    $SIG{$foo} = \&foo;

Regular expressions are identified by values beginning and ending with
slashes.  Any variable with a name that matches C<m/pattern/sm> will be
forbidden.  For example:

    [Variables::ProhibitEvilVariables]
    variables = /acme/

would cause all variables that match C<m/acme/> to be forbidden.  If
you want a case-blind check, you can use (?i: ... ).  For example

    [Variables::ProhibitEvilVariables]
    variables = /(?i:acme)/

forbids variables that match C<m/acme/smi>.

In addition, you can override the default message ("Prohibited variable
"I<variable>" used") with your own, in order to give suggestions for
alternative action.  To do so, put your message in curly braces after
the variable name or regular expression.  Like this:

    [Variables::ProhibitEvilVariables]
    variables = $[ {Found use of $[. Program to base index 0 instead}

If your message contains curly braces, you can enclose it in parentheses,
angle brackets, or square brackets instead.

Similarly, the C<variables_file> option gives the name of a file
containing specifications for prohibited variables.  Only one variable
specification is allowed per line and comments start with an octothorp
and run to end of line; no curly braces are necessary for delimiting
messages:

    $[      # Prohibit the "$[" variable and use the default message.

    # Prohibit the "$^S" variable and give a replacement message.
    $^S     Having to think about $^S in exception handlers is just wrong

    # Use a regular expression.
    /acme/  No coyotes allowed.

By default, there are no prohibited variables, although I can think of a
few that should be.  See C<perldoc perlvar> for a few suggestions.


=head1 RESTRICTIONS

Variables of the form C<${^foo}> are not recognized by PPI as of version
1.206. When PPI recognizes these, this policy will Just Work for them too.

Only direct references to prohibited variables and literal subscripts will be
recognized. For example, if you prohibit $[, the first line in

 my $foo = \$[;
 $$foo = 1;

will be flagged as a violation, but not the second, even though the second, in
fact, assigns to $[. Similarly, if you prohibit $SIG{__DIE__}, this policy
will not recognize

 my $foo = '__DIE__';
 $SIG{$foo} = sub {warn 'I cannot die!'};

as an assignment to $SIG{__DIE__}.


=head1 NOTES

This policy leans heavily on
L<Perl::Critic::Policy::Modules::ProhibitEvilModules|Perl::Critic::Policy::Modules::ProhibitEvilModules>
by Jeffrey Ryan Thalhammer.


=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>


=head1 COPYRIGHT

Copyright (c) 2009-2011 Thomas R. Wyant, III

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
