use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile( NAME           => 'Perl::Critic',
	       AUTHOR         => 'Jeffrey Thalhammer <thaljef@cpan.org>',
	       ABSTRACT_FROM  => 'lib/Perl/Critic.pm',
	       VERSION_FROM   => 'lib/Perl/Critic.pm',
	       EXE_FILES      => ['bin/perlcritic'],
	       PL_FILES       => {},
	       PREREQ_PM      => {'PPI'                   => 1.103,
				  'Config::Tiny'          => 2,
				  'File::Spec'            => 0,
				  'List::MoreUtils'       => 0,
				  'List::Util'            => 0,
				  'Pod::Usage'            => 0,
				  'Pod::PlainText'        => 0,
                                  'Test::More'            => 0,
				  'IO::String'            => 0,
				  'String::Format'        => 1.13,
			      },

);
