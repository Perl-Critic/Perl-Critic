#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::ClassHierarchies::ProhibitAutoloading;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.20;

#--------------------------------------------------------------------------

my $desc = q{AUTOLOAD method declared};
my $expl = [ 393 ];

#--------------------------------------------------------------------------

sub default_severity { return $SEVERITY_MEDIUM      }
sub default_themes    { return qw( unreliable pbp )  }
sub applies_to       { return 'PPI::Statement::Sub' }

#--------------------------------------------------------------------------

sub violates {
    my ($self, $elem, undef) = @_;

    if( $elem->name eq 'AUTOLOAD' ) {
        return $self->violation( $desc, $expl, $elem );
    }
    return; #ok!
}

1;

#--------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Critic::Policy::ClassHierarchies::ProhibitAutoloading

=head1 DESCRIPTION

Declaring a subroutine with the name C<"AUTOLOAD"> will violate this
Policy.  The C<AUTOLOAD> mechanism is an easy way to generate methods
for your classes, but unless they are carefully written, those classes
are difficult to inherit from.  And over time, the C<AUTOLOAD> method
will become more and more complex as it becomes responsible for
dispatching more and more functions.  You're better off writing
explicit accessor methods.  Editor macros can help make this a little
easier.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
