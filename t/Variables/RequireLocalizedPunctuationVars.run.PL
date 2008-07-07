#!perl
##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);
use Carp qw(confess);

use B::Keywords qw();
use List::MoreUtils qw< apply uniq >;

my $this_program = __FILE__;
(my $test_file_name = $this_program) =~ s/ \.PL \z //xms;
if ($this_program eq $test_file_name) {
    confess
        'Was not able to figure out the name of the file to generate.'
        . "This program: $this_program.";
}

print "\n\nGenerating $test_file_name.\n";



open my $test_file, '>', $test_file_name    ## no critic (RequireBriefOpen)
    or confess "Could not open $test_file_name: $ERRNO";

my @globals = (
    @B::Keywords::Arrays,
    @B::Keywords::Hashes,
    @B::Keywords::Scalars,
);
push @globals, uniq apply { s/ \A ([^*]) /*$1/xms } @B::Keywords::Filehandles;
my %exceptions = map {$_ => 1} qw(
    $_
    $ARG
    @_
);

my $carat_re = qr/\A [\$%]\^\w+ /xms;

my $numvars = @globals - keys %exceptions;
my $numcarats = grep {!$exceptions{$_} && m/ $carat_re /xms} @globals;

print {$test_file} <<'EOF';

## name Named magic variables, special case passes
## failures 0
## cut

local ($_, $RS) = ();
local $SIG{__DIE__} = sub { print "AAAAAAARRRRRGGGGHHHHH....\n"; };
$_ = 1;
$ARG = 1;
@_ = (1, 2, 3);

#-----------------------------------------------------------------------------

## name Named magic variables, special case failures
## failures 1
## TODO we are not handling dereferences yet...
## cut

$SIG{__DIE__} = sub { print "AAAAAAARRRRRGGGGHHHHH....\n"; };

#-----------------------------------------------------------------------------

## name Named magic variables, pass local
## failures 0
## cut

EOF

for my $varname (@globals) {
    print {$test_file} "local $varname = ();\n";
}

print {$test_file} <<"EOF";

#-----------------------------------------------------------------------------

## name Named magic variables, pass local()
## failures 0
## cut

EOF

for my $varname (@globals) {
    print {$test_file} "local ($varname) = ();\n";
}

print {$test_file} <<"EOF";

#-----------------------------------------------------------------------------

## name Named magic variables, pass (local)
## failures 0
## cut

EOF

for my $varname (@globals) {
    print {$test_file} "(local $varname) = ();\n";
}

print {$test_file} <<"EOF";

#-----------------------------------------------------------------------------

## name Named magic variables, pass = (local) =
## failures 0
## cut

EOF

for my $varname (@globals) {
    print {$test_file} "\@foo = (local $varname) = ();\n";
}

print {$test_file} <<"EOF";

#-----------------------------------------------------------------------------

## name Named magic variables, fail non-local, non-carats
## failures @{[$numvars - $numcarats]}
## cut

EOF

for my $varname (@globals) {
    next if $exceptions{$varname};
    next if $varname =~ m/ $carat_re /xms;
    print {$test_file} "$varname = ();\n";
}

print {$test_file} <<"EOF";

#-----------------------------------------------------------------------------

## name Named magic variables, fail non-local, carats
## failures $numcarats
## cut

EOF

for my $varname (@globals) {
    next if $exceptions{$varname};
    next if $varname !~ m/ $carat_re /xms;
    print {$test_file} "$varname = ();\n";
}

print {$test_file} <<"EOF";

#-----------------------------------------------------------------------------

## name Named magic variables, fail non-local, carats, no space
## failures $numcarats
## cut

EOF

for my $varname (@globals) {
    next if $exceptions{$varname};
    next if $varname !~ m/ $carat_re /xms;
    print {$test_file} "$varname= ();\n";
}

print {$test_file} <<"EOF";

#-----------------------------------------------------------------------------

## name Named magic variables, fail = (non-local) =
## failures $numvars
## cut

EOF

for my $varname (@globals) {
    next if $exceptions{$varname};
    print {$test_file} "\@foo = ($varname) = ();\n";
}

print {$test_file} <<"EOF";

#-----------------------------------------------------------------------------

## name Named magic variables, fail (non-local)
## failures $numvars
## cut

EOF

for my $varname (@globals) {
    next if $exceptions{$varname};
    print {$test_file} "($varname) = ();\n";
}


print {$test_file} <<'EOF';

#-----------------------------------------------------------------------------

## name Allow "my" as well, RT #33937
## failures 0
## cut

for my $entry (
   sort {
       my @a = split m{,}xms, $a;
       my @b = split m{,}xms, $b;
       $a[0] cmp $b[0] || $a[1] <=> $b[1]
   } qw( b,6 c,3 )
   )
{
   print;
}

#-----------------------------------------------------------------------------

##############################################################################
#      $\URL$
#     $\Date$
#   $\Author$
# $\Revision$
##############################################################################

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
EOF

close $test_file;
print "Done.\n\n";
