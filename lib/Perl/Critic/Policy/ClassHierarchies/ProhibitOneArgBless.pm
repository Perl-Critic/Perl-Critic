#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::ClassHierarchies::ProhibitOneArgBless;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.20;

#--------------------------------------------------------------------------

my $desc = q{One-argument "bless" used};
my $expl = [ 365 ];

#--------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGHEST  }
sub default_themes    { return qw( pbp danger )   }
sub applies_to       { return 'PPI::Token::Word' }

#--------------------------------------------------------------------------

sub violates {
    my ($self, $elem, undef) = @_;

    return if $elem ne 'bless';
    return if ! is_function_call($elem);

    if( scalar parse_arg_list($elem) == 1 ) {
        return $self->violation( $desc, $expl, $elem );
    }
    return; #ok!
}

1;

#--------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Critic::Policy::ClassHierarchies::ProhibitOneArgBless

=head1 DESCRIPTION

Always use the two-argument form of C<bless> because it allows
subclasses to inherit your constructor.

  sub new {
      my $class = shift;
      my $self = bless {};          # not ok
      my $self = bless {}, $class;  # ok
      return $self;
  }

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
