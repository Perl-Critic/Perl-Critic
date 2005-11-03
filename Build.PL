use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(

  module_name    => 'Perl::Critic',
  dist_author    => 'Jeffrey Thalhammer <thaljef@cpan.org>',
  dist_abstract  => 'Critique Perl source for style and standards',
  license        => 'perl',

  requires       => {'PPI'                   => 1.103,
	             'Config::Tiny'          => 2,
	             'File::Spec'            => 0,
  	             'List::MoreUtils'       => 0,
	             'List::Util'            => 0,
	             'Pod::Usage'            => 0,
		     'Pod::PlainText'        => 0,
		     'IO::String'            => 0,
		     'String::Format'        => 1.13,

	            },

  build_requires => {'Test::More'            => 0,
                    },

  recommends     => {'Perl::Tidy'            => 0,},
  script_files   => ['bin/perlcritic'],
);

$builder->create_build_script();
