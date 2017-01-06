package Perl::Critic::Policy::Miscellanea::ProhibitUnrestrictedNoCritic;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw<:severities :booleans>;
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Unrestricted '## no critic' annotation};
Readonly::Scalar my $EXPL => q{Only disable the Policies you really need to disable};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                         }
sub default_severity     { return $SEVERITY_MEDIUM           }
sub default_themes       { return qw( core maintenance )     }
sub applies_to           { return 'PPI::Document'            }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $doc, undef ) = @_;

    # If for some reason $doc is not a P::C::Document, then all bets are off
    return if not $doc->isa('Perl::Critic::Document');

    my @violations = ();
    for my $annotation ($doc->annotations()) {
        if ($annotation->disables_all_policies()) {
            my $elem = $annotation->element();
            push @violations, $self->violation($DESC, $EXPL, $elem);
        }
    }

    return @violations;
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords syntaxes

=head1 NAME

Perl::Critic::Policy::Miscellanea::ProhibitUnrestrictedNoCritic - Forbid a bare C<## no critic>


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

A bare C<## no critic> annotation will disable B<all> the active Policies.  This
creates holes for other, unintended violations to appear in your code.  It is
better to disable B<only> the particular Policies that you need to get around.
By putting Policy names in a comma-separated list after the C<## no critic>
annotation, then it will only disable the named Policies.  Policy names are
matched as regular expressions, so you can use shortened Policy names, or
patterns that match several Policies. This Policy generates a violation any
time that an unrestricted C<## no critic> annotation appears.

    ## no critic                     # not ok
    ## no critic ''                  # not ok
    ## no critic ()                  # not ok
    ## no critic qw()                # not ok

    ## no critic   (Policy1, Policy2)  # ok
    ## no critic   (Policy1 Policy2)   # ok (can use spaces to separate)
    ## no critic qw(Policy1 Policy2)   # ok (the preferred style)


=head1 NOTE

Unfortunately, L<Perl::Critic|Perl::Critic> is very sloppy about
parsing the Policy names that appear after a C<##no critic>
annotation.  For example, you might be using one of these
broken syntaxes...

    ## no critic Policy1 Policy2
    ## no critic 'Policy1, Policy2'
    ## no critic "Policy1, Policy2"
    ## no critic "Policy1", "Policy2"

In all of these cases, Perl::Critic will silently disable B<all> Policies,
rather than just the ones you requested.  But if you use the
C<ProhibitUnrestrictedNoCritic> Policy, all of these will generate
violations.  That way, you can track them down and correct them to use
the correct syntax, as shown above in the L<"DESCRIPTION">.  If you've
been using the syntax that is shown throughout the Perl::Critic
documentation for the last few years, then you should be fine.


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2008-2011 Imaginative Software Systems.  All rights reserved.

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
