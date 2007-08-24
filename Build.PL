#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
########################################################################

use strict;
use warnings;
use Module::Build;

my $warning = <<'END_WARNING';

###################################################
# NOTICE! NOTICE! NOTICE! NOTICE! NOTICE! NOTICE! #
#-------------------------------------------------#
# In this version of Perl::Critic, some of        #
# the Policy modules have been renamed to better  #
# better reflect the intent of the Policy.  If    #
# you have an older version of Perl::Critic       #
# already installed, it will cause many of the    #
# tests to fail and the new version will not work #
# properly.                                       #
#                                                 #
# I strongly advise you to remove the current     #
# version of Perl::Critic before proceeding with  #
# this installation.  In most cases, this can be  #
# done by deleting everything below the           #
# Perl/Critic/Policy directory in your site_perl  #
# location.                                       #
#                                                 #
# Also, if you have created a .perlcriticrc file, #
# you will need to update it to match the new     #
# Policy module names.                            #
#                                                 #
# Sorry for the inconvenience.                    #
#                                                 #
# -Jeff <thaljef@cpan.org>                        #
###################################################

END_WARNING


eval {
    require Perl::Critic;
    warn $warning if $Perl::Critic::VERSION < 0.14;
};


my $builder = Module::Build->new(

  module_name    => 'Perl::Critic',
  dist_author    => 'Jeffrey Thalhammer <thaljef@cpan.org>',
  dist_abstract  => 'Critique Perl source code for best-practices',
  license        => 'perl',

  requires       => {'B::Keywords'           => 1.05,
                     'Config::Tiny'          => 2,
                     'File::Spec'            => 0,
                     'File::Spec::Unix'      => 0,
                     'IO::String'            => 0,
                     'List::MoreUtils'       => 0,
                     'List::Util'            => 0,
                     'Module::Pluggable'     => 3.1,
                     'PPI'                   => 1.118,
                     'Pod::PlainText'        => 0,
                     'Pod::Usage'            => 0,
                     'Readonly'              => 1.03,
                     'Scalar::Util'          => 0,
                     'String::Format'        => 1.13,
                    },

  recommends     => {'File::HomeDir'         => 0,
                     'Perl::Tidy'            => 0,

                     # All of these are for Documentation::PodSpelling
                     'File::Which'           => 0,
                     'IPC::Open2'            => 1,
                     'Pod::Spell'            => 1,
                     'Text::ParseWords'      => 3,
                    },

  build_requires => {'Test::More'            => 0,
                    },

  script_files   => ['bin/perlcritic'],
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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
