##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::PPIx::Optimized::Document;

use strict;
use warnings;

use PPI::Document;
use Perl::Critic::PPIx::Optimized::Caches qw(%SERIALIZE);

#-----------------------------------------------------------------------------

our $VERSION = '1.098';

#-----------------------------------------------------------------------------

__install_serialize();

#------------------------------------------------------------------------------

sub __install_serialize {

    no strict 'refs';
    no warnings qw(once redefine);
    my $original_method = *PPI::Document::serialize{CODE};
    *{'PPI::Document::serialize'} = sub {

        my ($self) = @_;
	my $refaddr = refaddr $self;
        return $SERIALIZE{$refaddr} ||= $original_method->(@_);
    };

    return;
}

#-----------------------------------------------------------------------------

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
