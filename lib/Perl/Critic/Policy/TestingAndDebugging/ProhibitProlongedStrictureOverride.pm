##################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##################################################################

package Perl::Critic::Policy::TestingAndDebugging::ProhibitProlongedStrictureOverride;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.21;

#----------------------------------------------------------------------------

my $desc = q{Don't turn off strict for large blocks of code};
my $expl = [ 433 ];

#----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGH }
sub default_themes   { return qw(risky) }
sub applies_to       { return 'PPI::Statement::Include' }

#----------------------------------------------------------------------------

sub new {
    my ( $class, %config ) = @_;
    my $self = bless {}, $class;

    $self->{_lines} = 3;
    if ( defined $config{lines} ) {
        $self->{_lines} = $config{lines};
    }

    return $self;
}

#---------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;

    return if $elem->type ne 'no';
    return if $elem->module ne 'strict';

    my $sib = $elem->snext_sibling;
    my $lines = 0;
    while ($lines++ <= $self->{_lines}) {
        return if !$sib;
        return if $sib->isa('PPI::Statement::Include') &&
            $sib->type eq 'use' &&
            $sib->module eq 'strict';
       $sib = $sib->snext_sibling;
    }

    return $self->violation( $desc, $expl, $elem );
}

1;

#----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Critic::Policy::TestingAndDebugging::ProhibitProlongedStrictureOverride

=head1 DESCRIPTION


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2006 Chris Dolan.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
