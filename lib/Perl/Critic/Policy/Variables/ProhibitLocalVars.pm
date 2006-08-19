#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::Variables::ProhibitLocalVars;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.19;

#---------------------------------------------------------------------------

my $package_rx = qr/::/mx;
my $desc = q{Variable declared as "local"};
my $expl = [ 77, 78, 79 ];

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_LOW }
sub applies_to { return 'PPI::Statement::Variable' }

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    if ( $elem->type() eq 'local' && !_all_global_vars($elem) ) {
        return $self->violation( $desc, $expl, $elem );
    }
    return;    #ok!
}

#---------------------------------------------------------------------------

sub _all_global_vars {

    my $elem = shift;
    for my $variable_name ( $elem->variables() ) {
        next if $variable_name =~ $package_rx;
        return if ! is_perl_global( $variable_name );
    }
    return 1;
}

1;

__END__

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Variables::ProhibitLocalVars

=head1 DESCRIPTION

Since Perl 5, there are very few reasons to declare C<local>
variables.  The most common exceptions are Perl's magical global
variables.  If you do need to modify one of those global variables,
you should localize it first.  You should also use the L<English>
module to give those variables more meaningful names.

  local $foo;   #not ok
  my $foo;      #ok

  use English qw(-no_match_vars);
  local $INPUT_RECORD_SEPARATOR    #ok
  local $RS                        #ok
  local $/;                        #not ok

=head1 NOTES

If an external module uses package variables as its interface, then
using C<local> is actually a pretty sensible thing to do.  So
Perl::Critic will not complain if you C<local>-ize variables with a
fully qualified name such as C<$Some::Package::foo>.  However, if
you're in a position to dictate the module's interface, I strongly
suggest using accessor methods instead.

=head1 SEE ALSO

L<Perl::Critic::Policy::Variables::ProhibitPunctuationVars>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
