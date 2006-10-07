#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::InputOutput::ProhibitOneArgSelect;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.20;

#--------------------------------------------------------------------------

my $desc = q{One-argument "select" used};
my $expl = [ 224 ];

#--------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGH     }
sub default_themes    { return qw( risky pbp )    }
sub applies_to       { return 'PPI::Token::Word' }

#--------------------------------------------------------------------------

sub violates {
    my ($self, $elem, undef) = @_;

    return if $elem ne 'select';
    return if ! is_function_call($elem);

    if( scalar parse_arg_list($elem) == 1 ) {
        return $self->violation( $desc, $expl, $elem );
    }
    return; #ok!
}

1;

__END__

#--------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::InputOutput::ProhibitOneArgSelect

=head1 DESCRIPTION

Conway discourages the use of a raw C<select()> when setting
autoflushes.  We'll extend that further by simply prohibiting the
one-argument form of C<select()> entirely; if you really need it you
should know when/where/why that is.  For performing autoflushes,
Conway recommends the use of C<IO::Handle> instead.

  select((select($fh), $|=1)[0]);     # not ok
  select $fh;                         # not ok

   use IO::Handle;
   $fh->autoflush();                   # ok
   *STDOUT->autoflush();               # ok

=head1 SEE ALSO

L<IO::Handle>.

=head1 AUTHOR

Graham TerMarsch <graham@howlingfrog.com>

=head1 COPYRIGHT

Copyright (C) 2005-2006 Graham TerMarsch.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
