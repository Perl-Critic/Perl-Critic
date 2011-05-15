#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
########################################################################

package Perl::Critic::Module::Build;

use 5.006001;

use strict;
use warnings;

our $VERSION = '1.116';

use Carp;
use English qw< $OS_ERROR $EXECUTABLE_NAME -no_match_vars >;


use base 'Perl::Critic::Module::Build::Standard';


sub ACTION_policysummary {
    my ($self) = @_;

    require Perl::Critic::PolicySummaryGenerator;
    Perl::Critic::PolicySummaryGenerator->import(
        qw< generate_policy_summary >
    );

    my $policy_summary_file = generate_policy_summary();
    $self->add_to_cleanup( $policy_summary_file );

    return;
}


sub ACTION_nytprof {
    my ($self) = @_;

    $self->depends_on('build');
    $self->_run_nytprof();

    return;
}


sub authortest_dependencies {
    my ($self) = @_;

    $self->depends_on('policysummary');
    $self->SUPER::authortest_dependencies();

    return;
}


sub _run_nytprof {
    my ($self) = @_;

    eval { require Devel::NYTProf; 1 }
        or croak 'Devel::NYTProf is required to run nytprof';

    eval { require File::Which; File::Which->import('which'); 1 }
        or croak 'File::Which is required to run nytprof';

    my $nytprofhtml = which('nytprofhtml')
        or croak 'Could not find nytprofhtml in your PATH';

    my $this_perl = $EXECUTABLE_NAME;
    my @perl_args = qw(-Iblib/lib -d:NYTProf blib/script/perlcritic);
    my @perlcritic_args =
        qw<
            --noprofile
            --severity=1
            --theme=core
            --exclude=TidyCode
            --exclude=PodSpelling
            blib
        >;
    warn "Running: $this_perl @perl_args @perlcritic_args\n";

    my $status_perlcritic = system $this_perl, @perl_args, @perlcritic_args;
    croak "perlcritic failed with status $status_perlcritic"
        if $status_perlcritic == 1;

    my $status_nytprofhtml = system $nytprofhtml;
    croak "nytprofhtml failed with status $status_nytprofhtml"
        if $status_nytprofhtml;

    return;
}


1;


__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Critic::Module::Build - Customization of L<Module::Build> for L<Perl::Critic>.


=head1 DESCRIPTION

This is a custom subclass of L<Module::Build> (actually,
L<Perl::Critic::Module::Build::Standard>) that enhances existing functionality
and adds more for the benefit of installing and developing L<Perl::Critic>.
The following actions have been added or redefined:


=head1 ACTIONS

=over

=item policysummary

Generates the F<PolicySummary.pod> file.  This should only be used by
C<Perl::Critic> developers.  This action is also invoked by the C<authortest>
action, so the F<PolicySummary.pod> file will be generated whenever you create
a distribution with the C<dist> or C<distdir> targets.


=item nytprof

Runs perlcritic under the L<Devel::NYTProf> profiler and generates
an HTML report in F<nytprof/index.html>.


=back


=head1 AUTHOR

Elliot Shank <perl@galumph.com>

=head1 COPYRIGHT

Copyright (c) 2007-2011 Elliot Shank.

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
