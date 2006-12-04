## no critic (RequireRcsKeywords,RequirePodSections)
##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::InputOutput::ProhibitBacktickOperators;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.21_01;

#-----------------------------------------------------------------------------

my $expl = q{Use IPC::Open3 instead};
my $desc = q{Backtick operator used};

#-----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_MEDIUM }
sub default_themes   { return qw(unreliable)   }
sub applies_to       { return qw(PPI::Token::QuoteLike::Backtick
                                 PPI::Token::QuoteLike::Command ) }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    return $self->violation( $desc, $expl, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::InputOutput::ProhibitBacktickOperators

=head1 DESCRIPTION

Backticks are super-convenient, especially for CGI programs, but I
find that they make a lot of noise by filling up STDERR with messages
when they fail.  I think its better to use IPC::Open3 to trap all the
output and let the application decide what to do with it.


  use IPC::Open3 'open3';
  $SIG{CHLD} = 'IGNORE';

  @output = `some_command`;                      #not ok

  my ($writer, $reader, $err);
  open3($writer, $reader, $err, 'some_command'); #ok;
  @output = <$reader>;  #Output here
  @errors = <$err>;     #Errors here, instead of the console

=head1 NOTES

This policy also prohibits the generalized form of backticks seen as
C<qx{}>.

See L<perlipc> for more discussion on using C<wait()> instead of
C<$SIG{CHLD} = 'IGNORE'>.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
