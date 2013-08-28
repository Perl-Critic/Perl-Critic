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
    required_module_versions
    build_required_module_versions
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
    AUTHOR         => 'Jeffrey Thalhammer <jeff@imaginative-software.com>',
    ABSTRACT_FROM  => 'lib/Perl/Critic.pm',
    VERSION_FROM   => 'lib/Perl/Critic.pm',
    EXE_FILES      => ['bin/perlcritic'],
    PL_FILES       => get_PL_files(),
    PREREQ_PM      => {
        required_module_versions(),
        build_required_module_versions(),
    },
    realclean      => {
        FILES =>
            join
                q< >,
                (map { (ref $_ eq 'ARRAY') ? @{$_} : $_ } values %{ get_PL_files() }),
                test_wrappers_to_generate(),
    },
    META_MERGE     => {
        resources => {
            repository => 'https://github.com/Perl-Critic/Perl-Critic',
        },
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
