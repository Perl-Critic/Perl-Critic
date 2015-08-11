package Perl::Critic::Utils::Constants;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ $EMPTY hashify };

use Exporter 'import';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

our @EXPORT_OK = qw{
    $PROFILE_STRICTNESS_WARN
    $PROFILE_STRICTNESS_FATAL
    $PROFILE_STRICTNESS_QUIET
    $PROFILE_STRICTNESS_DEFAULT
    %PROFILE_STRICTNESSES
    $PROFILE_COLOR_SEVERITY_HIGHEST_DEFAULT
    $PROFILE_COLOR_SEVERITY_HIGH_DEFAULT
    $PROFILE_COLOR_SEVERITY_MEDIUM_DEFAULT
    $PROFILE_COLOR_SEVERITY_LOW_DEFAULT
    $PROFILE_COLOR_SEVERITY_LOWEST_DEFAULT
    $_MODULE_VERSION_TERM_ANSICOLOR
    @STRICT_EQUIVALENT_MODULES
    @WARNINGS_EQUIVALENT_MODULES
};

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
    profile_strictness => [
        qw{
            $PROFILE_STRICTNESS_WARN
            $PROFILE_STRICTNESS_FATAL
            $PROFILE_STRICTNESS_QUIET
            $PROFILE_STRICTNESS_DEFAULT
            %PROFILE_STRICTNESSES
        }
    ],
    color_severity  => [
        qw{
            $PROFILE_COLOR_SEVERITY_HIGHEST_DEFAULT
            $PROFILE_COLOR_SEVERITY_HIGH_DEFAULT
            $PROFILE_COLOR_SEVERITY_MEDIUM_DEFAULT
            $PROFILE_COLOR_SEVERITY_LOW_DEFAULT
            $PROFILE_COLOR_SEVERITY_LOWEST_DEFAULT
        }
    ],
    equivalent_modules => [
        qw{
           @STRICT_EQUIVALENT_MODULES
           @WARNINGS_EQUIVALENT_MODULES
        }
    ],
);

#-----------------------------------------------------------------------------

Readonly::Scalar our $PROFILE_STRICTNESS_WARN    => 'warn';
Readonly::Scalar our $PROFILE_STRICTNESS_FATAL   => 'fatal';
Readonly::Scalar our $PROFILE_STRICTNESS_QUIET   => 'quiet';
Readonly::Scalar our $PROFILE_STRICTNESS_DEFAULT => $PROFILE_STRICTNESS_WARN;

Readonly::Hash our %PROFILE_STRICTNESSES =>
    hashify(
        $PROFILE_STRICTNESS_WARN,
        $PROFILE_STRICTNESS_FATAL,
        $PROFILE_STRICTNESS_QUIET,
    );

Readonly::Scalar our $PROFILE_COLOR_SEVERITY_HIGHEST_DEFAULT    => 'bold red';
Readonly::Scalar our $PROFILE_COLOR_SEVERITY_HIGH_DEFAULT       => 'magenta';
Readonly::Scalar our $PROFILE_COLOR_SEVERITY_MEDIUM_DEFAULT     => $EMPTY;
Readonly::Scalar our $PROFILE_COLOR_SEVERITY_LOW_DEFAULT        => $EMPTY;
Readonly::Scalar our $PROFILE_COLOR_SEVERITY_LOWEST_DEFAULT     => $EMPTY;

# If the following changes, the corresponding change needs to be made in
# inc/Perl/Critic/BuildUtilities.pm, sub recommended_module_versions().
Readonly::Scalar our $_MODULE_VERSION_TERM_ANSICOLOR => 2.02;

Readonly::Array our @STRICT_EQUIVALENT_MODULES => qw(
    Mo

    Moo
    Moo::Role

    Moose
    Moose::Role
    Moose::Exporter
    Moose::Util::TypeConstraints

    MooseX::NonMoose
    MooseX::Singleton
    MooseX::Role::Parameterized

    Mouse
    Mouse::Role
    Mouse::Exporter
    Mouse::Util
    Mouse::Util::TypeConstraints

    Moos

    Mousse

    Any::Moose

    Modern::Perl

    Dancer
    Dancer2

    Mojolicious::Lite
    Mojo::Base

    sane
    shit
    strictures
);

# Such modules tend to inflict both strictures and warnings, so for
# the moment these equivalent module lists are exactly the same.
Readonly::Array our @WARNINGS_EQUIVALENT_MODULES
    => @STRICT_EQUIVALENT_MODULES;

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Critic::Utils::Constants - Global constants.

=head1 DESCRIPTION

Defines commonly used constants for L<Perl::Critic|Perl::Critic>.


=head1 INTERFACE SUPPORT

This is considered to be a public module.  Any changes to its
interface will go through a deprecation cycle.


=head1 IMPORTABLE CONSTANTS

=over

=item C<$PROFILE_STRICTNESS_WARN>

=item C<$PROFILE_STRICTNESS_FATAL>

=item C<$PROFILE_STRICTNESS_QUIET>

=item C<$PROFILE_STRICTNESS_DEFAULT>

=item C<%PROFILE_STRICTNESSES>

Valid values for the L<perlcritic/"-profile-strictness"> option.
Determines whether recoverable problems found in a profile file appear
as warnings, are fatal, or are ignored.
C<$PROFILE_STRICTNESS_DEFAULT> is set to C<$PROFILE_STRICTNESS_WARN>.
Importable via the C<:profile_strictness> tag.


=item C<$PROFILE_COLOR_SEVERITY_HIGHEST_DEFAULT>

Default for the -color-severity-highest option. Importable via the
C<:color_severity> tag.

=item C<$PROFILE_COLOR_SEVERITY_HIGH_DEFAULT>

Default for the -color-severity-high option. Importable via the
C<:color_severity> tag.

=item C<$PROFILE_COLOR_SEVERITY_MEDIUM_DEFAULT>

Default for the -color-severity-medium option. Importable via the
C<:color_severity> tag.

=item C<$PROFILE_COLOR_SEVERITY_LOW_DEFAULT>

Default for the -color-severity-low option. Importable via the
C<:color_severity> tag.

=item C<$PROFILE_COLOR_SEVERITY_LOWEST_DEFAULT>

Default for the -color-severity-lowest option. Importable via the
C<:color_severity> tag.

=item C<@STRICT_EQUIVALENT_MODULES>

=item C<@WARNINGS_EQUIVALENT_MODULES>

As the names suggest, these are lists of modules that are equivalent to
applying the L<strict|strict> or L<warnings|warnings> pragma when loaded. At
the moment, both lists are exactly the same. B<Note:> These lists are not
exhaustive; they only include the most commonly used modules. Policies that
use these lists should permit configuration of additional modules.

=back


=head1 AUTHOR

Elliot Shank <perl@galumph.com>


=head1 COPYRIGHT

Copyright (c) 2007-2011 Elliot Shank.

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
