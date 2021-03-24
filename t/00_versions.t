#!perl

use strict;
use warnings;

use English qw< -no_match_vars >;
use Carp qw< confess >;

use File::Find;

use Test::More;

plan 'no_plan';

our $VERSION = '1.140';

use Perl::Critic::TestUtils;
Perl::Critic::TestUtils::assert_version( $VERSION );

find({wanted => \&check_version, no_chdir => 1}, 'blib');

sub check_version {
    return if (! m< blib/script/ >xms && ! m< [.] pm \z >xms);

    my $content = read_content($_);

    # Only look at Perl programs, not sh scripts.
    return if (m{blib/script/}xms && $content !~ m/\A \#![^\r\n]+?perl/xms);

    my @version_lines = $content =~ m/ ( [^\n]* \$VERSION\b [^\n]* ) /gxms;
    # Special cases for printing/documenting version numbers
    @version_lines = grep {! m/(?:[\\\"\'v]|C<)\$VERSION/xms} @version_lines;
    @version_lines = grep {! m/^\s*\#/xms} @version_lines;
    if (@version_lines == 0) {
        fail($_);
    }
    my $expected = qq{our \$VERSION = '$VERSION';};
    for my $line (@version_lines) {
        is($line, $expected, $_);
    }

    return;
}



find({wanted => \&check_asserts, no_chdir => 1}, 't', 'xt');

sub check_asserts {
    return if !/ [.]t \z /xms;

    my $content = read_content( $_ );
    ok( $content =~ m/Perl::Critic::TestUtils::assert_version/xms, "Found assert_version in $_" );

    return;
}


sub read_content {
    my $filename = shift;

    local $INPUT_RECORD_SEPARATOR = undef;
    open my $fh, '<', $filename or confess "$OS_ERROR";
    my $content = <$fh>;
    close $fh or confess "$OS_ERROR";

    # Skip POD
    $content =~ s/^__END__.*//xms;

    return $content;
}


# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
