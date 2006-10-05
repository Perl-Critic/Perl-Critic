##################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 7;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

my $code ;
my $policy;
my %config;

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
my $self = bless {};
my $self = bless [];

#Critic doesn't catch these,
#cuz they parse funny
# Update CJD 2006-10-05: There is a failing test for this in PPI.
# Hopefully it will be fixed in PPI v1.200.
#my $self = bless( {} );
#my $self = bless( [] );

END_PERL

$policy = 'ClassHierarchies::ProhibitOneArgBless';
is( pcritique($policy, \$code), 2, $policy );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
my $self = bless {}, 'foo';
my $self = bless( {}, 'foo' );
my $self = bless [], 'foo';
my $self = bless( [], 'foo' );
my $self = bless {} => 'foo';

$baz{bless}; # not a function call
$bar->bless('foo'); # method call

# Failure due to constructor parsing in PPI v1.118
# Uncomment when PPI v1.200 is ready
# RT 21153
#$data{"attachment_$index"} = bless([ $files->[$i] ], "Attachment");
END_PERL

$policy = 'ClassHierarchies::ProhibitOneArgBless';
is( pcritique($policy, \$code), 0, $policy );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
our @ISA = qw(Foo);
push @ISA, 'Foo';
@ISA = ('Foo');
END_PERL

$policy = 'ClassHierarchies::ProhibitExplicitISA';
is( pcritique($policy, \$code), 3, $policy );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
print @Foo::ISA;
use base 'Foo';
END_PERL

$policy = 'ClassHierarchies::ProhibitExplicitISA';
is( pcritique($policy, \$code), 0, $policy );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
sub AUTOLOAD {}
END_PERL

$policy = 'ClassHierarchies::ProhibitAutoloading';
is( pcritique($policy, \$code), 1, $policy );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
sub AUTOLOAD {
     $foo, $bar = @_;
     return $baz;
}
END_PERL

$policy = 'ClassHierarchies::ProhibitAutoloading';
is( pcritique($policy, \$code), 1, $policy );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
sub autoload {}
my $AUTOLOAD = 'foo';
our @AUTOLOAD = qw(nuts);
END_PERL

$policy = 'ClassHierarchies::ProhibitAutoloading';
is( pcritique($policy, \$code), 0, $policy );
