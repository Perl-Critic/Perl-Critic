##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::Modules::ProhibitAutomaticExportation;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use List::MoreUtils qw(any);
use base 'Perl::Critic::Policy';

our $VERSION = '1.085';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Symbols are exported by default};
Readonly::Scalar my $EXPL => q{Use '@EXPORT_OK' or '%EXPORT_TAGS' instead};  ## no critic

#-----------------------------------------------------------------------------

sub supported_parameters { return ()              }
sub default_severity     { return $SEVERITY_HIGH  }
sub default_themes       { return qw( core bugs ) }
sub applies_to           { return 'PPI::Document' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    if ( _uses_exporter($doc) ) {
        if ( my $exp = _has_exports($doc) ) {
            return $self->violation( $DESC, $EXPL, $exp );
        }
    }
    return; #ok
}

#-----------------------------------------------------------------------------

sub _uses_exporter {
    my ($doc) = @_;
    my $includes_ref = $doc->find('PPI::Statement::Include');
    return if !$includes_ref;
    #This covers both C<use Exporter;> and C<use base 'Exporter';>
    return scalar grep { m/ \b Exporter \b/mx }  @{ $includes_ref };
}

#------------------

sub _has_exports {
    my ($doc) = @_;
    my $wanted = sub {_our_EXPORT(@_) || _vars_EXPORT(@_) || _package_EXPORT(@_)};
    return $doc->find_first( $wanted );
}

#------------------

sub _our_EXPORT {
    my (undef, $elem) = @_;
    $elem->isa('PPI::Statement::Variable') || return 0;
    $elem->type() eq 'our' || return 0;
    return any { $_ eq '@EXPORT' } $elem->variables(); ## no critic(RequireInterpolationOfMetachars)
}

#------------------

sub _vars_EXPORT {
    my (undef, $elem) = @_;
    $elem->isa('PPI::Statement::Include') || return 0;
    $elem->pragma() eq 'vars' || return 0;
    return $elem =~ m{ \@EXPORT \b }mx; #Crude, but usually works
}

#------------------

sub _package_EXPORT {
    my (undef, $elem) = @_;
    $elem->isa('PPI::Token::Symbol') || return 0;
    return $elem =~ m{ \A \@ \S+ ::EXPORT \z }mx;
    #TODO: ensure that it is in _this_ package!
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Modules::ProhibitAutomaticExportation - Export symbols via C<@EXPORT_OK> or C<%EXPORT_TAGS> instead of C<@EXPORT>.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic> distribution.


=head1 DESCRIPTION

When using L<Exporter>, symbols placed in the C<@EXPORT> variable are
automatically exported into the caller's namespace.  Although
convenient, this practice is not polite, and may cause serious
problems if the caller declares the same symbols.  The best practice
is to place your symbols in C<@EXPORT_OK> or C<%EXPORT_TAGS> and let
the caller choose exactly which symbols to export.

  package Foo;

  use base qw(Exporter);
  our @EXPORT      = qw(&foo &bar);                  # not ok
  our @EXPORT_OK   = qw(&foo &bar);                  # ok
  our %EXPORT_TAGS = ( all => [ qw(&foo &bar) ] );   # ok


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


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
