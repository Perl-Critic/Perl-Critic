#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
########################################################################

package Perl::Critic::Policy::ClassHierarchies::ProhibitExplicitISA;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.14_01';
$VERSION = eval $VERSION; ## no critic

#--------------------------------------------------------------------------

my $desc = q{@ISA used instead of 'use base'}; ##no critic for @ in string
my $expl = [ 360 ];

#--------------------------------------------------------------------------

sub default_severity { return $SEVERITY_MEDIUM }
sub applies_to { return 'PPI::Token::Symbol' }

#--------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;
    if( $elem eq q{@ISA} ) {  ##no critic for @ in string
        my $sev = $self->get_severity();
	return Perl::Critic::Violation->new( $desc, $expl, $elem, $sev );
    }
    return; #ok!
}

1;

#--------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Critic::Policy::ClassHierarchies::ProhibitExplicitISA

=head1 DESCRIPTION

Conway recommends employing C<use base qw(Foo)> instead of the usual
C<our @ISA = qw(Foo)> because the former happens at compile time and
the latter at runtime.  The C<base> pragma also automatically loads
C<Foo> for you so you save a line of easily-forgotten code.

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2006 Chris Dolan.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
