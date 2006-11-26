#!perl

##################################################################
#     $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/Perl-Critic/t/20_policies_variables.t $
#    $Date: 2006-11-25 11:47:17 -0600 (Sat, 25 Nov 2006) $
#   $Author: petdance $
# $Revision: 938 $
##################################################################

use strict;
use warnings;
use Test::More;
use File::Find;
use Data::Dumper;


# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

# TODO: test that we have a t/*/*.pl for each lib/*/*.pm

my %test_files;
find( sub {
    if ( -f && ( $File::Find::name =~ m{t/(.+)\.pl$} ) ) {
        my $package = $1;
        $package =~ s{/}{::}gmsx;
        $test_files{ $package } = $File::Find::name;
    }
}, 't/' );

plan tests => scalar keys %test_files;

for my $package ( sort keys %test_files ) {
    my $test_file = $test_files{ $package };
    pass( $test_file );
}
#----------------------------------------------------------------
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 expandtab ft=perl:
