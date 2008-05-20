##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::TestUtilitiesWithMinimalDependencies;

use strict;
use warnings;

# do not use Readonly-- this module is used at build-time.

use base 'Exporter';

our $VERSION = '1.083_005';
our @EXPORT_OK = qw(
    get_skip_all_tests_tap
);

#-----------------------------------------------------------------------------

sub get_skip_all_tests_tap {
    return '1..0 # Skip ';
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Critic::TestUtilitiesWithMinimalDependencies - Testing functions that only depend upon L<strict>, L<warnings>, and L<Exporter>.

=head1 SYNOPSIS

  use Perl::Critic::TestUtilitiesWithMinimalDependencies qw{
      get_skip_all_tests_tap
  };

  use Test::More;

  if ($should_not_run) {
      plan skip_all => 'Hey!  I shouldn't be run!';
  }

=head1 DESCRIPTION

This module is used by L<Perl::Critic> only for self-testing. It
differs from L<Perl::Critic::TestUtils> in that it only depends upon
L<strict>, L<warnings>, and L<Exporter>.  This is important for tests
that need to hide the presence of other modules before starting.

=head1 IMPORTABLE SUBROUTINES

=over

=item C< get_skip_all_tests_tap() >

Returns a string representing the TAP (Test Anything Protocol) output
for skipping an entire file.  This is useful if you don't want to load
any Test::* modules.


=back


=head1 AUTHOR

Elliot Shank <perl@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2007-2008 Elliot Shank.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
