##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::TestUtils;

use strict;
use warnings;
use English qw(-no_match_vars);
use Readonly;
use Carp qw( confess );

use base 'Exporter';

use File::Path ();
use File::Spec ();
use File::Spec::Unix ();
use File::Temp ();
use File::Find qw( find );

use Perl::Critic;
use Perl::Critic::Utils qw{ :data_conversion };
use Perl::Critic::PolicyFactory (-test => 1);

our $VERSION = 1.061;
Readonly::Array our @EXPORT_OK => qw(
    pcritique pcritique_with_violations
    critique  critique_with_violations
    fcritique fcritique_with_violations
    subtests_in_tree
    should_skip_author_tests
    get_author_test_skip_message
    starting_points_including_examples
    bundled_policy_names
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
# Criticize a code snippet using only one policy.  Returns the violations.

sub pcritique_with_violations {
    my($policy, $code_ref, $config_ref) = @_;
    my $c = Perl::Critic->new( -profile => 'NONE' );
    $c->add_policy(-policy => $policy, -config => $config_ref);
    return $c->critique($code_ref);
}

#-----------------------------------------------------------------------------
# Criticize a code snippet using only one policy.  Returns the number
# of violations

sub pcritique {  ##no critic(ArgUnpacking)
    return scalar pcritique_with_violations(@_);
}

#-----------------------------------------------------------------------------
# Criticize a code snippet using a specified config.  Returns the violations.

sub critique_with_violations {
    my ($code_ref, $config_ref) = @_;
    my $c = Perl::Critic->new( %{$config_ref} );
    return $c->critique($code_ref);
}

#-----------------------------------------------------------------------------
# Criticize a code snippet using a specified config.  Returns the
# number of violations

sub critique {  ##no critic(ArgUnpacking)
    return scalar critique_with_violations(@_);
}

#-----------------------------------------------------------------------------
# Like pcritique_with_violations, but forces a PPI::Document::File context.
# The $filename arg is a Unix-style relative path, like 'Foo/Bar.pm'

Readonly::Scalar my $TEMP_FILE_PERMISSIONS => oct 700;

sub fcritique_with_violations {
    my($policy, $code_ref, $filename, $config_ref) = @_;
    my $c = Perl::Critic->new( -profile => 'NONE' );
    $c->add_policy(-policy => $policy, -config => $config_ref);

    my $dir = File::Temp::tempdir( 'PerlCritic-tmpXXXXXX', TMPDIR => 1 );
    $filename ||= 'Temp.pm';
    my @fileparts = File::Spec::Unix->splitdir($filename);
    if (@fileparts > 1) {
        my $subdir = File::Spec->catdir($dir, @fileparts[0..$#fileparts-1]);
        File::Path::mkpath($subdir, 0, $TEMP_FILE_PERMISSIONS);
    }
    my $file = File::Spec->catfile($dir, @fileparts);
    if (open my $fh, '>', $file) {
        print {$fh} ${$code_ref};
        close $fh or confess "unable to close $file: $!";
    }

    # Use eval so we can clean up before die() in case of error.
    my @v = eval {$c->critique($file)};
    my $err = $EVAL_ERROR;
    File::Path::rmtree($dir, 0, 1);
    if ($err) {
        confess $err;
    }
    return @v;
}

#-----------------------------------------------------------------------------
# Like pcritique, but forces a PPI::Document::File context.  The
# $filename arg is a Unix-style relative path, like 'Foo/Bar.pm'

sub fcritique {  ##no critic(ArgUnpacking)
    return scalar fcritique_with_violations(@_);
}

sub subtests_in_tree {
    my $start = shift;

    my %subtests;

    find( {wanted => sub {
               return if ! -f $_;
               my ($fileroot) = m{(.+)\.run\z}mx;
               return if !$fileroot;
               my @pathparts = File::Spec->splitdir($fileroot);
               if (@pathparts < 2) {
                   confess 'confusing policy test filename ' . $_;
               }
               my $policy = join q{::}, @pathparts[-2, -1]; ## no critic (MagicNumbers)

               my @subtests = _subtests_from_file( $_ );
               $subtests{ $policy } = [ @subtests ];
           }, no_chdir => 1}, $start );
    return \%subtests;
}

# Answer whether author test should be run.

sub should_skip_author_tests {
    return !-d '.svn' && !$ENV{TEST_AUTHOR}
}

sub get_author_test_skip_message {
    ## no critic (RequireInterpolation);
    return 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
}

sub starting_points_including_examples {
    return (-e 'blib' ? 'blib' : 'lib', 'examples');
}

# The internal representation of a subtest is just a hash with some
# named keys.  It could be an object with accessors for safety's sake,
# but at this point I don't see why.

sub _subtests_from_file {
    my $test_file = shift;

    my %valid_keys = hashify qw( name failures parms TODO error filename );

    # XXX Remove me once all subtest files are populated
    return if -z $test_file;

    open my $fh, '<', $test_file
      or confess "Couldn't open $test_file: $OS_ERROR";

    my @subtests;

    my $incode = 0;
    my $subtest;
    my $lineno;
    while ( <$fh> ) {
        ++$lineno;
        chomp;
        my $inheader = /^## name/ .. /^## cut/; ## no critic(RegularExpression)

        my $line = $_;

        if ( $inheader ) {
            $line =~ m/\A\#/mx or confess "Code before cut: $test_file";
            my ($key,$value) = $line =~ m/\A\#\#[ ](\S+)(?:\s+(.+))?/mx;
            next if !$key;
            next if $key eq 'cut';
            confess "Unknown key $key in $test_file" if !$valid_keys{$key};

            if ( $key eq 'name' ) {
                if ( $subtest ) { # Stash any current subtest
                    push @subtests, _finalize_subtest( $subtest );
                    undef $subtest;
                }
                $subtest->{lineno} = $lineno;
                $incode = 0;
            }
            if ($incode) {
                confess "Header line found while still in code: $test_file";
            }
            $subtest->{$key} = $value;
        }
        elsif ( $subtest ) {
            $incode = 1;
            # Don't start a subtest if we're not in one
            push @{$subtest->{code}}, $line;
        }
        elsif (@subtests) {
            ## don't complain if we have not yet hit the first test
            confess "Got some code but I'm not in a subtest: $test_file";
        }
    }
    close $fh or confess "unable to close $test_file: $!";
    if ( $subtest ) {
        if ( $incode ) {
            push @subtests, _finalize_subtest( $subtest );
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
        $subtest->{code} = join "\n", @{$subtest->{code}};
    }
    else {
        confess "$subtest->{name} has no code lines";
    }
    if ( !defined $subtest->{failures} ) {
        confess "$subtest->{name} does not specify failures";
    }
    if ($subtest->{parms}) {
        $subtest->{parms} = eval $subtest->{parms}; ## no critic(StringyEval)
        if ($EVAL_ERROR) {
            confess "$subtest->{name} has an error in the 'parms' property:\n"
              . $EVAL_ERROR;
        }
        if ('HASH' ne ref $subtest->{parms}) {
            confess "$subtest->{name} 'parms' did not evaluate to a hashref";
        }
    } else {
        $subtest->{parms} = {};
    }

    if (defined $subtest->{error}) {
        if ( $subtest->{error} =~ m{ \A / (.*) / \z }xms) {
            $subtest->{error} = eval {qr/$1/};
            if ($EVAL_ERROR) {
                confess "$subtest->{name} 'error' has a malformed regular expression";
            }
        }
    }

    return $subtest;
}

sub bundled_policy_names {
    require ExtUtils::Manifest;
    my $manifest = ExtUtils::Manifest::maniread();
    my @policy_paths = map {m{\A lib/(Perl/Critic/Policy/.*).pm \z}mx} keys %{$manifest};
    my @policies = map { join q{::}, split m{/}mx, $_} @policy_paths;
    return sort @policies;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords subtest subtests

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

=item block_perlcriticrc()

If a user has a F<~/.perlcriticrc> file, this can interfere with testing.
This handy method disables the search for that file -- simply call it at the
top of your F<.t> program.  Note that this is not easily reversible, but that
should not matter.

=item critique_with_violations( $code_string_ref, $config_ref )

Test a block of code against the specified Perl::Critic::Config instance (or
C<undef> for the default).  Returns the violations that occurred.

=item critique( $code_string_ref, $config_ref )

Test a block of code against the specified Perl::Critic::Config instance (or
C<undef> for the default).  Returns the number of violations that occurred.

=item pcritique_with_violations( $policy_name, $code_string_ref, $config_ref )

Like C<critique_with_violations()>, but tests only a single policy instead of
the whole bunch.

=item pcritique( $policy_name, $code_string_ref, $config_ref )

Like C<critique()>, but tests only a single policy instead of the whole bunch.

=item fcritique_with_violations( $policy_name, $code_string_ref, $filename, $config_ref )

Like C<pcritique_with_violations()>, but pretends that the code was loaded
from the specified filename.  This is handy for testing policies like
C<Modules::RequireFilenameMatchesPackage> which care about the filename that
the source derived from.

The C<$filename> parameter must be a relative path, not absolute.  The file
and all necessary subdirectories will be created via L<File::Temp> and will be
automatically deleted.

=item fcritique( $policy_name, $code_string_ref, $filename, $config_ref )

Like C<pcritique()>, but pretends that the code was loaded from the specified
filename.  This is handy for testing policies like
C<Modules::RequireFilenameMatchesPackage> which care about the filename that
the source derived from.

The C<$filename> parameter must be a relative path, not absolute.  The file
and all necessary subdirectories will be created via L<File::Temp> and will be
automatically deleted.

=item subtests_in_tree( $dir )

Searches the specified directory recursively for F<.run> files.  Each one
found is parsed and a hash-of-list-of-hashes is returned.  The outer hash is
keyed on policy short name, like C<Modules::RequireEndWithOne>.  The inner
hash specifies a single test to be handed to C<pcritique()> or C<fcritique()>,
including the code string, test name, etc.  See below for the syntax of the
F<.run> files.

=item should_skip_author_tests()

Answers whether author tests should run.

=item get_author_test_skip_message()

Returns a string containing the message that should be emitted when a test
is skipped due to it being an author test when author tests are not enabled.

=item starting_points_including_examples()

Returns a list of the directories contain code that needs to be tested when it
is desired that the examples be included.

=item bundled_policy_names()

Returns a list of Policy packages that come bundled with this package.  This
functions by searching F<MANIFEST> for F<lib/Perl/Critic/Policy/*.pm> and
converts the results to package names.

=back

=head1 F<.run> file information

Testing a policy follows a very simple pattern:

    * Policy name
        * Subtest name
        * Optional parameters
        * Number of failures expected
        * Optional exception expected
        * Optional filename for code

Each of the subtests for a policy is collected in a single F<.run> file, with
test properties as comments in front of each code block that describes how we expect
Perl::Critic to react to the code.  For example, say you have a policy called
Variables::ProhibitVowels:

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

These are called "subtests", and two are shown above.  The beauty of
incorporating multiple subtests in a file is that the F<.run> is itself a
(mostly) valid Perl file, and not hidden in a HEREDOC, so your editor's
color-coding still works, and it is much easier to work with the code and the
POD.

If you need to pass any configuration parameters for your subtest, do so like
this:

    ## parms { allow_y => 0 }

If it's a TODO subtest (probably because of some weird corner of
PPI that we exercised that Adam is getting around to fixing, right?),
then make a C<##TODO> entry.

    ## TODO Should pass when PPI 1.xxx comes out

If the code is expected to trigger an exception in the policy, indicate that
like so:

    ## error 1

If you want to test the error message, mark it with C</.../> to indicate a
C<like()> test:

    ## error /Can't load Foo::Bar/

If the policy you are testing cares about the filename of the code, you can
indicate that C<fcritique> should be used like so (see C<fcritique> for more
details):

    ## filename lib/Foo/Bar.pm

The value of C<parms> will get C<eval>ed and passed to C<pcritique()>,
so be careful.

Note that nowhere within the F<.run> file itself do you specify the
policy that you're testing.  That's implicit within the filename.

=head1 BUGS AND CAVEATS AND TODO ITEMS

Test that we have a t/*/*.run for each lib/*/*.pm

Allow us to specify the nature of the failures, and which one.  If
there are 15 lines of code, and six of them fail, how do we know
they're the right six?

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>
and the rest of the L<Perl::Critic> team.

=head1 COPYRIGHT

Copyright (c) 2005-2007 Chris Dolan.  All rights reserved.

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
