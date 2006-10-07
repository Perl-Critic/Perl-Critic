#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::Variables::ProhibitMatchVars;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.20;

#---------------------------------------------------------------------------

my $desc = q{Match variable used};
my $expl = [ 82 ];

my @forbidden = qw( $` $& $' $MATCH $PREMATCH $POSTMATCH );
my %forbidden = hashify( @forbidden );

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGH  }
sub default_themes    { return qw( risky pbp ) }
sub applies_to       { return qw( PPI::Token::Symbol
                                  PPI::Statement::Include ) }

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    if (_is_use_english($elem) || _is_forbidden_var($elem)) {
        return $self->violation( $desc, $expl, $elem );
    }
    return;  #ok!
}

#-----------------------------------------------------------------------------

sub _is_use_english {
    my $elem = shift;
    $elem->isa('PPI::Statement::Include') || return;
    $elem->type() eq 'use' || return;
    $elem->module() eq 'English' || return;
    return 1 if ($elem =~ m/\A use \s+ English \s* ;\z/xms); # Bare, lacking -no_match_vars
    return 1 if ($elem =~ m/\$(?:PRE|POST|)MATCH/xms);
    return;  # either "-no_match_vars" or a specific list
}

sub _is_forbidden_var {
    my $elem = shift;
    $elem->isa('PPI::Token::Symbol') || return;
    return exists $forbidden{$elem};
}

1;

__END__

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Variables::ProhibitMatchVars

=head1 DESCRIPTION

Using the "match variables" C<$`>, C<$&>, and/or C<$'> can
significantly degrade the performance of a program.  This policy
forbids using them or their English equivalents.  It also forbids
plain C<use English;> so you should instead employ C<use English
'-no_match_vars';> which avoids the match variables.  See B<perldoc
English> or PBP page 82 for more information.

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006 Chris Dolan.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
