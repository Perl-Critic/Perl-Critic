##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::Variables::ProhibitPunctuationVars;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :characters :severities :data_conversion };
use base 'Perl::Critic::Policy';

our $VERSION = '1.094001';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Magic punctuation variable used};
Readonly::Scalar my $EXPL => [ 79 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'allow',
            description     => 'The additional variables to allow.',
            default_string  => $EMPTY,
            behavior        => 'string list',
            list_always_present_values =>
                                 [ qw( $_ @_ $1 $2 $3 $4 $5 $6 $7 $8 $9 _ ) ],
        },
    );
}

sub default_severity { return $SEVERITY_LOW         }
sub default_themes   { return qw(core pbp cosmetic) }
sub applies_to       { return 'PPI::Token::Magic'   }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    if ( !exists $self->{_allow}->{$elem} ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }
    return;  #ok!
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Variables::ProhibitPunctuationVars - Write C<$EVAL_ERROR> instead of C<$@>.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Perl's vocabulary of punctuation variables such as C<$!>, C<$.>, and
C<$^> are perhaps the leading cause of its reputation as inscrutable
line noise.  The simple alternative is to use the L<English|English>
module to give them clear names.

  $| = undef;                      #not ok

  use English qw(-no_match_vars);
  local $OUTPUT_AUTOFLUSH = undef;        #ok


=head1 CONFIGURATION

The scratch variables C<$_> and C<@_> are very common and are pretty
well understood, so they are exempt from this policy.  The same goes
for the less-frequently-used default filehandle C<_> used by stat().
All the regexp capture variables (C<$1>, C<$2>, ...) are exempt too.

You can add more exceptions to your configuration.  In your
perlcriticrc file, add a block like this:

  [Variables::ProhibitPunctuationVars]
  allow = $@ $!

The C<allow> property should be a whitespace-delimited list of
punctuation variables.


=head1 BUGS

This doesn't find punctuation variables in strings.  RT #35970.


=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2005-2009 Jeffrey Ryan Thalhammer.  All rights reserved.

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
