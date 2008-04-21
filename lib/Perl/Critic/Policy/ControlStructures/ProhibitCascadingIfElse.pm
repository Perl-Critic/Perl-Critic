##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::ControlStructures::ProhibitCascadingIfElse;

use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.083_001';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Cascading if-elsif chain};
Readonly::Scalar my $EXPL => [ 117, 118 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'max_elsif',
            description     => 'The maximum number of alternatives that will be allowed.',
            default_string  => '2',
            behavior        => 'integer',
            integer_minimum => 1,
        },
    );
}

sub default_severity { return $SEVERITY_MEDIUM                      }
sub default_themes   { return qw( core pbp maintenance complexity ) }
sub applies_to       { return 'PPI::Statement::Compound'            }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if ($elem->type() ne 'if');

    if ( _count_elsifs($elem) > $self->{_max_elsif} ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }
    return;    #ok!
}

sub _count_elsifs {
    my $elem = shift;
    return
      grep { $_->isa('PPI::Token::Word') && $_ eq 'elsif' } $elem->schildren();
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords lookup

=head1 NAME

Perl::Critic::Policy::ControlStructures::ProhibitCascadingIfElse - Don't write long "if-elsif-elsif-elsif-elsif...else" chains.

=head1 DESCRIPTION

Long C<if-elsif> chains are hard to digest, especially if they are
longer than a single page or screen.  If testing for equality, use a
hash lookup instead.  See L<Switch> for another approach.

  if ($condition1) {         #ok
      $foo = 1;
  }
  elsif ($condition2) {      #ok
      $foo = 2;
  }
  elsif ($condition3) {      #ok
      $foo = 3;
  }
  elsif ($condition4) {      #too many!
      $foo = 4;
  }
  else {                     #ok
      $foo = $default;
  }

=head1 CONFIGURATION

This policy can be configured with a maximum number of C<elsif> alternatives
to allow.  The default is 2.  This can be specified via a C<max_elsif> item in
the F<.perlcriticrc> file:

 [ControlStructures::ProhibitCascadingIfElse]
 max_elsif = 3

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2008 Jeffrey Ryan Thalhammer.  All rights reserved.

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
