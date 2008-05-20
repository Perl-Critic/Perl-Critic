##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::Modules::RequireVersionVar;

use strict;
use warnings;
use Readonly;

use List::MoreUtils qw(any);

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.083_005';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{No "VERSION" variable found};
Readonly::Scalar my $EXPL => [ 404 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                       }
sub default_severity     { return $SEVERITY_LOW            }
sub default_themes       { return qw(core pbp readability) }
sub applies_to           { return 'PPI::Document'          }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    return if $doc->find_first( \&_is_VERSION_declaration );

    #If we get here, then no $VERSION was found
    return $self->violation( $DESC, $EXPL, $doc );
}

#-----------------------------------------------------------------------------

sub _is_VERSION_declaration {  ##no critic(ArgUnpacking)
    return 1 if _is_our_VERSION(@_);
    return 1 if _is_vars_VERSION(@_);
    return 1 if _is_package_VERSION(@_);
    return 1 if _is_readonly_VERSION(@_);
    return 0;
}

#-----------------------------------------------------------------------------

sub _is_our_VERSION {
    my (undef, $elem) = @_;
    $elem->isa('PPI::Statement::Variable') || return 0;
    $elem->type() eq 'our' || return 0;
    return any { $_ eq '$VERSION' } $elem->variables(); ## no critic
}

#-----------------------------------------------------------------------------

sub _is_vars_VERSION {
    my (undef, $elem) = @_;
    $elem->isa('PPI::Statement::Include') || return 0;
    $elem->pragma() eq 'vars' || return 0;
    return $elem =~ m{ \$VERSION }mx; #Crude, but usually works
}

#-----------------------------------------------------------------------------

sub _is_package_VERSION {
    my (undef, $elem) = @_;
    $elem->isa('PPI::Token::Symbol') || return 0;
    return $elem =~ m{ \A \$ \S+ ::VERSION \z }mx;
    #TODO: ensure that it is in _this_ package!
}

#-----------------------------------------------------------------------------

sub _is_readonly_VERSION {

    #---------------------------------------------------------------
    # Readonly VERSION statements usually come in one of two forms:
    #
    #   Readonly our $VERSION = 1.0;
    #   Readonly::Scalar our $VERSION = 1.0;
    #---------------------------------------------------------------

    my (undef, $elem) = @_;
    $elem->isa('PPI::Token::Symbol') || return 0;
    return 0 if $elem !~ m{ \A \$VERSION \z }mx;

    my $psib = $elem->sprevious_sibling() || return 0;
    return 0 if $psib ne 'our';

    my $ppsib = $psib->sprevious_sibling() || return 0;
    return $ppsib eq 'Readonly' || $ppsib eq 'Readonly::Scalar';
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Modules::RequireVersionVar - Give every module a C<$VERSION> number.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic> distribution.


=head1 DESCRIPTION

Every Perl file (modules, libraries, and programs) should have a
C<$VERSION> variable.  The C<$VERSION> allows clients to insist on a
particular revision of your file like this:

  use SomeModule 2.4;  #Only loads version 2.4

This Policy scans your file for any package variable named
C<$VERSION>.  I'm assuming that you are using C<strict>, so you'll
have to declare it like one of these:

  our $VERSION = 1.0611;
  $MyPackage::VERSION = 1.061;
  use vars qw($VERSION);

A common practice is to use the C<$Revision$> keyword to automatically
define the C<$VERSION> variable like this:

  our ($VERSION) = '$Revision$' =~ m{ \$Revision: \s+ (\S+) }x;


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 NOTES

Conway recommends using the C<version> pragma instead of raw numbers
or 'v-strings.'  However, this Policy only insists that the
C<$VERSION> be defined somehow.  I may try to extend this in the
future.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2008 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
