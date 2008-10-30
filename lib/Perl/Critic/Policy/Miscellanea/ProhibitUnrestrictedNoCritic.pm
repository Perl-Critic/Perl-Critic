##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/Perl-Critic/lib/Perl/Critic/Policy/Miscellanea/ProhibitFormats.pm $
#     $Date: 2008-09-07 03:33:32 -0700 (Sun, 07 Sep 2008) $
#   $Author: clonezone $
# $Revision: 2730 $
##############################################################################

package Perl::Critic::Policy::Miscellanea::ProhibitUnrestrictedNoCritic;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw<:severities :booleans>;
use base 'Perl::Critic::Policy';

our $VERSION = '1.093_02';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Unrestriced '## no critic' pseudo-pragma};
Readonly::Scalar my $EXPL => q{Only disable the Policies you really need to disable};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                         }
sub default_severity     { return $SEVERITY_MEDIUM           }
sub default_themes       { return qw( core maintenance )     }
sub applies_to           { return 'PPI::Token::Comment'      }

#-----------------------------------------------------------------------------
# TODO: Consolidate these regexen with those used in Critic.pm

sub violates {
    my ( $self, $elem, undef ) = @_;
    $elem =~ m{\A \#\# \s* no \s+ critic \s* (.*) \z}smx
        or return;

    if ($1 !~ m{\A (?: qw)? \s* [("'] \s* \w+ }smx ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }

    return; # ok!
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Miscellanea::ProhibitUnrestrictedNoCritic - Forbid a bare C<## no critic>

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.

=head1 DESCRIPTION

A bare C<## no critic> marker will disable B<all> the active Policies.  This
creates holes for other, unintended violations to appear in your code.  It is
better to disable B<only> the particular Policies that you need to get around.
By putting Policy names in a comma-separated list after the C<## no critic>
marker, then it will only disable the named Policies.  Policy names are
matched as regular expressions, so you can use shortened Policy names, or
patterns that match several Policies. This Policy generates a violation any
time that an unrestricted C<## no critic> marker appears.

  ## no critic                     # not ok
  ## no critic ''                  # not ok
  ## no critic ()                  # not ok
  ## no critic qw()                # not ok

  ## no critic    Policy1, Policy2   # ok
  ## no critic   'Policy1, Policy2'  # ok
  ## no critic   (Policy1, Policy2)  # ok
  ## no critic qw(Policy1, Policy2)  # ok (the preferred style)

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

###############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
