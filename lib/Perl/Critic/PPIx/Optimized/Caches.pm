package Perl::Critic::PPIx::Optimized::Caches;

use strict;
use warnings;

use Scalar::Util qw(refaddr);
use base qw(Exporter);

#------------------------------------------------------------------------------

use vars qw(%SPREVIOUS_SIBLING %SNEXT_SIBLING %SERIALIZE %CONTENT);
our @EXPORT_OK = qw(%SPREVIOUS_SIBLING %SNEXT_SIBLING %SERIALIZE %CONTENT);

#------------------------------------------------------------------------------

sub flush_element {
    my ($elem) = @_;
    my $refaddr = refaddr $elem;
    delete $SPREVIOUS_SIBLING{$refaddr};
    delete $SNEXT_SIBLING{$refaddr};
    delete $SERIALIZE{$refaddr};
    delete $CONTENT{$refaddr};
}

#------------------------------------------------------------------------------

1;

__END__

=pod

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
