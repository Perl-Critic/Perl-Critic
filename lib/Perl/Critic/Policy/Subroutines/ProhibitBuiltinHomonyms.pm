#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::Subroutines::ProhibitBuiltinHomonyms;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.20;

#---------------------------------------------------------------------------

my @allow = qw( import AUTOLOAD DESTROY );
my %allow = hashify( @allow );
my $desc  = q{Subroutine name is a homonym for builtin function};
my $expl  = [177];

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGH        }
sub default_themes    { return qw( risky pbp )       }
sub applies_to       { return 'PPI::Statement::Sub' }

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    return if $elem->isa('PPI::Statement::Scheduled'); #e.g. BEGIN, INIT, END
    return if exists $allow{ $elem->name() };
    if ( is_perl_builtin( $elem ) ) {
        return $self->violation( $desc, $expl, $elem );
    }
    return;    #ok!
}

1;

__END__

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::ProhibitBuiltinHomonyms

=head1 DESCRIPTION

Common sense dictates that you shouldn't declare subroutines with the
same name as one of Perl's built-in functions. See C<`perldoc
perlfunc`> for a list of built-ins.

  sub open {}  #not ok
  sub exit {}  #not ok
  sub print {} #not ok

  #You get the idea...

Exceptions are made for C<BEGIN>, C<END>, C<INIT> and C<CHECK> blocks,
as well as C<AUTOLOAD>, C<DESTROY>, and C<import> subroutines.

=head1 CAVEATS

It is reasonable to declare an B<object> method with the same name as
a Perl built-in function, since they are easily distinguished from
each other.  However, at this time, Perl::Critic cannot tell whether a
subroutine is static or an object method.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
