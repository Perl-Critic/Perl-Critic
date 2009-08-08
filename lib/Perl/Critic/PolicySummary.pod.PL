#!perl  ## no critic (PodSpelling)
##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

# TODO: The "no critic" above is due to PodSpelling not being able to tell
# that there is no POD in this program.


use 5.006;
use 5.006001;
use strict;
use warnings;

use English qw< -no_match_vars >;
use Carp qw< confess >;

# We need both because the blib directory may or may not be in @INC at the
# time this is run.
use lib qw< blib lib >;

use Perl::Critic::Config;
use Perl::Critic::Exception::IO ();
use Perl::Critic::PolicyFactory (-test => 1);
use Perl::Critic::Utils qw< :characters >;
use Perl::Critic::Utils::POD qw< get_module_abstract_from_file >;

use Exception::Class ();  # Must be after P::C::Exception::*

our $VERSION = '1.103';


print "\n\nGenerating Perl::Critic::PolicySummary.\n";


my $configuration =
    Perl::Critic::Config->new(
        -profile => $EMPTY,
        -severity => 1,
        -theme => 'core',
    );
my @policies = $configuration->all_policies_enabled_or_not();


my $policy_summary = 'lib/Perl/Critic/PolicySummary.pod';

## no critic (RequireBriefOpen)
open my $pod_file, '>', $policy_summary
    or confess "Could not open $policy_summary: $ERRNO";

print {$pod_file} <<'END_HEADER';
=head1 NAME

Perl::Critic::PolicySummary - Descriptions of the Policy modules included with L<Perl::Critic|Perl::Critic> itself.


=head1 DESCRIPTION

The following Policy modules are distributed with Perl::Critic.
(There are additional Policies that can be found in add-on
distributions.)  The Policy modules have been categorized according to
the table of contents in Damian Conway's book B<Perl Best Practices>.
Since most coding standards take the form "do this..." or "don't do
that...", I have adopted the convention of naming each module
C<RequireSomething> or C<ProhibitSomething>.  Each Policy is listed
here with its default severity.  If you don't agree with the default
severity, you can change it in your F<.perlcriticrc> file.  See the
documentation of each module for its specific details.


=head1 POLICIES

END_HEADER


my $format = <<'END_POLICY';
=head2 L<%s>

%s [Severity %d]

END_POLICY

eval {
    foreach my $policy (@policies) {
        my $module_abstract = $policy->get_raw_abstract();

        printf
            {$pod_file}
            $format,
            $policy->get_long_name(),
            $module_abstract,
            $policy->default_severity();
    }

    1;
}
    or do {
        # Yes, an assignment and not equality test.
        if (my $exception = $EVAL_ERROR) {
            if ( ref $exception ) {
                $exception->show_trace(1);
            }

            print {*STDERR} "$exception\n";
        }
        else {
            print {*STDERR} "Failed printing abstracts for an unknown reason.\n";
        }

        exit 1;
    };


print {$pod_file} <<'END_FOOTER';

=head1 VERSION

This is part of L<Perl::Critic|Perl::Critic> version 1.103.


=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2005-2009 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
END_FOOTER


close $pod_file or confess "Could not close $policy_summary: $ERRNO";


print "Done.\n\n";


##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
