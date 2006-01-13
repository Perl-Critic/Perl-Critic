package criticism;

use strict;
use warnings;
use Perl::Critic;
use Carp;

#-----------------------------------------------------------------------------

my %severity_of = (
    gentle => 5,
    stern  => 4,
    harsh  => 3,
    cruel  => 2,
    brutal => 1
);

#-----------------------------------------------------------------------------

sub import {
    my ($pkg, $mood) = @_;
    my $file         = (caller)[1];
    my $sev          = $severity_of{$mood || 'gentle'};
    my $critic       = Perl::Critic->new( -severity => $sev );
    my @violations   = $critic->critique($file);
    if (@violations) { warn @violations and croak };
    return 1;
}


__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

criticism - Pragma to enforce coding style at compile-time

=head1 SYNOPSIS

  use criticism;

  use criticism 'stern';
  use criticism 'harsh';
  use criticism 'cruel';
  use criticism 'brutal';

=head1 DESCRIPTION

This pragma runs your code through L<Perl::Critic> before every
execution.  In practice, this isn't really feasible because it adds
great deal of overhead at start up.  Unless you're really sick, you're
better off using the L<perlcritic> command-line or
L<Test::Perl::Critic>.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
