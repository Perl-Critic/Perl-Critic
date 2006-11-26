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

my %test_chunks;
my $nchunks;
find( sub {
    if ( -f && ( $File::Find::name =~ m{t/(.+)\.pl$} ) ) {
        my $package = $1;
        $package =~ s{/}{::}gmsx;

        my @chunks = chunks( $_ );
        $nchunks += @chunks;
        $test_chunks{ $package } = [ @chunks ];
    }
}, 't/' );

plan tests => $nchunks;

for my $package ( sort keys %test_chunks ) {
    my $chunk_list = $test_chunks{ $package };
    for my $chunk ( @$chunk_list ) {
        pass( "$package: $chunk->{name}" );
    }
}

sub chunks {
    my $test_file = shift;

    my %valid_keys = map {($_,1)} qw( name failures parms );

    open( my $fh, '<', $test_file ) or die "Couldn't open $test_file: $!";

    my @chunks = ();

    my $incode = 0;
    my $chunk;
    while ( <$fh> ) {
        chomp;
        my $inpod = /^=name/ .. /^=cut/;

        my $line = $_;

        if ( $inpod ) {
            $line =~ /^=(\S+)\s+(.+)/ or next;
            my ($key,$value) = ($1,$2);
            die "Unknown key $key" unless $valid_keys{$key};

            if ( $key eq 'name' ) {
                if ( $chunk ) { # Stash any current chunk
                    push( @chunks, $chunk );
                    undef $chunk;
                }
                $incode = 0;
            }
            $incode && die "POD found while I'm still in code";
            $chunk->{$key} = $value;
        }
        else {
            $incode = 1;
            push @{$chunk->{code}}, $line if $chunk; # Don't start a chunk if we're not in one
        }
    }
    close $fh;
    if ( $chunk ) {
        if ( $incode ) {
            push( @chunks, $chunk );
        }
        else {
            die "Incomplete chunk in $test_file";
        }
    }

    return @chunks;
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
