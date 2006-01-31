package PerlCriticTestUtils;

use warnings;
use strict;
use base 'Exporter';
use Perl::Critic;
use Perl::Critic::Config;
our @EXPORT_OK = qw(pcritique critique);

#---------------------------------------------------------------
# If the user already has an existing perlcriticrc file, it will 
# get in the way of these test.  This little tweak to ensures 
# that we don't find the perlcriticrc file.

sub block_perlcriticrc {
    no warnings 'redefine';
    *Perl::Critic::Config::find_profile_path = sub { return };
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
