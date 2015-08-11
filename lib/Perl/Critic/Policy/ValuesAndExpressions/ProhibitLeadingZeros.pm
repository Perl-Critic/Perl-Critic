package Perl::Critic::Policy::ValuesAndExpressions::ProhibitLeadingZeros;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw{ :characters :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $LEADING_RX => qr<\A [+-]? (?: 0+ _* )+ [1-9]>xms;
Readonly::Scalar my $EXPL       => [ 58 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name           => 'strict',
            description    =>
                q<Don't allow any leading zeros at all.  Otherwise builtins that deal with Unix permissions, e.g. chmod, don't get flagged.>,
            default_string => '0',
            behavior       => 'boolean',
        },
    );
}

sub default_severity     { return $SEVERITY_HIGHEST           }
sub default_themes       { return qw< core pbp bugs certrec >         }
sub applies_to           { return 'PPI::Token::Number::Octal' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem !~ $LEADING_RX;
    return $self->_create_violation($elem) if $self->{_strict};
    return if $self->_is_first_argument_of_chmod_or_umask($elem);
    return if $self->_is_second_argument_of_mkdir($elem);
    return if $self->_is_third_argument_of_dbmopen($elem);
    return if $self->_is_fourth_argument_of_sysopen($elem);
    return $self->_create_violation($elem);
}

sub _create_violation {
    my ($self, $elem) = @_;

    return $self->violation(
        qq<Integer with leading zeros: "$elem">,
        $EXPL,
        $elem
    );
}

sub _is_first_argument_of_chmod_or_umask {
    my ($self, $elem) = @_;

    my $previous_token = _previous_token_that_isnt_a_parenthesis($elem);
    return if not $previous_token;

    my $content = $previous_token->content();
    return $content eq 'chmod' || $content eq 'umask';
}

sub _is_second_argument_of_mkdir {
    my ($self, $elem) = @_;

    # Preceding comma.
    my $previous_token = _previous_token_that_isnt_a_parenthesis($elem);
    return if not $previous_token;
    return if $previous_token->content() ne $COMMA;  # Don't know what it is.

    # Directory name.
    $previous_token =
        _previous_token_that_isnt_a_parenthesis($previous_token);
    return if not $previous_token;

    $previous_token =
        _previous_token_that_isnt_a_parenthesis($previous_token);
    return if not $previous_token;

    return $previous_token->content() eq 'mkdir';
}

sub _is_third_argument_of_dbmopen {
    my ($self, $elem) = @_;

    # Preceding comma.
    my $previous_token = _previous_token_that_isnt_a_parenthesis($elem);
    return if not $previous_token;
    return if $previous_token->content() ne $COMMA;  # Don't know what it is.

    # File path.
    $previous_token =
        _previous_token_that_isnt_a_parenthesis($previous_token);
    return if not $previous_token;

    # Another comma.
    $previous_token =
        _previous_token_that_isnt_a_parenthesis($previous_token);
    return if not $previous_token;
    return if $previous_token->content() ne $COMMA;  # Don't know what it is.

    # Variable name.
    $previous_token =
        _previous_token_that_isnt_a_parenthesis($previous_token);
    return if not $previous_token;

    $previous_token =
        _previous_token_that_isnt_a_parenthesis($previous_token);
    return if not $previous_token;

    return $previous_token->content() eq 'dbmopen';
}

sub _is_fourth_argument_of_sysopen {
    my ($self, $elem) = @_;

    # Preceding comma.
    my $previous_token = _previous_token_that_isnt_a_parenthesis($elem);
    return if not $previous_token;
    return if $previous_token->content() ne $COMMA;  # Don't know what it is.

    # Mode.
    $previous_token =
        _previous_token_that_isnt_a_parenthesis($previous_token);
    while ($previous_token and $previous_token->content() ne $COMMA) {
        $previous_token =
            _previous_token_that_isnt_a_parenthesis($previous_token);
    }
    return if not $previous_token;
    return if $previous_token->content() ne $COMMA;  # Don't know what it is.

    # File name.
    $previous_token =
        _previous_token_that_isnt_a_parenthesis($previous_token);
    return if not $previous_token;

    # Yet another comma.
    $previous_token =
        _previous_token_that_isnt_a_parenthesis($previous_token);
    return if not $previous_token;
    return if $previous_token->content() ne $COMMA;  # Don't know what it is.

    # File handle.
    $previous_token =
        _previous_token_that_isnt_a_parenthesis($previous_token);
    return if not $previous_token;

    $previous_token =
        _previous_token_that_isnt_a_parenthesis($previous_token);
    return if not $previous_token;

    return $previous_token->content() eq 'sysopen';
}

sub _previous_token_that_isnt_a_parenthesis {
    my ($elem) = @_;

    my $previous_token = $elem->previous_token();
    while (
            $previous_token
        and (
                not $previous_token->significant()
            or  $previous_token->content() eq $LEFT_PAREN
            or  $previous_token->content() eq $RIGHT_PAREN
        )
    ) {
        $previous_token = $previous_token->previous_token();
    }

    return $previous_token;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitLeadingZeros - Write C<oct(755)> instead of C<0755>.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Perl interprets numbers with leading zeros as octal.  If that's what
you really want, its better to use C<oct> and make it obvious.

    $var = 041;     # not ok, actually 33
    $var = oct(41); # ok

    chmod 0644, $file;                              # ok by default
    dbmopen %database, 'foo.db', 0600;              # ok by default
    mkdir $directory, 0755;                         # ok by default
    sysopen $filehandle, $filename, O_RDWR, 0666;   # ok by default
    umask 0002;                                     # ok by default

=head1 CONFIGURATION

If you want to ban all leading zeros, set C<strict> to a true value in
a F<.perlcriticrc> file.

    [ValuesAndExpressions::ProhibitLeadingZeros]
    strict = 1


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
