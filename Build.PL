use 5.006001;

use strict;
use warnings;

use Module::Build;
# meta_merge->resources->license now takes an arrayref of URLs in 0.4200 (or
# thereabouts, but I can't tell for sure from the Changes file).

use lib 'inc';

use Perl::Critic::BuildUtilities qw<
    required_module_versions
    build_required_module_versions
    emit_tar_warning_if_necessary
    get_PL_files
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

    # Don't require a developer version of Module::Build, even if the
    # distribution tarball was created with one.  (Oops.)
    configure_requires  => {
        'Module::Build' => '0.4204',
    },

    PL_files            => get_PL_files(),

    script_files        => ['bin/perlcritic'],

    meta_merge          => {
        resources => {
            bugtracker  => 'https://github.com/Perl-Critic/Perl-Critic/issues',
            homepage    => 'http://perlcritic.com',
            license     => [ 'http://dev.perl.org/licenses' ],
            MailingList => 'https://groups.google.com/d/forum/perl-critic',
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
        x_authority => 'cpan:CRITICRE',
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
    ],
);

$builder->create_build_script();


##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
