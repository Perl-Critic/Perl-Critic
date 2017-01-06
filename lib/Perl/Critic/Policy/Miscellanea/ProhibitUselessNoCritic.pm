package Perl::Critic::Policy::Miscellanea::ProhibitUselessNoCritic;

use 5.006001;
use strict;
use warnings;

use Readonly;

use List::MoreUtils qw< none >;

use Perl::Critic::Utils qw{ :severities :classification hashify };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Useless '## no critic' annotation};
Readonly::Scalar my $EXPL => q{This annotation can be removed};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                         }
sub default_severity     { return $SEVERITY_LOW              }
sub default_themes       { return qw(core maintenance)       }
sub applies_to           { return 'PPI::Document'            }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, undef, $doc ) = @_;

    # If for some reason $doc is not a P::C::Document, then all bets are off
    return if not $doc->isa('Perl::Critic::Document');

    my @violations = ();
    my @suppressed_viols = $doc->suppressed_violations();

    for my $ann ( $doc->annotations() ) {
        if ( none { _annotation_suppresses_violation($ann, $_) } @suppressed_viols ) {
            push @violations, $self->violation($DESC, $EXPL, $ann->element());
        }
    }

    return @violations;
}

#-----------------------------------------------------------------------------

sub _annotation_suppresses_violation {
    my ($annotation, $violation) = @_;

    my $policy_name = $violation->policy();
    my $line = $violation->location()->[0];

    return $annotation->disables_line($line)
        && $annotation->disables_policy($policy_name);
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::Miscellanea::ProhibitUselessNoCritic - Remove ineffective "## no critic" annotations.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic> distribution.


=head1 DESCRIPTION

Sometimes, you may need to use a C<"## no critic"> annotation to work around
a false-positive bug in L<Perl::Critic|Perl::Critic>.  But eventually, that bug might get
fixed, leaving your code with extra C<"## no critic"> annotations lying about.
Or you may use them to locally disable a Policy, but then later decide to
permanently remove that Policy entirely from your profile, making some of
those C<"## no critic"> annotations pointless.  Or, you may accidentally
disable too many Policies at once, creating an opportunity for new
violations to slip in unnoticed.

This Policy will emit violations if you have a C<"## no critic"> annotation in
your source code that does not actually suppress any violations given your
current profile.  To resolve this, you should either remove the annotation
entirely, or adjust the Policy name patterns in the annotation to match only
the Policies that are actually being violated in your code.


=head1 EXAMPLE

For example, let's say I have a regex, but I don't want to use the C</x> flag,
which violates the C<RegularExpressions::RequireExtendedFormatting> policy.
In the following code, the C<"## no critic"> annotation will suppress
violations of that Policy and ALL Policies that match
C<m/RegularExpressions/imx>

  my $re = qr/foo bar baz/ms;  ## no critic (RegularExpressions)

However, this creates a potential loop-hole for someone to introduce
additional violations in the future, without explicitly acknowledging them.
This Policy is designed to catch these situations by warning you that you've
disabled more Policies than the situation really requires.  The above code
should be remedied like this:

  my $re = qr/foo bar baz/ms;  ## no critic (RequireExtendedFormatting)

Notice how the C<RequireExtendedFormatting> pattern more precisely matches
the name of the Policy that I'm trying to suppress.


=head1 NOTE

Changing your F<.perlcriticrc> file and disabling policies globally or running
at a higher (i.e. less restrictive) severity level may cause this Policy to
emit additional violations.  So you might want to defer using this Policy
until you have a fairly stable profile.


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 ACKNOWLEDGMENT

This Policy was inspired by Adam Kennedy's article at
L<http://use.perl.org/article.pl?sid=08/09/24/1957256>.


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2005-2011 Imaginative Software Systems.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
