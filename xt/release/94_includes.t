#!perl

##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

use strict;
use warnings;

use Carp qw< confess >;

use File::Find;
use PPI::Document;

use Test::More;

#-----------------------------------------------------------------------------

our $VERSION = '1.116';

#-----------------------------------------------------------------------------

my %implied = (
    # Universal
    SUPER => 1,

    'Readonly::Scalar' => 'Readonly',
    'Readonly::Array' => 'Readonly',
    'Readonly::Hash' => 'Readonly',
);


my @pm;
find(
    {
        wanted => sub { if (m< [.] pm \z >xms && ! m<svn>xms) { push @pm, $_ } },
        no_chdir => 1,
    },
    'lib',
);
plan tests => scalar @pm;

for my $file (@pm) {
    SKIP:
    {
        my $doc = PPI::Document->new($file) or confess qq<Failed to parse "$file">;

        my @incs = @{$doc->find('PPI::Statement::Include') || []};
        my %deps = map {$_->module => 1} grep {$_->type eq 'use' || $_->type eq 'require'} @incs;
        my %thispkg = map {$_->namespace => 1} @{$doc->find('PPI::Statement::Package') || []};
        my @pkgs = @{$doc->find('PPI::Token::Word')};
        my %failed;

        for my $pkg (@pkgs) {
            my $name = "$pkg";
            next if $name !~ m/::/xms;
            next if $name =~ m/::_private::/xms;
            next if $name =~ m/List::Util::[[:lower:]]+/xms;

            # subroutine declaration with absolute name?
            # (bad form, but legal)
            my $prev_sib = $pkg->sprevious_sibling;
            next if ($prev_sib &&
                     $prev_sib eq 'sub' &&
                     !$prev_sib->sprevious_sibling &&
                     $pkg->parent->isa('PPI::Statement::Sub'));

            my $token = $pkg->next_sibling;

            if ($token =~ m< \A [(] >xms) {
                $name =~ s/::\w+\z//xms;
            }

            if ( !match($name, \%deps, \%thispkg) ) {
                $failed{$name} = 1;
            }
        }

        my @failures = sort keys %failed;
        ok(@failures == 0, "$file has an include statement for each package that it refers to.")
            or do {
                diag("Found dependencies: @{[sort keys %deps]}.");
                diag("Missing import of: @failures.");
            };
    }
}

sub match {
    my $pkg = shift;
    my $deps = shift;
    my $thispkg = shift;

    return 1 if $thispkg->{$pkg};
    return 1 if $deps->{$pkg};
    $pkg = $implied{$pkg};
    return 0 if !defined $pkg;
    return 1 if '1' eq $pkg;
    return match($pkg, $deps, $thispkg);
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/94_includes.t.t.without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
