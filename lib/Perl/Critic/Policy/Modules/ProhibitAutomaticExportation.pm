#######################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/Perl-Critic/lib/Perl/Critic/Policy/Modules/RequireVersionVar.pm $
#     $Date: 2006-04-28 23:36:18 -0700 (Fri, 28 Apr 2006) $
#   $Author: thaljef $
# $Revision: 396 $
########################################################################

package Perl::Critic::Policy::Modules::ProhibitAutomaticExportation;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use List::MoreUtils qw(any);
use base 'Perl::Critic::Policy';

our $VERSION = '0.15_03';
$VERSION = eval $VERSION;    ## no critic

#---------------------------------------------------------------------------

my $desc = q{Symbols are exported by default};
my $expl = q{Use '@EXPORT_OK' or '%EXPORT_TAGS' instead};

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGH }
sub applies_to { return 'PPI::Document' }

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    if ( _uses_exporter($doc) ) {
        if ( my $exp = _has_exports($doc) ) {
            my $sev = $self->get_severity();
            return Perl::Critic::Violation->new( $desc, $expl, $exp, $sev );
        }
    }
    return; #ok
}

#---------------------------------------------------------------------------

sub _uses_exporter {
    my ($doc) = @_;
    my $includes_ref = $doc->find('PPI::Statement::Include') || return;
    #This covers both C<use 'Exporter';> and C<use base 'Exporter';>
    return scalar grep { m/ \b Exporter \b/mx }  @{ $includes_ref };
}

#------------------

sub _has_exports {
    my ($doc) = @_;
    my $wanted = sub { _our_EXPORT(@_) || _vars_EXPORT(@_) || _package_EXPORT(@_) };
    return $doc->find_first( $wanted );
}

#------------------

sub _our_EXPORT {
    my ($doc, $elem) = @_;
    $elem->isa('PPI::Statement::Variable') || return 0;
    $elem->type() eq 'our' || return 0;
    return any { $_ eq '@EXPORT' } $elem->variables(); ## no critic
}

#------------------

sub _vars_EXPORT {
    my ($doc, $elem) = @_;
    $elem->isa('PPI::Statement::Include') || return 0;
    $elem->pragma() eq 'vars' || return 0;
    return $elem =~ m{ \@EXPORT }mx; #Crude, but usually works
}

#------------------

sub _package_EXPORT {
    my ($doc, $elem) = @_;
    $elem->isa('PPI::Token::Symbol') || return 0;
    return $elem =~ m{ \A \@ \S+ ::EXPORT \z }mx;
    #TODO: ensure that it is in _this_ package!
}

1;

__END__

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Modules::ProhibitAutomaticExportation

=head1 DESCRIPTION

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
