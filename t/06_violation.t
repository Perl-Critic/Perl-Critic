use strict;
use warnings;
use PPI::Document;
use English qw(-no_match_vars);
use Test::More tests => 32;

#-----------------------------------------------------------------------------

BEGIN
{
    # Needs to be in BEGIN for global vars
    use_ok('Perl::Critic::Violation');
}

use lib qw(t/tlib);
use ViolationTest;   # this is solely to test the import() method; has diagnostics
use ViolationTest2;  # this is solely to test the import() method; no diagnostics
use Perl::Critic::Policy::Test;    # this is to test violation formatting

#-----------------------------------------------------------------------------
#  method tests

can_ok('Perl::Critic::Violation', 'sort_by_location');
can_ok('Perl::Critic::Violation', 'sort_by_severity');
can_ok('Perl::Critic::Violation', 'new');
can_ok('Perl::Critic::Violation', 'location');
can_ok('Perl::Critic::Violation', 'diagnostics');
can_ok('Perl::Critic::Violation', 'description');
can_ok('Perl::Critic::Violation', 'explanation');
can_ok('Perl::Critic::Violation', 'source');
can_ok('Perl::Critic::Violation', 'policy');
can_ok('Perl::Critic::Violation', 'get_format');
can_ok('Perl::Critic::Violation', 'set_format');
can_ok('Perl::Critic::Violation', 'to_string');

#-----------------------------------------------------------------------------
# Constructor Failures:
eval { Perl::Critic::Violation->new('desc', 'expl'); };
ok($EVAL_ERROR, 'new, wrong number of args');
eval { Perl::Critic::Violation->new('desc', 'expl', {}, 'severity'); };
ok($EVAL_ERROR, 'new, bad arg');

#-----------------------------------------------------------------------------
# Accessor tests

my $pkg  = __PACKAGE__;
my $code = 'Hello World;';
my $doc = PPI::Document->new(\$code);
my $no_diagnostics_msg = qr/ \s* No [ ] diagnostics [ ] available \s* /xms;
my $viol = Perl::Critic::Violation->new( 'Foo', 'Bar', $doc, 99, );

my $expected_location = $PPI::VERSION ge '1.116' ? [1,1,1] : [0,0,0];

is(        $viol->description(), 'Foo',    'description');
is(        $viol->explanation(), 'Bar',    'explanation');
is_deeply( $viol->location(),    $expected_location,  'location');
is(        $viol->severity(),    99,       'severity');
is(        $viol->source(),      $code,    'source');
is(        $viol->policy(),      $pkg,     'policy');
like(      $viol->diagnostics(), qr/ \A $no_diagnostics_msg \z /xms, 'diagnostics');

{
    local $Perl::Critic::Violation::FORMAT = '%l,%c,%m,%e,%p,%d,%r';
    my $expect = qr/\A $expected_location->[0],$expected_location->[1],Foo,Bar,$pkg,$no_diagnostics_msg,\Q$code\E \z/xms;

    like($viol->to_string(), $expect, 'to_string');
    like("$viol",            $expect, 'stringify');
}

$viol = Perl::Critic::Violation->new('Foo', [28], $doc, 99);
is($viol->explanation(), 'See page 28 of PBP', 'explanation');

$viol = Perl::Critic::Violation->new('Foo', [28,30], $doc, 99);
is($viol->explanation(), 'See pages 28,30 of PBP', 'explanation');


#-----------------------------------------------------------------------------
# Import tests
like(ViolationTest->get_violation()->diagnostics(),
     qr/ \A \s* This [ ] is [ ] a [ ] test [ ] diagnostic\. \s*\z /xms, 'import diagnostics');

#-----------------------------------------------------------------------------
# Violation sorting

SKIP: {

	#For reasons I don't yet understand these tests fail
	#on my perl at work.  So for now, I just skip them.
	skip( 'Broken on perls <= 5.6.1', 2 ) if $] <= 5.006001;

$code = <<'END_PERL';
my $foo = 1; my $bar = 2;
my $baz = 3;
END_PERL

	$doc = PPI::Document->new(\$code);
	my @children   = $doc->schildren();
	my @violations = map {Perl::Critic::Violation->new('', '', $_, 0)} $doc, @children;
	my @sorted = Perl::Critic::Violation->sort_by_location( reverse @violations);
	is_deeply(\@sorted, \@violations, 'sort_by_location');


	my @severities = (5, 3, 4, 0, 2, 1);
	@violations = map {Perl::Critic::Violation->new('', '', $doc, $_)} @severities;
	@sorted = Perl::Critic::Violation->sort_by_severity( @violations );
	is_deeply( [map {$_->severity()} @sorted], [sort @severities], 'sort_by_severity');
}

#-----------------------------------------------------------------------------
# Violation formatting

{
    my $format = '%l; %c; %m; %e; %s; %r; %P; %p; %d';
    my $expected = join q{; }, (
       1, 1,  # line, col
       'desc', 'expl',
       1, # severity
       'print;', # source near token[0]
       'Perl::Critic::Policy::Test', 'Test', # long, short
       '    diagnostic',
    );

    Perl::Critic::Violation::set_format($format);
    is(Perl::Critic::Violation::get_format(), $format, 'set/get_format');
    $code = "print;\n";
    $doc = PPI::Document->new(\$code);
    $doc->index_locations();
    my $p = Perl::Critic::Policy::Test->new();
    my @t = $doc->tokens();
    my $v = $p->violates($t[0]);
    ok($v, 'got a violation');

    is($v->to_string(), $expected, 'to_string()');
}
