##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::PolicySummaryGenerator;

use 5.006001;
use strict;
use warnings;

use Exporter 'import';

use lib qw< blib lib >;
use Carp qw< confess >;
use English qw< -no_match_vars >;

use Perl::Critic::Config;
use Perl::Critic::Exception::IO ();
use Perl::Critic::PolicyFactory (-test => 1);
use Perl::Critic::Utils qw< :characters >;
use Perl::Critic::Utils::POD qw< get_module_abstract_from_file >;

use Exception::Class ();  # Must be after P::C::Exception::*

#-----------------------------------------------------------------------------

our $VERSION = '1.116';

#-----------------------------------------------------------------------------

our @EXPORT_OK = qw< generate_policy_summary >;

#-----------------------------------------------------------------------------

sub generate_policy_summary {

    print "\n\nGenerating Perl::Critic::PolicySummary.\n";


    my $configuration =
      Perl::Critic::Config->new(-profile => $EMPTY, -severity => 1, -theme => 'core');

    my @policies = $configuration->all_policies_enabled_or_not();
    my $policy_summary = 'lib/Perl/Critic/PolicySummary.pod';

    ## no critic (RequireBriefOpen)
    open my $pod_file, '>', $policy_summary
      or confess "Could not open $policy_summary: $ERRNO";

    print {$pod_file} <<'END_HEADER';

=head1 NAME

Perl::Critic::PolicySummary - Descriptions of the Policy modules included with L<Perl::Critic|Perl::Critic> itself.


=head1 DESCRIPTION

The following Policy modules are distributed with Perl::Critic. (There are
additional Policies that can be found in add-on distributions.)  The Policy
modules have been categorized according to the table of contents in Damian
Conway's book B<Perl Best Practices>. Since most coding standards take the
form "do this..." or "don't do that...", I have adopted the convention of
naming each module C<RequireSomething> or C<ProhibitSomething>.  Each Policy
is listed here with its default severity.  If you don't agree with the default
severity, you can change it in your F<.perlcriticrc> file (try C<perlcritic
--profile-proto> for a starting version).  See the documentation of each
module for its specific details.


=head1 POLICIES

END_HEADER


my $format = <<'END_POLICY';
=head2 L<%s|%s>

%s [Default severity %d]

END_POLICY

eval {
    foreach my $policy (@policies) {
        my $module_abstract = $policy->get_raw_abstract();

        printf
            {$pod_file}
            $format,
            $policy->get_short_name(),
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

This is part of L<Perl::Critic|Perl::Critic> version 1.116.


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2005-2011 Imaginative Software Systems.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
END_FOOTER


    close $pod_file or confess "Could not close $policy_summary: $ERRNO";

    print "Done.\n\n";

    return $policy_summary;

}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Critic::PolicySummaryGenerator - Create F<PolicySummary.pod> file.


=head1 DESCRIPTION

This module contains subroutines for generating the
L<Perl::Critic::PolicySummary> POD file.  This file contains a brief
summary of all the Policies that ship with L<Perl::Critic>.  These
summaries are extracted from the C<NAME> section of the POD for each
Policy module.

This library should be used at author-time to generate the
F<PolicySummary.pod> file B<before> releasing a new distribution.  See
also the C<policysummary> action in L<Perl::Critic::Module::Build>.


=head1 IMPORTABLE SUBROUTINES

=over

=item C<generate_policy_summary()>

Generates the F<PolicySummary.pod> file which contains a brief summary of all
the Policies in this distro.  Returns the relative path this file.  Unlike
most of the other subroutines here, this subroutine should be used when
creating a distribution, not when building or installing an existing
distribution.

=back


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2009-2011 Imaginative Software Systems.  All rights reserved.

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
