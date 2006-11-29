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
use Carp qw( confess );
use English qw(-no_match_vars);
use File::Path ();
use File::Spec ();
use File::Spec::Unix ();
use File::Temp ();
use File::Find qw( find );
use Perl::Critic;
use Perl::Critic::Utils;
use Perl::Critic::PolicyFactory (-test => 1);

our $VERSION = 0.22;
our @EXPORT_OK = qw(
    pcritique critique fcritique
    subtests_in_tree
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

sub subtests_in_tree {
    my $start = shift;

    my %subtests;
    my $nsubtests;

    find( {wanted => sub {
               return if ! -f $_;
               my ($fileroot) = m{(.+)\.run\z}mx;
               return if !$fileroot;
               my @pathparts = File::Spec->splitdir($fileroot);
               if (@pathparts < 2) {
                   die 'confusing policy test filename ' . $_;
               }
               my $policy = join q{::}, $pathparts[-2], $pathparts[-1];

               my @subtests = _subtests_from_file( $_ );
               $nsubtests += @subtests;
               $subtests{ $policy } = [ @subtests ];
           }, no_chdir => 1}, $start );
    return ( \%subtests, $nsubtests );
}

=for notes

The internal representation of a subtest is just a hash with some
named keys.  It could be an object with accessors for safety's sake,
but at this point I don't see why.

=cut

sub _subtests_from_file {
    my $test_file = shift;

    my %valid_keys = hashify qw( name failures parms TODO );

    return unless -s $test_file; # XXX Remove me once all subtest files are populated

    open my $fh, '<', $test_file or confess "Couldn't open $test_file: $OS_ERROR";

    my @subtests = ();

    my $incode = 0;
    my $subtest;
    while ( <$fh> ) {
        chomp;
        my $inpod = /^## name/ .. /^## cut/;

        my $line = $_;

        if ( $inpod ) {
            $line =~ m/\A\#/mx or confess "Code before cut: $test_file";
            my ($key,$value) = $line =~ m/\A\#\#[ ](\S+)(?:\s+(.+))?/mx;
            next if !$key;
            next if $key eq 'cut';
            confess "Unknown key $key in $test_file" unless $valid_keys{$key};

            if ( $key eq 'name' ) {
                if ( $subtest ) { # Stash any current subtest
                    push( @subtests, _finalize_subtest( $subtest ) );
                    undef $subtest;
                }
                $incode = 0;
            }
            $incode && confess "POD found while I'm still in code: $test_file";
            $subtest->{$key} = $value;
        }
        else {
            if ( $subtest ) {
                $incode = 1;
                push @{$subtest->{code}}, $line if $subtest; # Don't start a subtest if we're not in one
            }
            else {
                confess "Got some code but I'm not in a subtest: $test_file";
            }
        }
    }
    close $fh;
    if ( $subtest ) {
        if ( $incode ) {
            push( @subtests, _finalize_subtest( $subtest ) );
        }
        else {
            confess "Incomplete subtest in $test_file";
        }
    }

    return @subtests;
}

sub _finalize_subtest {
    my $subtest = shift;

    if ( $subtest->{code} ) {
        $subtest->{code} = join( "\n", @{$subtest->{code}} );
    }
    else {
        confess "$subtest->{name} has no code lines";
    }
    if ( !defined $subtest->{failures} ) {
        confess "$subtest->{name} does not specify failures";
    }
    $subtest->{parms} = $subtest->{parms} ? eval $subtest->{parms} : {};

    return $subtest;
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

=item subtests_in_tree( $dir )

=back

=head1 F<.run> file information

Testing a policy follows a very simple pattern:

    * Policy name
        * Subtest name
        * Optional parameters
        * Number of failures expected

Each of the subtests for a policy is collected in a single F<.run>
file, with POD in front of each code block that describes how we
expect P::C to react to the code.  For example, say you have a
policy called Variables::ProhibitVowels:

    (In file t/Variables/ProhibitVowels.run)

    ## name Basics
    ## failures 1
    ## cut

    my $vrbl_nm = 'foo';    # Good, vowel-free name
    my $wango = 12;         # Bad, pronouncable name


    ## name Sometimes Y
    ## failures 1
    ## cut

    my $yllw = 0;       # "y" not a vowel here
    my $rhythm = 12;    # But here it is

These are called "subtests", and two are shown above.  The beauty
of the multiple-subtests-in-a-file method is that because the F<.run>
is itself a valid Perl file, and not hidden in a heredoc, your
editor's color-coding still works, and it is much easier to work
with the code and the POD.

If you need to pass special parms for your subtest, do so like this:

    ## parms { allow_y => 0 }

If it's a TODO subtest (probably because of some weird corner of
PPI that we exercised that Adam is getting around to fixing, right?),
then make a C<=TODO> POD entry.

    ## TODO Should pass when PPI 1.xxx comes out

The value of I<parms> will get C<eval>ed and passed to C<pcritique>,
so be careful.

Note that nowhere within the F<.run> file itself do you specify the
policy that you're testing.  That's implicit within the filename.

=head1 TODO items

Test that we have a t/*/*.run for each lib/*/*.pm

Allow us to specify the nature of the failures, and which one.  If
there are 15 lines of code, and six of them fail, how do we know
they're the right six?

Make the File::Find callback portable (e.g. use catfile or some such).

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
