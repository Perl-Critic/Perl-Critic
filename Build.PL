#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
########################################################################

use 5.006001;

use strict;
use warnings;

use lib 'inc';

use Perl::Critic::BuildUtilities qw<
    required_module_versions
    build_required_module_versions
    recommended_module_versions
    test_wrappers_to_generate
    get_PL_files
    dump_unlisted_or_optional_module_versions
    emit_tar_warning_if_necessary
>;
use Perl::Critic::Module::Build;


emit_tar_warning_if_necessary();


my $builder = Perl::Critic::Module::Build->new(
    module_name         => 'Perl::Critic',
    dist_author         => 'Jeffrey Thalhammer <jeff@imaginative-software.com>',
    dist_abstract       => 'Critique Perl source code for best-practices.',
    license             => 'perl',
    dynamic_config      => 1,
    create_readme       => 1,
    create_packlist     => 1,
    sign                => 0,

    requires            => { required_module_versions() },
    build_requires      => { build_required_module_versions() },
    recommends          => { recommended_module_versions() },

    # Don't require a developer version of Module::Build, even if the
    # distribution tarball was created with one.  (Oops.)
    configure_requires  => {
        'Module::Build' => '0.34',
    },

    PL_files            => get_PL_files(),

    script_files        => ['bin/perlcritic'],

    meta_merge          => {
        resources => {
            bugtracker  => 'https://github.com/Perl-Critic/Perl-Critic/issues',
            homepage    => 'http://perlcritic.com',
            license     => 'http://dev.perl.org/licenses',
            MailingList => 'http://perlcritic.tigris.org/servlets/SummarizeList?listName=users',
            repository  => 'git://github.com/Perl-Critic/Perl-Critic.git',
        },
        no_index        => {
            file        => [
                qw<
                    TODO.pod
                >
            ],
            directory   => [
                qw<
                    doc
                    inc
                    tools
                    xt
                >
            ],
        },
    },

    add_to_cleanup      => [
        qw<
            Debian_CPANTS.txt
            Makefile
            Makefile.old
            MANIFEST.bak
            META.json
            META.yml
            pm_to_blib
            README
        >,
        values %{ get_PL_files() },
        test_wrappers_to_generate(),
    ],
);

$builder->create_build_script();

dump_unlisted_or_optional_module_versions();


##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
