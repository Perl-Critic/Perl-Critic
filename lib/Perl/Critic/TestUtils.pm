#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::TestUtils;

use strict;
use warnings;
use base 'Exporter';
use English qw(-no_match_vars);
use File::Path qw();
use File::Spec qw();
use File::Spec::Unix qw();
use File::Temp qw();
use Perl::Critic::Config (-test => 1);
use Perl::Critic;


our $VERSION = 0.21;
our @EXPORT_OK = qw(pcritique critique fcritique);

#---------------------------------------------------------------
# If the user already has an existing perlcriticrc file, it will
# get in the way of these test.  This little tweak to ensures
# that we don't find the perlcriticrc file.

sub block_perlcriticrc {
    no warnings 'redefine';  ## no critic (ProhibitNoWarnings);
    *Perl::Critic::UserProfile::find_profile_path = sub { return };
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

#----------------------------------------------------------------
# Like pcritique, but forces a PPI::Document::File context.  The
# $filename arg is a Unix-style relative path, like 'Foo/Bar.pm'

sub fcritique {
    my($policy, $code_ref, $filename, $config_ref) = @_;
    my $c = Perl::Critic->new( -profile => 'NONE' );
    $c->add_policy(-policy => $policy, -config => $config_ref);

    my $dir = File::Temp::tempdir( 'PerlCritic-tmpXXXXXX', TMPDIR => 1 );
    $filename ||= 'Temp.pm';
    my @fileparts = File::Spec::Unix->splitdir($filename);
    if (@fileparts > 1) {
        my $subdir = File::Spec->catdir($dir, @fileparts[0..$#fileparts-1]);
        File::Path::mkpath($subdir, 0, oct 700);
    }
    my $file = File::Spec->catfile($dir, @fileparts);
    if (open my $fh, '>', $file) {
        print {$fh} ${$code_ref};
        close $fh;
    }

    # Use eval so we can clean up before die() in case of error.
    my @v = eval {$c->critique($file)};
    my $err = $EVAL_ERROR;
    File::Path::rmtree($dir, 0, 1);
    if ($err) {
        die $err; ## no critic (ErrorHandling::RequireCarping)
    }
    return scalar @v;
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::TestUtils - Utility functions for testing new Policies

=head1 SYNOPSIS

  use Perl::Critic::TestUtils qw(critique pcritique fcritique);

  my $code = '<<END_CODE';
  package Foo::Bar;
  $foo = frobulator();
  $baz = $foo ** 2;
  1;
  END_CODE

  # Critique code against all loaded policies...
  my $perl_critic_config = { -severity => 2 };
  my $violation_count = critique( \$code, $perl_critic_config);

  # Critique code against one policy...
  my $custom_policy = 'Miscellanea::ProhibitFrobulation'
  my $violation_count = pcritique( $custom_policy, \$code );

  # Critique code against one filename-related policy...
  my $custom_policy = 'Modules::RequireFilenameMatchesPackage'
  my $violation_count = fcritique( $custom_policy, \$code, 'Foo/Bar.pm' );

=head1 DESCRIPTION

This module is used by L<Perl::Critic> only for self-testing. It
provides a few handy subroutines for testing new Perl::Critic::Policy
modules.  Look at the test scripts that ship with Perl::Critic for
more examples of how to use these subroutines.

=head1 EXPORTS

=over

=item critique( $code_string_ref, $config_ref )

=item pcritique( $policy_name, $code_string_ref, $config_ref )

=item fcritique( $policy_name, $code_string_ref, $filename, $config_ref )

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
