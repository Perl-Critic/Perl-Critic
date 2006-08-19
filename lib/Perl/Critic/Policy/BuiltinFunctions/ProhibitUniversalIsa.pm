##################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##################################################################

package Perl::Critic::Policy::BuiltinFunctions::ProhibitUniversalIsa;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.19;

#----------------------------------------------------------------------------

my $desc = q{UNIVERSAL::isa should not be used as a function};
my $expl = q{Use eval{$obj->isa($pkg)} instead};  ##no critic 'RequireInterp';

#----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_MEDIUM }
sub applies_to { return 'PPI::Token::Word' }

#----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    return if !($elem eq 'isa' || $elem eq 'UNIVERSAL::isa');
    return if ! is_function_call($elem);
    return if $elem->parent()->isa('PPI::Statement::Include'); # allow 'use UNIVERSAL::isa;'

    return $self->violation( $desc, $expl, $elem );
}


1;

__END__

#------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::BuiltinFunctions::ProhibitUniversalIsa

=head1 DESCRIPTION

  print UNIVERSAL::isa($obj, 'Foo::Bar') ? 'yes' : 'no';  #not ok
  print eval { $obj->isa('Foo::Bar') } ? 'yes' : 'no';    #ok

As of Perl 5.9.3, the use of C<UNIVERSAL::isa> as a function has been
deprecated and the method form is preferred instead.  Formerly, the
functional form was recommended because it gave valid results even
when the object was C<undef> or an unblessed scalar.  However, the
functional form makes it impossible for packages to override C<isa()>,
a technique which is crucial for implementing mock objects and some
facades.

Another alternative to UNIVERSAL::isa is the C<_INSTANCE> method of
Param::Util, which is faster.

See the CPAN module L<UNIVERSAL::isa> for an incendiary discussion of
this topic.

=head1 SEE ALSO

L<Perl::Critic::Policy::BuiltinFunctions::ProhibitUniversalCan>

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006 Chris Dolan.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
