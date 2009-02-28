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
    recommended_module_versions
    test_wrappers_to_generate
    get_PL_files
    dump_unlisted_or_optional_module_versions
    emit_tar_warning_if_necessary
>;
use Perl::Critic::Module::Build;


emit_tar_warning_if_necessary();


my $builder = Perl::Critic::Module::Build->new(
    module_name     => 'Perl::Critic',
    dist_author     => 'Jeffrey Thalhammer <thaljef@cpan.org>',
    dist_abstract   => 'Critique Perl source code for best-practices.',
    license         => 'perl',
    dynamic_config  => 1,
    create_readme   => 1,
    create_packlist => 1,
    sign            => 0,

    requires        => {
        'B::Keywords'               => 1.05,
        'Carp'                      => 0,
        'Config::Tiny'              => 2,
        'English'                   => 0,
        'Exception::Class'          => 1.23,
        'Exporter'                  => 0,
        'File::Basename'            => 0,
        'File::Find'                => 0,
        'File::Path'                => 0,
        'File::Spec'                => 0,
        'File::Spec::Unix'          => 0,
        'File::Temp'                => 0,
        'Getopt::Long'              => 0,
        'IO::String'                => 0,
        'List::MoreUtils'           => 0,
        'List::Util'                => 0,
        'Module::Pluggable'         => 3.1,
        'PPI'                       => 1.203,
        'PPI::Document'             => 1.203,
        'PPI::Document::File'       => 1.203,
        'PPI::Node'                 => 1.203,
        'PPI::Token::Quote::Single' => 1.203,
        'PPI::Token::Whitespace'    => 1.203,
        'Pod::PlainText'            => 0,
        'Pod::Select'               => 0,
        'Pod::Usage'                => 0,
        'Readonly'                  => 1.03,
        'Scalar::Util'              => 0,
        'String::Format'            => 1.13,
        'base'                      => 0,
        'charnames'                 => 0,
        'overload'                  => 0,
        'strict'                    => 0,
        'version'                   => 0,
        'warnings'                  => 0,
        'overload'                  => 0,
        'strict'                    => 0,
        'version'                   => 0,
        'warnings'                  => 0,
    },

    recommends      => { recommended_module_versions() },

    build_requires  => {
        'lib'                       => 0,
        'Test::More'                => 0,
    },

    PL_files        => get_PL_files(),

    script_files    => ['bin/perlcritic'],

    meta_merge      => {
        resources   => {
            homepage    => 'http://perlcritic.com',
            license     => 'http://dev.perl.org/licenses/',
            Repository  => 'http://guest@perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/',
            MailingList => 'http://perlcritic.tigris.org/servlets/SummarizeList?listName=users',
        },
        no_index    => {
            file        => [
                qw<
                    TODO.pod
                    lib/Perl/Critic/PolicySummary.pod.PL
                >
            ],
            directory   => [
                qw<
                    doc
                    tools
                    xt
                >
            ],
        },
    },

    add_to_cleanup => [
        qw<
            Debian_CPANTS.txt
            Makefile
            Makefile.old
            MANIFEST
            MANIFEST.bak
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
