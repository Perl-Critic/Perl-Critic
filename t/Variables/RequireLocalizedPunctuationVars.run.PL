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
(my $test_file_name = $this_program) =~ s< [.] PL \z ><>xms;
if ($this_program eq $test_file_name) {
    confess
        'Was not able to figure out the name of the file to generate.'
        . "This program: $this_program.";
}

print "\n\nGenerating $test_file_name.\n";


my @globals = (
    @B::Keywords::Arrays,
    @B::Keywords::Hashes,
    @B::Keywords::Scalars,
);
push @globals, uniq apply { s/ \A ([^*]) /*$1/xms } @B::Keywords::Filehandles;
my %exemptions = map {$_ => 1} qw(
    $_
    $ARG
    @_
);

my $carat_re = qr/\A [\$%]\^\w+ /xms;

my $numvars = @globals - keys %exemptions;
my $numcarats = grep {!$exemptions{$_} && m/ $carat_re /xms} @globals;


open my $test_file, '>', $test_file_name    ## no critic (RequireBriefOpen)
    or confess "Could not open $test_file_name: $ERRNO";

print_header($test_file);
print_pass_local($test_file, \@globals);
print_pass_local_deref($test_file, \@globals);
print_pass_non_local_exception($test_file, \@globals);
print_fail_non_local($test_file, \@globals, $numvars, $numcarats);
print_fail_non_local_deref($test_file, \@globals);
print_footer($test_file);

close $test_file
    or confess "Could not close $test_file_name: $ERRNO";

print "Done.\n\n";

sub print_header {
    my ($test_file) = @_;

    print {$test_file} <<'END_CODE';

## name Named magic variables, special case passes
## failures 0
## cut

local ($_, $RS) = ();
local $SIG{__DIE__} = sub { print "AAAAAAARRRRRGGGGHHHHH....\n"; };
$_ = 1;
$ARG = 1;
@_ = (1, 2, 3);

#-----------------------------------------------------------------------------

END_CODE

    return;
}

sub print_pass_local {
    my ($test_file, $globals) = @_;

    print {$test_file} <<'END_CODE';
## name Named magic variables, pass local
## failures 0
## cut

END_CODE

    for my $varname (@{$globals}) {
        print {$test_file} "local $varname = ();\n";
    }

    print {$test_file} <<"END_CODE";

#-----------------------------------------------------------------------------

## name Named magic variables, pass local()
## failures 0
## cut

END_CODE

    for my $varname (@{$globals}) {
        print {$test_file} "local ($varname) = ();\n";
    }

    print {$test_file} <<"END_CODE";

#-----------------------------------------------------------------------------

## name Named magic variables, pass (local)
## failures 0
## cut

END_CODE

    for my $varname (@{$globals}) {
        print {$test_file} "(local $varname) = ();\n";
    }

    print {$test_file} <<"END_CODE";

#-----------------------------------------------------------------------------

## name Named magic variables, pass = (local) =
## failures 0
## cut

END_CODE

    for my $varname (@{$globals}) {
        print {$test_file} "\@foo = (local $varname) = ();\n";
    }

    return;
}


sub print_pass_local_deref {
    my ($test_file, $globals) = @_;

    my %subscript = (
        '%' => '{foo}',
        '@' => '[0]',
    );

    my @derefs = grep { $subscript{substr $_, 0, 1} } @{ $globals };

    print {$test_file} <<"END_CODE";

#-----------------------------------------------------------------------------

## name Named magic variables, pass local dereferenced
## failures 0
## cut

END_CODE

    foreach my $varname ( @derefs ) {
        my ($sigil, $barename) = $varname =~ m/ (.)(.*) /smx;
        print {$test_file} 'local $', $barename,
            $subscript{$sigil}, " = 'bar';\n";
    }

}


sub print_pass_non_local_exception {
    my ($test_file, $globals) = @_;

    (my $except = "@$globals") =~ s< ([\\']) ><\\$1>gmsx;
    print {$test_file} <<"END_CODE";

#-----------------------------------------------------------------------------

## name Named magic variables, pass non-local but in exception list
## failures 0
## parms { allow => '$except' }
## cut

END_CODE

    foreach my $varname (@{$globals}) {
        next if $exemptions{$varname};
        print {$test_file} "$varname = ();\n";
    }
}


sub print_fail_non_local {
    my ($test_file, $globals, $numvars, $numcarats) = @_;

    print {$test_file} <<"END_CODE";

#-----------------------------------------------------------------------------

## name Named magic variables, fail non-local, non-carats
## failures @{[$numvars - $numcarats]}
## cut

END_CODE

    for my $varname (@{$globals}) {
        next if $exemptions{$varname};
        next if $varname =~ m/ $carat_re /xms;
        print {$test_file} "$varname = ();\n";
    }

    print {$test_file} <<"END_CODE";

#-----------------------------------------------------------------------------

## name Named magic variables, fail non-local, carats
## failures $numcarats
## cut

END_CODE

    for my $varname (@{$globals}) {
        next if $exemptions{$varname};
        next if $varname !~ m/ $carat_re /xms;
        print {$test_file} "$varname = ();\n";
    }

    print {$test_file} <<"END_CODE";

#-----------------------------------------------------------------------------

## name Named magic variables, fail non-local, carats, no space
## failures $numcarats
## cut

END_CODE

    for my $varname (@{$globals}) {
        next if $exemptions{$varname};
        next if $varname !~ m/ $carat_re /xms;
        print {$test_file} "$varname= ();\n";
    }

    print {$test_file} <<"END_CODE";

#-----------------------------------------------------------------------------

## name Named magic variables, fail = (non-local) =
## failures $numvars
## cut

END_CODE

    for my $varname (@{$globals}) {
        next if $exemptions{$varname};
        print {$test_file} "\@foo = ($varname) = ();\n";
    }

    print {$test_file} <<"END_CODE";

#-----------------------------------------------------------------------------

## name Named magic variables, fail (non-local)
## failures $numvars
## cut

END_CODE

    for my $varname (@{$globals}) {
        next if $exemptions{$varname};
        print {$test_file} "($varname) = ();\n";
    }

    return;
}


sub print_fail_non_local_deref {
    my ($test_file, $globals) = @_;

    my %subscript = (
        '%' => '{foo}',
        '@' => '[0]',
    );

    my @derefs = grep { $subscript{substr $_, 0, 1} && !$exemptions{$_} }
        @{ $globals };
    my $numvars = scalar @derefs;

    print {$test_file} <<"END_CODE";

#-----------------------------------------------------------------------------

## name Named magic variables, fail non-local dereferenced
## failures $numvars
## cut

END_CODE

    foreach my $varname ( @derefs ) {
        my ($sigil, $barename) = $varname =~ m/ (.)(.*) /smx;
        print {$test_file} '$', $barename,
            $subscript{$sigil}, " = 'bar';\n";
    }

}


sub print_footer {
    my ($test_file) = @_;

    print {$test_file} <<'END_CODE';

#-----------------------------------------------------------------------------

## name Allowing a variable with a particular sigil doesn't allow other variables with the same name but different sigils
## failures 1
## parms { allow => '$ARGV' }
## cut

@ARGV = (1, 2, 3);

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
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
END_CODE

    return;
}

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
