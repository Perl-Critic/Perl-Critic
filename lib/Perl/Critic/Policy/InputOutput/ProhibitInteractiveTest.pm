##################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##################################################################

package Perl::Critic::Policy::InputOutput::ProhibitInteractiveTest;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.19;

#----------------------------------------------------------------------------

my $desc = q{Use prompt() instead of -t};
my $expl = [ 218 ];

#----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGHEST }
sub applies_to { return 'PPI::Token::Operator' }

#----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;
    return if $elem ne '-t';
    return $self->violation( $desc, $expl, $elem );
}

1;

#----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Critic::Policy::InputOutput::ProhibitInteractiveTest

=head1 DESCRIPTION

The C<-t> operator is fragile and complicated.  When you are testing
whether C<STDIN> is interactive, It's much more robust to use
well-tested CPAN modules like L<IO::Interactive>.

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2006 Chris Dolan.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
