##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::ControlStructures::ProhibitCascadingIfElse;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 1.00;

#-----------------------------------------------------------------------------

my $desc = q{Cascading if-elsif chain};
my $expl = [ 117, 118 ];

my $DEFAULT_MAX_ELSIF = 2;

#-----------------------------------------------------------------------------

sub policy_parameters { return qw( max_elsif )                       }
sub default_severity  { return $SEVERITY_MEDIUM                      }
sub default_themes    { return qw( core pbp maintenance complexity ) }
sub applies_to        { return 'PPI::Statement::Compound'            }

#-----------------------------------------------------------------------------

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;

    #Set configuration
    $self->{_max} = defined $args{max_elsif} ? $args{max_elsif}
                                             : $DEFAULT_MAX_ELSIF;

    return $self;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if ($elem->type() ne 'if');

    if ( _count_elsifs($elem) > $self->{_max} ) {
        return $self->violation( $desc, $expl, $elem );
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

Perl::Critic::Policy::ControlStructures::ProhibitCascadingIfElse

=head1 DESCRIPTION

Long C<if-elsif> chains are hard to digest, especially if they are
longer than a single page or screen.  If testing for equality, use a
hash lookup instead.  See L<Switch> for another approach.

  if ($condition1) {         #ok
      $foo = 1;
  }
  elseif ($condition2) {     #ok
      $foo = 2;
  }
  elsif ($condition3) {      #ok
      $foo = 3;
  }
  elsif ($condition4) {      #too many!
      $foo = 4;
  }
  else{                      #ok
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
