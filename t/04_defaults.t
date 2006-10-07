#!perl

##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 12;

use Perl::Critic::Config::Defaults;
use Perl::Critic::Config;
use Perl::Critic::Utils;

# common P::C testing tools
use Perl::Critic::TestUtils qw();
Perl::Critic::TestUtils::block_perlcriticrc();

{
    my $d = Perl::Critic::Config::Defaults->new();
    is($d->default_severity(), $SEVERITY_HIGHEST, 'native default severity');
    is_deeply($d->default_themes,  [], 'native default themes');
    is_deeply($d->default_include, [], 'native default include');
    is_deeply($d->default_exclude, [], 'native default exclude');
}

#-----------------------------------------------------------------------------

{
    my $severity = 2;
    my @themes   = sort qw(pbp risky);
    my @includes = qw(CodeLayout ControlStructures);
    my @excludes = qw(Variables Modules);
    my %user_defaults = ( -severity => $severity,
                          -themes   => \@themes,
                          -include  => \@includes,
                          -exclude  => \@excludes,
                     );

    my $d = Perl::Critic::Config::Defaults->new( %user_defaults );
    is($d->default_severity(), $severity, 'user-default severity');
    is_deeply($d->default_themes,  \@themes, 'user-default themes');
    is_deeply($d->default_include, \@includes, 'user-default include');
    is_deeply($d->default_exclude, \@excludes, 'user-default exclude');
}

#-----------------------------------------------------------------------------

{
    my $samples_dir = 't/samples';
    my $profile = "$samples_dir/perlcriticrc.defaults";
    my $critic  = Perl::Critic::Config->new( -profile => $profile );
    my $d       = $critic->defaults();

    my $severity = 3;
    my @themes   = sort qw(danger risky pbp);
    my @includes = qw(CodeLayout Modules);
    my @excludes = qw(Documentation NamingConventions);

    is_deeply($d->default_severity, $severity, 'user-default from file');
    is_deeply($d->default_themes,   \@themes, 'user-default from file');
    is_deeply($d->default_include,  \@includes, 'user-default from file');
    is_deeply($d->default_exclude,  \@excludes, 'user-default from file');
}
