package Perl::Critic::Policy::Test;

use warnings;
use strict;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

sub default_severity { return $SEVERITY_LOWEST }
sub applies_to { return 'PPI::Token::Word' }

sub violates {
    my ( $self, $elem, undef ) = @_;
    return $self->violation( 'desc', 'expl', $elem );
}

1;
__END__

=head1 DESCRIPTION

diagnostic

=cut
