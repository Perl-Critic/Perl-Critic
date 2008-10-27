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
use lib 'lib';

use ExtUtils::MakeMaker;

use Perl::Critic::BuildUtilities qw<
    test_wrappers_to_generate
    get_PL_files
    dump_unlisted_or_optional_module_versions
    emit_tar_warning_if_necessary
>;


emit_tar_warning_if_necessary();


# An attempt was made by Elliot to get the "resources" META.yml entry going
# here, but he failed.  The version in Build.PL works.  See the Makefile.PL
# in the ack distribution for an example.

WriteMakefile(
    NAME           => 'Perl::Critic',
    AUTHOR         => 'Jeffrey Thalhammer <thaljef@cpan.org>',
    ABSTRACT_FROM  => 'lib/Perl/Critic.pm',
    VERSION_FROM   => 'lib/Perl/Critic.pm',
    EXE_FILES      => ['bin/perlcritic'],
    PL_FILES       => get_PL_files(),
    PREREQ_PM      => {
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

        'lib'                       => 0,
        'Test::More'                => 0,
    },
    realclean      => {
        FILES =>
            join
                q< >,
                values %{ get_PL_files() },
                test_wrappers_to_generate(),
    },
);

sub MY::postamble {
    return <<"MAKE_FRAG";
.PHONY: tags

tags:
\tctags -f tags \\
\t\t--recurse \\
\t\t--totals \\
\t\t\\
\t\t--exclude=blib/ \\
\t\t--exclude=t/lib \\
\t\t--exclude=.svn \\
\t\t--exclude='*~' \\
\t\t\\
\t\t--languages=Perl \\
\t\t--langmap=Perl:+.t
MAKE_FRAG
}

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
