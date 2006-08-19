#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::Variables::ProhibitPunctuationVars;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.19;

#---------------------------------------------------------------------------

my $desc = q{Magic punctuation variable used};
my $expl = [ 79 ];

## no critic
my %default_exempt = hashify(
  '$_', '@_',
  '$1', '$2', '$3', '$4', '$5', '$6', '$7', '$8', '$9',
  '_',   # default filehandle for stat()
);
## use critic

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_LOW }
sub applies_to { return 'PPI::Token::Magic' }

#---------------------------------------------------------------------------

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;

    $self->{_exempt} = {%default_exempt};
    if ( defined $args{allow} ) {
        my @allow = split m{ \s+ }mx, $args{allow};
        for my $varname (@allow) {
           $self->{_exempt}->{$varname} = 1;
        }
    }

    return $self;
}

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    if ( !exists $self->{_exempt}->{$elem} ) {
        return $self->violation( $desc, $expl, $elem );
    }
    return;  #ok!
}

1;

__END__

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Variables::ProhibitPunctuationVars

=head1 DESCRIPTION

Perl's vocabulary of punctuation variables such as C<$!>, C<$.>, and
C<$^> are perhaps the leading cause of its reputation as inscrutable
line noise.  The simple alternative is to use the L<English> module to
give them clear names.

  $| = undef;                      #not ok

  use English qw(-no_match_vars);
  local $OUTPUT_AUTOFLUSH = undef;        #ok

=head1 EXCEPTIONS

The scratch variables C<$_> and C<@_> are very common and have no
equivalent name in L<English>, so they are exempt from this policy.
The same goes for the less-frequently-used default filehandle C<_>
used by stat().  All the regexp capture variables (C<$1>, C<$2>, ...)
are exempt too.

You can add more exceptions to your configuration.  In your
perlcriticrc file, add a block like this:

  [Variables::ProhibitPunctuationVars]
  allow = $@ $!

The C<allow> property should be a whitespace-delimited list of
punctutation variables.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
