#############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
#############################################################################

package Perl::Critic::TAP::Formatter::Session::TeamCity;

use strict;
use warnings;

use base qw(TAP::Formatter::Session);

#----------------------------------------------------------------------------
1;

=pod

=head1 NAME

TAP::Formatter::Session::TeamCity

=head1 DESCRIPTION

L<TAP::Formatter::Session::TeamCity> is the Session delegate used by 
L<TAP::Formatter::TeamCity>.  Since TeamCity takes care of tabulating and
summarizing test results for you, there is no particular session-level
reporting that is required.  So this is basically just the minimal
L<TAP::Formatter::Session>.

=head1 AUTHOR

Jeffrey Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT   

Copyright (c) 2009 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
