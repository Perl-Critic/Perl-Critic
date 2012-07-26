##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::BuildUtilities;

use 5.006001;
use strict;
use warnings;

use English q<-no_match_vars>;

our $VERSION = '1.116';

use Exporter 'import';

our @EXPORT_OK = qw<
    required_module_versions
    build_required_module_versions
    recommended_module_versions
    test_wrappers_to_generate
    get_PL_files
    dump_unlisted_or_optional_module_versions
    emit_tar_warning_if_necessary
>;


use Devel::CheckOS qw< os_is >;


sub required_module_versions {
    return (
        'B::Keywords'                   => 1.05,
        'Carp'                          => 0,
        'Config::Tiny'                  => 2,
        'Email::Address'                => 1.889,
        'English'                       => 0,
        'Exception::Class'              => 1.23,
        'Exporter'                      => 5.63,
        'File::Basename'                => 0,
        'File::Find'                    => 0,
        'File::Path'                    => 0,
        'File::Spec'                    => 0,
        'File::Spec::Unix'              => 0,
        'File::Temp'                    => 0,
        'Getopt::Long'                  => 0,
        'IO::String'                    => 0,
        'IPC::Open2'                    => 1,
        'List::MoreUtils'               => 0.19,
        'List::Util'                    => 0,
        'Module::Pluggable'             => 3.1,
        'PPI'                           => '1.215', # RT 61301
        'PPI::Document'                 => '1.215',
        'PPI::Document::File'           => '1.215',
        'PPI::Node'                     => '1.215',
        'PPI::Token::Quote::Single'     => '1.215',
        'PPI::Token::Whitespace'        => '1.215',
        'PPIx::Regexp'                  => '0.027', # Literal { deprecated in re
        'PPIx::Utilities::Node'         => '1.001',
        'PPIx::Utilities::Statement'    => '1.001',
        'Perl::Tidy'                    => 0,
        'Pod::Parser'                   => 0,
        'Pod::PlainText'                => 0,
        'Pod::Select'                   => 0,
        'Pod::Spell'                    => 1,
        'Pod::Usage'                    => 0,
        'Readonly'                      => 1.03,
        'Scalar::Util'                  => 0,
        'String::Format'                => 1.13,
        'Task::Weaken'                  => 0,
        'Test::Builder'                 => 0.92,
        'Text::ParseWords'              => 3,
        'base'                          => 0,
        'charnames'                     => 0,
        'overload'                      => 0,
        'strict'                        => 0,
        'version'                       => 0.77,
        'warnings'                      => 0,
    );
}


sub build_required_module_versions {
    return (
        'lib'           => 0,
        'Test::Deep'    => 0,
        'Test::More'    => 0,
    );
}


sub recommended_module_versions {
    return (
        'File::HomeDir'         => 0,
        'Readonly::XS'          => 0,

        # If the following changes, the corresponding change needs to be made
        # in $Perl::Critic::Utils::Constants::_MODULE_VERSION_TERM_ANSICOLOR.
        'Term::ANSIColor'       => '2.02',

        # All of these are for Documentation::PodSpelling
        'File::Which'           => 0,
    );
}


sub test_wrappers_to_generate {
    my @tests_to_be_wrapped = qw<
        t/00_modules.t
        t/01_config.t
        t/01_config_bad_perlcriticrc.t
        t/01_policy_config.t
        t/02_policy.t
        t/03_pragmas.t
        t/04_options_processor.t
        t/05_utils.t
        t/05_utils_ppi.t
        t/05_utils_pod.t
        t/06_violation.t
        t/07_command.t
        t/07_perlcritic.t
        t/08_document.t
        t/09_theme.t
        t/10_user_profile.t
        t/11_policy_factory.t
        t/12_policy_listing.t
        t/12_theme_listing.t
        t/13_bundled_policies.t
        t/14_policy_parameters.t
        t/15_statistics.t
        t/20_policies.t
        t/20_policy_pod_spelling.t
        t/20_policy_prohibit_evil_modules.t
        t/20_policy_prohibit_hard_tabs.t
        t/20_policy_prohibit_trailing_whitespace.t
        t/20_policy_require_consistent_newlines.t
        t/20_policy_require_tidy_code.t
        xt/author/80_policysummary.t
        t/92_memory_leaks.t
        xt/author/94_includes.t
    >;

    return
        map
            { "xt/author/generated/${_}_without_optional_dependencies.t" }
            @tests_to_be_wrapped;
}

my @TARGET_FILES = qw<
    t/ControlStructures/ProhibitNegativeExpressionsInUnlessAndUntilConditions.run
    t/NamingConventions/Capitalization.run
    t/Variables/RequireLocalizedPunctuationVars.run
>;

sub get_PL_files {
    my %PL_files = map { ( "$_.PL" => $_ ) } @TARGET_FILES;

    $PL_files{'xt/author/generate_without_optional_dependencies_wrappers.PL'} =
        [ test_wrappers_to_generate() ];

    return \%PL_files;
}

sub dump_unlisted_or_optional_module_versions {
    print
        "\nVersions of optional/unlisted/indirect dependencies:\n\n";

    my @unlisted_modules = (
        qw<
        >,
        keys %{ { recommended_module_versions() } },
    );

    foreach my $module (sort @unlisted_modules) {
        my $version;

        if ($module eq 'Readonly::XS') {
            eval 'use Readonly; use Readonly::XS; $version = $Readonly::XS::VERSION;';
        }
        else {
            eval "use $module; \$version = \$${module}::VERSION;";
        }
        if ($EVAL_ERROR) {
            $version = 'not installed';
        } elsif (not defined $version) {
            $version = 'undef';
        }

        print "    $module = $version\n";
    }

    print "\n";

    return;
}

sub emit_tar_warning_if_necessary {
    if ( os_is( qw<Solaris> ) ) {
        print <<'END_OF_TAR_WARNING';
NOTE: tar(1) on some Solaris systems cannot deal well with long file
names.

If you get warnings about missing files below, please ensure that you
extracted the Perl::Critic tarball using GNU tar.

END_OF_TAR_WARNING
    }
}




1;

__END__

=head1 NAME

Perl::Critic::BuildUtilities - Common bits of compiling Perl::Critic.


=head1 DESCRIPTION

Various utilities used in assembling Perl::Critic, primary for use by
*.PL programs that generate code.


=head1 IMPORTABLE SUBROUTINES

=over

=item C<recommended_module_versions()>

Returns a hash mapping between recommended (but not required) modules
for Perl::Critic and the minimum version required of each module,


=item C<test_wrappers_to_generate()>

Returns a list of test wrappers to be generated by
F<xt/author/generate_without_optional_dependencies_wrappers.PL>.


=item C<get_PL_files()>

Returns a reference to a hash with a mapping from the name of a .PL
program to an array of the parameters to be passed to it, suited for
use by L<Module::Build::API/"PL_files"> or
L<ExtUtils::MakeMaker/"PL_FILES">.  May print to C<STDOUT> messages
about what it is doing.


=item C<dump_unlisted_or_optional_module_versions()>

Prints to C<STDOUT> a list of all the unlisted (e.g. things in core
like L<Exporter|Exporter>), optional (e.g.
L<File::Which|File::Which>), or potentially indirect (e.g.
L<Readonly::XS|Readonly::XS>) dependencies, plus their versions, if
they're installed.


=item C<emit_tar_warning_if_necessary()>

On some Solaris systems, C<tar(1)> can't deal with long file names and
thus files are not correctly extracted from the tarball.  So this
prints a warning if the current system is Solaris.


=back


=head1 AUTHOR

Elliot Shank  C<< <perl@galumph.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007-2011, Elliot Shank.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
