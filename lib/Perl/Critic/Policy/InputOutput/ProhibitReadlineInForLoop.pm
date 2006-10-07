########################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::InputOutput::ProhibitReadlineInForLoop;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.20;

#----------------------------------------------------------------------------

my $desc = q{Readline inside "for" loop};
my $expl = [ 211 ];

#----------------------------------------------------------------------------

sub default_severity   { return $SEVERITY_HIGH               }
sub default_themes      { return qw( risky pbp )              }
sub applies_to         { return qw( PPI::Structure::ForLoop) }

#----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    if ( my $rl = $elem->find_first('PPI::Token::QuoteLike::Readline') ) {
        return $self->violation( $desc, $expl, $rl );
    }

    return;  #ok!
}

1;

__END__

#----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::InputOutput::ProhibitReadlineInForLoop

=head1 DESCRIPTION

Using the readline operator in a C<for> or C<foreach> loop is very
slow.  The iteration list of the loop creates a list context,
which causes the readline operator to read the entire input stream
before iteration even starts.  Instead, just use a C<while> loop,
which only reads one line at a time.

  for my $line ( <$file_handle> ){ do_something($line) }      #not ok
  while ( my $line = <$file_handle> ){ do_something($line) }  #ok

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
