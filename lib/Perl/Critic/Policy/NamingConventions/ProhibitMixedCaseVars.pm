#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseVars;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.20;

#---------------------------------------------------------------------------

my $package_rx = qr/ :: /mx;
my $mixed_rx   = qr/ [A-Z][a-z] | [a-z][A-Z] /mx;
my $desc       = 'Mixed-case variable name(s)';
my $expl       = [ 44 ];

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_LOWEST           }
sub default_themes    { return qw( pbp cosmetic )         }
sub applies_to       { return 'PPI::Statement::Variable' }

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    if ( _has_mixed_case_vars($elem) ) {
        return $self->violation( $desc, $expl, $elem );
    }
    return;    #ok!
}


sub _has_mixed_case_vars {
    my $elem = shift;
    for my $variable_name ( $elem->variables() ) {

        #Variables with fully qualified package names are exempt
        #because we can't really be responsible for symbols that
        #are defined in other packages.

        next if $elem->type() eq 'local' && $variable_name =~ $package_rx;
        return 1 if $variable_name =~ $mixed_rx;
    }
    return 0;
}

1;

__END__

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseVars

=head1 DESCRIPTION

Conway's recommended naming convention is to use lower-case words
separated by underscores.  Well-recognized acronyms can be in ALL
CAPS, but must be separated by underscores from other parts of the
name.

  my $foo_bar   #ok
  my $foo_BAR   #ok
  my @FOO_bar   #ok
  my %FOO_BAR   #ok

  my $FooBar   #not ok
  my $FOObar   #not ok
  my @fooBAR   #not ok
  my %fooBar   #not ok

=head1 SEE ALSO

L<Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseSubs>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
