#######################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/common/inc/Perl/Critic/Module/Build/Standard.pm $
#     $Date: 2011-01-30 14:13:17 -0800 (Sun, 30 Jan 2011) $
#   $Author: clonezone $
# $Revision: 4016 $
########################################################################

package Perl::Critic::Module::Build::Standard;

use 5.006001;

use strict;
use warnings;

our $VERSION = '1.112_001';

use Carp;
use English qw< $OS_ERROR -no_match_vars >;


use base 'Module::Build';


sub ACTION_authortest {
    my ($self) = @_;

    $self->authortest_dependencies();
    $self->depends_on('test');

    return;
}


sub ACTION_authortestcover {
    my ($self) = @_;

    $self->authortest_dependencies();
    $self->depends_on('testcover');

    return;
}


sub ACTION_distdir {
    my ($self, @arguments) = @_;

    $self->depends_on('authortest');

    return $self->SUPER::ACTION_distdir(@arguments);
}


sub ACTION_manifest {
    my ($self, @arguments) = @_;

    # Make sure we get rid of files that no longer exist.
    if (-e 'MANIFEST') {
        unlink 'MANIFEST' or die "Can't unlink MANIFEST: $OS_ERROR";
    }

    return $self->SUPER::ACTION_manifest(@arguments);
}


sub tap_harness_args {
    my ($self) = @_;

    return $self->_tap_harness_args() if $ENV{RUNNING_UNDER_TEAMCITY};
    return;
}


sub _tap_harness_args {
    return {formatter_class => 'TAP::Formatter::TeamCity', merge => 1};
}


sub authortest_dependencies {
    my ($self) = @_;

    $self->depends_on('build');
    $self->depends_on('manifest');
    $self->depends_on('distmeta');

    $self->test_files( qw< t xt/author > );
    $self->recursive_test_files(1);

    return;
}


1;


__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Critic::Module::Build::Standard - Customization of L<Module::Build> for L<Perl::Critic> distributions.


=head1 DESCRIPTION

This is a custom subclass of L<Module::Build> that enhances existing
functionality and adds more for the benefit of installing and
developing L<Perl::Critic>.  The following actions have been added
or redefined:


=head1 ACTIONS

=over

=item authortest

Runs the regular tests plus the author tests (those in F<xt/author>).
It used to be the case that author tests were run if an environment
variable was set or if a F<.svn> directory existed.  What ended up
happening was that people that had that environment variable set for
other purposes or who had done a checkout of the code repository would
run those tests, which would fail, and we'd get bug reports for
something not expected to run elsewhere.  Now, you've got to
explicitly ask for the author tests to be run.


=item authortestcover

As C<authortest> is to the standard C<test> action, C<authortestcover>
is to the standard C<testcover> action.


=item distdir

In addition to the standard action, this adds a dependency upon the
C<authortest> action so you can't do a release without passing the
author tests.


=back


=head1 METHODS

In addition to the above actions:


=head2 C<authortest_dependencies()>

Sets up dependencies upon the C<build>, C<manifest>, and C<distmeta> actions,
adds F<xt/author> to the set of test directories, and turns on the recursive
search for tests.


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
