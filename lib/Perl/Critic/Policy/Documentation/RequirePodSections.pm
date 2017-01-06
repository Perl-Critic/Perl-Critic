package Perl::Critic::Policy::Documentation::RequirePodSections;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :booleans :characters :severities :classification };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL => [133, 138];

Readonly::Scalar my $BOOK                => 'book';
Readonly::Scalar my $BOOK_FIRST_EDITION  => 'book_first_edition';
Readonly::Scalar my $MODULE_STARTER_PBP  => 'module_starter_pbp';
Readonly::Scalar my $M_S_PBP_0_0_3       => 'module_starter_pbp_0_0_3';

Readonly::Scalar my $DEFAULT_SOURCE      => $BOOK_FIRST_EDITION;

Readonly::Hash   my %SOURCE_TRANSLATION  => (
    $BOOK               => $BOOK_FIRST_EDITION,
    $BOOK_FIRST_EDITION => $BOOK_FIRST_EDITION,
    $MODULE_STARTER_PBP => $M_S_PBP_0_0_3,
    $M_S_PBP_0_0_3      => $M_S_PBP_0_0_3,
);

Readonly::Scalar my $EN_AU                       => 'en_AU';
Readonly::Scalar my $EN_US                       => 'en_US';
Readonly::Scalar my $ORIGINAL_MODULE_VERSION     => 'original';

Readonly::Hash my %SOURCE_DEFAULT_LANGUAGE     => (
    $BOOK_FIRST_EDITION => $ORIGINAL_MODULE_VERSION,
    $M_S_PBP_0_0_3      => $EN_AU,
);

Readonly::Scalar my $BOOK_FIRST_EDITION_US_LIB_SECTIONS =>
    [
        'NAME',
        'VERSION',
        'SYNOPSIS',
        'DESCRIPTION',
        'SUBROUTINES/METHODS',
        'DIAGNOSTICS',
        'CONFIGURATION AND ENVIRONMENT',
        'DEPENDENCIES',
        'INCOMPATIBILITIES',
        'BUGS AND LIMITATIONS',
        'AUTHOR',
        'LICENSE AND COPYRIGHT',
    ];

Readonly::Hash my %DEFAULT_LIB_SECTIONS => (
    $BOOK_FIRST_EDITION => {
        $ORIGINAL_MODULE_VERSION => $BOOK_FIRST_EDITION_US_LIB_SECTIONS,
        $EN_AU => [
            'NAME',
            'VERSION',
            'SYNOPSIS',
            'DESCRIPTION',
            'SUBROUTINES/METHODS',
            'DIAGNOSTICS',
            'CONFIGURATION AND ENVIRONMENT',
            'DEPENDENCIES',
            'INCOMPATIBILITIES',
            'BUGS AND LIMITATIONS',
            'AUTHOR',
            'LICENCE AND COPYRIGHT',
        ],
        $EN_US => $BOOK_FIRST_EDITION_US_LIB_SECTIONS,
    },
    $M_S_PBP_0_0_3 => {
        $EN_AU => [
            'NAME',
            'VERSION',
            'SYNOPSIS',
            'DESCRIPTION',
            'INTERFACE',
            'DIAGNOSTICS',
            'CONFIGURATION AND ENVIRONMENT',
            'DEPENDENCIES',
            'INCOMPATIBILITIES',
            'BUGS AND LIMITATIONS',
            'AUTHOR',
            'LICENCE AND COPYRIGHT',
            'DISCLAIMER OF WARRANTY',
        ],
        $EN_US => [
            'NAME',
            'VERSION',
            'SYNOPSIS',
            'DESCRIPTION',
            'INTERFACE',
            'DIAGNOSTICS',
            'CONFIGURATION AND ENVIRONMENT',
            'DEPENDENCIES',
            'INCOMPATIBILITIES',
            'BUGS AND LIMITATIONS',
            'AUTHOR',
            'LICENSE AND COPYRIGHT',
            'DISCLAIMER OF WARRANTY'
        ],
    },
);

Readonly::Hash my %DEFAULT_SCRIPT_SECTIONS => (
    $BOOK_FIRST_EDITION => {
        $ORIGINAL_MODULE_VERSION => [
            'NAME',
            'USAGE',
            'DESCRIPTION',
            'REQUIRED ARGUMENTS',
            'OPTIONS',
            'DIAGNOSTICS',
            'EXIT STATUS',
            'CONFIGURATION',
            'DEPENDENCIES',
            'INCOMPATIBILITIES',
            'BUGS AND LIMITATIONS',
            'AUTHOR',
            'LICENSE AND COPYRIGHT',
        ],
        $EN_AU => [
            'NAME',
            'VERSION',
            'USAGE',
            'REQUIRED ARGUMENTS',
            'OPTIONS',
            'DESCRIPTION',
            'DIAGNOSTICS',
            'CONFIGURATION AND ENVIRONMENT',
            'DEPENDENCIES',
            'INCOMPATIBILITIES',
            'BUGS AND LIMITATIONS',
            'AUTHOR',
            'LICENCE AND COPYRIGHT',
        ],
        $EN_US => [
            'NAME',
            'VERSION',
            'USAGE',
            'REQUIRED ARGUMENTS',
            'OPTIONS',
            'DESCRIPTION',
            'DIAGNOSTICS',
            'CONFIGURATION AND ENVIRONMENT',
            'DEPENDENCIES',
            'INCOMPATIBILITIES',
            'BUGS AND LIMITATIONS',
            'AUTHOR',
            'LICENSE AND COPYRIGHT',
        ],
    },
    $M_S_PBP_0_0_3 => {
        $EN_AU => [
            'NAME',
            'VERSION',
            'USAGE',
            'REQUIRED ARGUMENTS',
            'OPTIONS',
            'DESCRIPTION',
            'DIAGNOSTICS',
            'CONFIGURATION AND ENVIRONMENT',
            'DEPENDENCIES',
            'INCOMPATIBILITIES',
            'BUGS AND LIMITATIONS',
            'AUTHOR',
            'LICENCE AND COPYRIGHT',
            'DISCLAIMER OF WARRANTY',
        ],
        $EN_US => [
            'NAME',
            'VERSION',
            'USAGE',
            'REQUIRED ARGUMENTS',
            'OPTIONS',
            'DESCRIPTION',
            'DIAGNOSTICS',
            'CONFIGURATION AND ENVIRONMENT',
            'DEPENDENCIES',
            'INCOMPATIBILITIES',
            'BUGS AND LIMITATIONS',
            'AUTHOR',
            'LICENSE AND COPYRIGHT',
            'DISCLAIMER OF WARRANTY',
        ],
    },
);

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'lib_sections',
            description     => 'The sections to require for modules (separated by qr/\s* [|] \s*/xms).',
            default_string  => $EMPTY,
            parser          => \&_parse_lib_sections,
        },
        {
            name            => 'script_sections',
            description     => 'The sections to require for programs (separated by qr/\s* [|] \s*/xms).',
            default_string  => $EMPTY,
            parser          => \&_parse_script_sections,
        },
        {
            name            => 'source',
            description     => 'The origin of sections to use.',
            default_string  => $DEFAULT_SOURCE,
            behavior        => 'enumeration',
            enumeration_values => [ keys %SOURCE_TRANSLATION ],
        },
        {
            name            => 'language',
            description     => 'The spelling of sections to use.',
            default_string  => $EMPTY,
            behavior        => 'enumeration',
            enumeration_values => [ $EN_AU, $EN_US ],
        },
    );
}

sub default_severity { return $SEVERITY_LOW            }
sub default_themes   { return qw(core pbp maintenance) }
sub applies_to       { return 'PPI::Document'          }

#-----------------------------------------------------------------------------

sub _parse_sections {
    my $config_string = shift;

    my @sections = split m{ \s* [|] \s* }xms, $config_string;

    return map { uc } @sections;  # Normalize CaSe!
}

sub _parse_lib_sections {
    my ($self, $parameter, $config_string) = @_;

    if ( defined $config_string ) {
        $self->{_lib_sections} = [ _parse_sections( $config_string ) ];
    }

    return;
}

sub _parse_script_sections {
    my ($self, $parameter, $config_string) = @_;

    if ( defined $config_string ) {
        $self->{_script_sections} = [ _parse_sections( $config_string ) ];
    }

    return;
}

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    my ($self, $config) = @_;

    my $source = $self->{_source};
    if ( not defined $source or not defined $DEFAULT_LIB_SECTIONS{$source} ) {
        $source = $DEFAULT_SOURCE;
    }

    my $language = $self->{_language};
    if (
            not defined $language
        or  not defined $DEFAULT_LIB_SECTIONS{$source}{$language}
    ) {
        $language = $SOURCE_DEFAULT_LANGUAGE{$source};
    }

    if ( not $self->_sections_specified('_lib_sections') ) {
        $self->{_lib_sections} = $DEFAULT_LIB_SECTIONS{$source}{$language};
    }
    if ( not $self->_sections_specified('_script_sections') ) {
        $self->{_script_sections} =
            $DEFAULT_SCRIPT_SECTIONS{$source}{$language};
    }

    return $TRUE;
}

sub _sections_specified {
    my ( $self, $sections_key ) = @_;

    my $sections = $self->{$sections_key};

    return 0 if not defined $sections;

    return scalar @{ $sections };
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    # This policy does not apply unless there is some real code in the
    # file.  For example, if this file is just pure POD, then
    # presumably this file is ancillary documentation and you can use
    # whatever headings you want.
    return if ! $doc->schild(0);

    my %found_sections = ();
    my @violations = ();

    my @required_sections =
        $doc->is_program()
            ? @{ $self->{_script_sections} }
            : @{ $self->{_lib_sections} };

    my $pods_ref = $doc->find('PPI::Token::Pod');
    return if not $pods_ref;

    # Round up the names of all the =head1 sections
    my $pod_of_record;
    for my $pod ( @{ $pods_ref } ) {
        for my $found ( $pod =~ m{ ^ =head1 \s+ ( .+? ) \s* $ }gxms ) {
            # Use first matching POD as POD of record (RT #59268)
            $pod_of_record ||= $pod;
            #Leading/trailing whitespace is already removed
            $found_sections{ uc $found } = 1;
        }
    }

    # Compare the required sections against those we found
    for my $required ( @required_sections ) {
        if ( not exists $found_sections{$required} ) {
            my $desc = qq{Missing "$required" section in POD};
            # Report any violations against POD of record rather than whole
            # document (the point of RT #59268)
            # But if there are no =head1 records at all, rat out the
            # first pod found, as being better than blowing up. RT #67231
            push @violations, $self->violation( $desc, $EXPL,
                $pod_of_record || $pods_ref->[0] );
        }
    }

    return @violations;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords licence

=head1 NAME

Perl::Critic::Policy::Documentation::RequirePodSections - Organize your POD into the customary sections.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

This Policy requires your POD to contain certain C<=head1> sections.
If the file doesn't contain any POD at all, then this Policy does not
apply.  Tools like L<Module::Starter|Module::Starter> make it really
easy to ensure that every module has the same documentation framework,
and they can save you lots of keystrokes.


=head1 DEFAULTS

Different POD sections are required, depending on whether the file is
a library or program (which is determined by the presence or absence
of a perl shebang line).

                Default Required POD Sections

    Perl Libraries                     Perl Programs
    -----------------------------      ---------------------
    NAME                               NAME
    VERSION
    SYNOPSIS                           USAGE
    DESCRIPTION                        DESCRIPTION
    SUBROUTINES/METHODS                REQUIRED ARGUMENTS
                                       OPTIONS
    DIAGNOSTICS                        DIAGNOSTICS
                                       EXIT STATUS
    CONFIGURATION AND ENVIRONMENT      CONFIGURATION
    DEPENDENCIES                       DEPENDENCIES
    INCOMPATIBILITIES                  INCOMPATIBILITIES
    BUGS AND LIMITATIONS               BUGS AND LIMITATIONS
    AUTHOR                             AUTHOR
    LICENSE AND COPYRIGHT              LICENSE AND COPYRIGHT


=head1 CONFIGURATION

The default sections above are derived from Damian Conway's I<Perl
Best Practices> book.  Since the book has been published, Conway has
released L<Module::Starter::PBP|Module::Starter::PBP>, which has
different names for some of the sections, and adds some more.  Also,
the book and module use Australian spelling, while the authors of this
module have previously used American spelling.  To sort this all out,
there are a couple of options that can be used: C<source> and
C<language>.

The C<source> option has two generic values, C<book> and
C<module_starter_pbp>, and two version-specific values,
C<book_first_edition> and C<module_starter_pbp_0_0_3>.  Currently, the
generic values map to the corresponding version-specific values, but
may change as new versions of the book and module are released, so use
these if you want to keep up with the latest and greatest.  If you
want things to remain stable, use the version-specific values.

The C<language> option has a default, unnamed value but also accepts
values of C<en_AU> and C<en_US>.  The reason the unnamed value exists
is because the default values for programs don't actually match the
book, even taking spelling into account, i.e. C<CONFIGURATION> instead
of C<CONFIGURATION AND ENVIRONMENT>, the removal of C<VERSION>, and
the addition of C<EXIT STATUS>.  To get precisely the sections as
specified in the book, put the following in your F<.perlcriticrc>
file:

    [Documentation::RequirePodSections]
    source   = book_first_edition
    language = en_AU

If you want to use

    [Documentation::RequirePodSections]
    source   = module_starter_pbp
    language = en_US

you will need to modify your F<~/.module-starter/PBP/Module.pm>
template because it is generated using Australian spelling.

Presently, the difference between C<en_AU> and C<en_US> is in how the
word "licence" is spelled.

The sections required for modules and programs can be independently
customized, overriding any values for C<source> and C<language>, by
giving values for C<script_sections> and C<lib_sections> of a string
of pipe-delimited required POD section names.  An example of entries
in a F<.perlcriticrc> file:

    [Documentation::RequirePodSections]
    lib_sections    = NAME | SYNOPSIS | BUGS AND LIMITATIONS | AUTHOR
    script_sections = NAME | USAGE | OPTIONS | EXIT STATUS | AUTHOR


=head1 LIMITATIONS

Currently, this Policy does not look for the required POD sections
below the C<=head1> level.  Also, it does not require the sections to
appear in any particular order.

This Policy applies to the entire document, but can be disabled for a
particular document by a C<## no critic (RequirePodSections)> annotation
anywhere between the beginning of the document and the first POD section
containing a C<=head1>, the C<__END__> (if any), or the C<__DATA__> (if any),
whichever comes first.


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2006-2011 Imaginative Software Systems.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
