##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::PPIx::Optimized::Element;

use strict;
use warnings;

use PPI::Element;
use Perl::Critic::PPIx::Optimized::Caches qw(%SPREVIOUS_SIBLING %SNEXT_SIBLING);

#-----------------------------------------------------------------------------

our $VERSION = '1.098';

#-----------------------------------------------------------------------------

__install_sprevious_sibling();
__install_snext_sibling();
__install_DESTROY();

#-----------------------------------------------------------------------------

sub __install_sprevious_sibling {

    no strict 'refs';
    no warnings qw(once redefine);
    my $original_method = *PPI::Element::sprevious_sibling{CODE};
    *{'PPI::Element::sprevious_sibling'} = sub {

        my ($self) = @_;
	my $refaddr = refaddr $self;
	return $SPREVIOUS_SIBLING{$refaddr} ||= $original_method->(@_);
    };

    return;
}

#-----------------------------------------------------------------------------

sub __install_snext_sibling {


    no strict 'refs';
    no warnings qw(once redefine);
    my $original_method = *PPI::Element::snext_sibling{CODE};
    *{'PPI::Element::snext_sibling'} = sub {

        my ($self) = @_;
        my $refaddr = refaddr $self;
	return $SNEXT_SIBLING{$refaddr} ||= $original_method->(@_);
    };

    return;
}

#-----------------------------------------------------------------------------

sub __install_DESTROY {

    no strict 'refs';
    no warnings qw(once redefine);
    my $original_method = *PPI::Element::DESTROY{CODE};
    *{'PPI::Element::DESTROY'} = sub {

        my ($self) = @_;
	Perl::Critic::PPIx::Optimized::Caches::flush_element($self);
	return $original_method->(@_);
    };

    return;
}


#-----------------------------------------------------------------------------

sub PPI::Element::descendants { return }  # An Element has no descendants

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
