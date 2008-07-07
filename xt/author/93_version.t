#!perl -w

use strict;
use warnings;

use Carp qw< confess >;

use File::Find;

use Test::More;

#-----------------------------------------------------------------------------

our $VERSION = '1.088';

#-----------------------------------------------------------------------------

plan 'no_plan';

my $last_version = undef;
find({wanted => \&check_version, no_chdir => 1}, 'blib');
if (! defined $last_version) {
    fail('Failed to find any files with $VERSION');
}

sub check_version {
    return if (! m{blib/script/}xms && ! m{\.pm \z}xms);

    local $/ = undef;
    my $fh;
    open $fh, '<', $_ or confess $!;
    my $content = <$fh>;
    close $fh;

    # Skip POD
    $content =~ s/^__END__.*//xms;

    # only look at perl scripts, not sh scripts
    return if (m{blib/script/}xms && $content !~ m/\A \#![^\r\n]+?perl/xms);

    my @version_lines = $content =~ m/ ( [^\n]* \$VERSION [^\n]* ) /gxms;
    # Special cases for printing/documenting version numbers
    @version_lines = grep {! m/(?:\\|\"|\'|C<|v)\$VERSION/xms} @version_lines;
    @version_lines = grep {! m/^\s*\#/xms} @version_lines;
    if (@version_lines == 0) {
        fail($_);
    }
    for my $line (@version_lines) {
        if (!defined $last_version) {
            $last_version = shift @version_lines;
            pass($_);
        }
        else {
            is($line, $last_version, $_);
        }
    }

    return;
}

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
