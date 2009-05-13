package Perl::Critic::PPIx::Optimized::Caches;

use strict;
use warnings;

use Scalar::Util qw(refaddr weaken);
use base qw(Exporter);

#------------------------------------------------------------------------------

use vars qw(%SPREVIOUS_SIBLING %SNEXT_SIBLING %SERIALIZE %CONTENT %FINDER);
our @EXPORT_OK = qw(%SPREVIOUS_SIBLING %SNEXT_SIBLING %SERIALIZE %CONTENT %FINDER);

#------------------------------------------------------------------------------

sub flush_all {
    %SPREVIOUS_SIBLING = ();
    %SNEXT_SIBLING     = ();
    %SERIALIZE         = ();
    %CONTENT           = ();
    %FINDER            = ();
    return;
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
