##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::TestUtils;

use strict;
use warnings;
use base 'Exporter';
use English qw(-no_match_vars);
use File::Path ();
use File::Spec ();
use File::Spec::Unix ();
use File::Temp ();
use File::Find qw( find );
use Perl::Critic ();
use Perl::Critic::PolicyFactory (-test => 1);

our $VERSION = 0.22;
our @EXPORT_OK = qw(
    pcritique critique fcritique
    subtests_in_tree run_subtest
);

#-----------------------------------------------------------------------------
# If the user already has an existing perlcriticrc file, it will get
# in the way of these test.  This little tweak to ensures that we
# don't find the perlcriticrc file.

sub block_perlcriticrc {
    no warnings 'redefine';  ## no critic (ProhibitNoWarnings);
    *Perl::Critic::UserProfile::_find_profile_path = sub { return }; ## no critic (ProtectPrivateVars)
    return 1;
}

#-----------------------------------------------------------------------------
# Criticize a code snippet using only one policy.  Returns the number
# of violations

sub pcritique {
    my($policy, $code_ref, $config_ref) = @_;
    my $c = Perl::Critic->new( -profile => 'NONE' );
    $c->add_policy(-policy => $policy, -config => $config_ref);
    my @v = $c->critique($code_ref);
    return scalar @v;
}

#-----------------------------------------------------------------------------
# Criticize a code snippet using a specified config.  Returns the
# number of violations

sub critique {
    my ($code_ref, $config_ref) = @_;
    my $c = Perl::Critic->new( %{$config_ref} );
    my @v = $c->critique($code_ref);
    return scalar @v;
}

#-----------------------------------------------------------------------------
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

sub run_subtest {
    my $policy = shift;
    my $subtest = shift;

    my $name = $subtest->{name};

    my $code = join( "\n", @{$subtest->{code}} );
    my $nfailures = $subtest->{failures};
    defined $nfailures or die "$policy, $name does not specify failures\n";

    my $parms = $subtest->{parms} ? eval $subtest->{parms} : {};

    TODO: {
        require Test::More;
        local $main::TODO = $subtest->{TODO}; # Is NOT a TODO if it's not set
        Test::More::is( pcritique($policy, \$code, $parms), $nfailures, "$policy: $name" );
    }
}

sub subtests_in_tree {
    my $start = shift;

    my %subtests;
    my $nsubtests;

    find( sub {
        if ( -f && ( $File::Find::name =~ m{\Q$start\E(.+)\.run$} ) ) {
            my $policy = $1;
            $policy =~ s{/}{::}gmsx;

            my @subtests = _subtests_from_file( $_, $File::Find::name );
            $nsubtests += @subtests;
            $subtests{ $policy } = [ @subtests ];
        }
    }, $start );
    return ( \%subtests, $nsubtests );
}


=for notes

The internal representation of a subtest is just a hash with some
named keys.  It could be an object with accessors for safety's sake,
but at this point I don't see why.

=cut

sub _subtests_from_file {
    my $test_file = shift;
    my $full_path = shift;

    my %valid_keys = map {($_,1)} qw( name failures parms TODO );

    return () unless -s $test_file; # XXX Remove me once all subtest files are populated

    open( my $fh, '<', $test_file ) or die "Couldn't open $test_file: $!";

    my @subtests = ();

    my $incode = 0;
    my $subtest;
    while ( <$fh> ) {
        chomp;
        my $inpod = /^=name/ .. /^=cut/;

        my $line = $_;

        if ( $inpod ) {
            $line =~ /^=(\S+)\s+(.+)/ or next;
            my ($key,$value) = ($1,$2);
            die "Unknown key $key in $full_path" unless $valid_keys{$key};

            if ( $key eq 'name' ) {
                if ( $subtest ) { # Stash any current subtest
                    push( @subtests, $subtest );
                    undef $subtest;
                }
                $incode = 0;
            }
            $incode && die "POD found while I'm still in code: $full_path";
            $subtest->{$key} = $value;
        }
        else {
            if ( $subtest ) {
                $incode = 1;
                push @{$subtest->{code}}, $line if $subtest; # Don't start a subtest if we're not in one
            }
            else {
                die "Got some code but I'm not in a subtest: $full_path";
            }
        }
    }
    close $fh;
    if ( $subtest ) {
        if ( $incode ) {
            push( @subtests, $subtest );
        }
        else {
            die "Incomplete subtest in $full_path";
        }
    }

    return @subtests;
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

=item run_subtest( $subtest )

=item subtests_in_tree( $dir )

=back

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Chris Dolan.  All rights reserved.

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
