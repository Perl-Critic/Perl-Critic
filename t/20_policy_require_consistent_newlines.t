#!perl

##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

use 5.006001;
use strict;
use warnings;

use charnames ':full';

use Perl::Critic::TestUtils qw(pcritique fcritique);

use Test::More tests => 29;

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

Perl::Critic::TestUtils::block_perlcriticrc();

my $code;
my $policy = 'CodeLayout::RequireConsistentNewlines';

my $base_code = <<'END_PERL';
package My::Pkg;
my $str = <<"HEREDOC";
heredoc_body
heredoc_body
HEREDOC

=head1 POD_HEADER

pod pod pod

=cut

# comment_line

1; # inline_comment

__END__
end_body
__DATA__
DataLine1
DataLine2
END_PERL

is( fcritique($policy, \$base_code), 0, $policy );

my @lines = split m/\n/xms, $base_code;
for my $keyword (qw<
    Pkg; heredoc_body HEREDOC POD_HEADER pod =cut
    comment_line inline_comment
    __END__ end_body __DATA__ DataLine1 DataLine2
>) {
    my $is_first_line = $lines[0] =~ m/\Q$keyword\E\z/xms;
    my $nfail = $is_first_line ? @lines-1 : 1;
    for my $nl (
        "\N{LINE FEED}",
        "\N{CARRIAGE RETURN}",
        "\N{CARRIAGE RETURN}\N{LINE FEED}",
    ) {
        next if $nl eq "\n";
        ($code = $base_code) =~ s/ (\Q$keyword\E) \n /$1$nl/xms;
        is( fcritique($policy, \$code), $nfail, $policy.' - '.$keyword );
    }
}

for my $nl (
    "\N{LINE FEED}",
    "\N{CARRIAGE RETURN}",
    "\N{CARRIAGE RETURN}\N{LINE FEED}",
) {
    next if $nl eq "\n";
    ($code = $base_code) =~ s/ \n /$nl/xms;
    is( pcritique($policy, \$code), 0, $policy.' - no filename' );
}

# ensure we return true if this test is loaded by
# 20_policy_require_consistent_newlines.t_without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
