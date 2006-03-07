#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
########################################################################

package Perl::Critic::Policy::Variables::ProtectPrivateVars;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use List::MoreUtils qw(all);
use base 'Perl::Critic::Policy';

our $VERSION = '0.14_02';
$VERSION = eval $VERSION;    ## no critic

#---------------------------------------------------------------------------

my $desc = q{Private variable used};
my $expl = q{Use published APIs};

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_MEDIUM }
sub applies_to { return 'PPI::Token::Symbol' }

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    if ( $elem =~ m{ \w::_\w+ \z }xms )
    {
        my $sev = $self->get_severity();
        return Perl::Critic::Violation->new( $desc, $expl, $elem, $sev );
    }
    return;    #ok!
}

1;

__END__

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Variables::ProtectPrivateVars

=head1 DESCRIPTION

By convention Perl authors (like authors in many other languages)
indicate private methods and variables by inserting a leading
underscore before the identifier.  This policy catches attempts to
access private variables from outside the package itself.

=head1 HISTORY

This policy is inspired by a similar test in L<B::Lint>

=head1 SEE ALSO

L<Perl::Critic::Policy::Subroutines::ProtectPrivateSubs>

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006 Chris Dolan.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
