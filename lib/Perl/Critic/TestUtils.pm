package Perl::Critic::TestUtils;

use strict;
use warnings;
use base 'Exporter';
use Perl::Critic::Config (-test => 1);
use Perl::Critic;


our $VERSION = '0.18';
our @EXPORT_OK = qw(pcritique critique);

#---------------------------------------------------------------
# If the user already has an existing perlcriticrc file, it will
# get in the way of these test.  This little tweak to ensures
# that we don't find the perlcriticrc file.

sub block_perlcriticrc {
    no warnings 'redefine';  ## no critic (ProhibitNoWarnings);
    *Perl::Critic::Config::find_profile_path = sub { return };
    return 1;
}

#----------------------------------------------------------------
# Criticize a code snippet using only one policy.  Returns the number
# of violations

sub pcritique {
    my($policy, $code_ref, $config_ref) = @_;
    my $c = Perl::Critic->new( -profile => 'NONE' );
    $c->add_policy(-policy => $policy, -config => $config_ref);
    my @v = $c->critique($code_ref);
    return scalar @v;
}

#----------------------------------------------------------------
# Criticize a code snippet using a specified config.  Returns the
# number of violations

sub critique {
    my ($code_ref, $config_ref) = @_;
    my $c = Perl::Critic->new( %{$config_ref} );
    my @v = $c->critique($code_ref);
    return scalar @v;
}


1;

__END__

=pod

=head1 NAME

Perl::Critic::TestUtils - Utility functions for testing new Policies

=head1 SYNOPSIS

  use Perl::Critic::TestUtils qw(critique pcritique);

  my $code = '<<END_CODE';
  $foo = frobulator();
  $baz = $foo ** 2;
  END_CODE

  # Critique code against all loaded policies...
  my $perl_critic_config = { -severity => 2 };
  my $violation_count = critique( $code, $perl_critic_config);

  # Critique code against one policy...
  my $custom_policy = 'Miscellanea::ProhibitFrobulation'
  my $violation_count = pcritique( $code, $custom_policy );

=head1 DESCRIPTION

This module is not used directly by L<Perl::Critic> but it provides a
few handy subroutines for testing new Perl::Critic::Policy modules.
Look at the test scripts that ship with Perl::Critic for more examples
of how to use these subroutines.

=head1 EXPORTS

=over

=item critique( $policy_name, $code_string_ref )

=item pcritique( $policy_name, $string_ref, $config_ref )

=item block_perlcriticrc()

=back

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Chris Dolan.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
