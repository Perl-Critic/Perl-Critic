#!perl

use warnings;
use strict;
use File::Find;
use PPI::Document;
use Test::More;
use Perl::Critic::TestUtils qw{ should_skip_author_tests get_author_test_skip_message };

if (should_skip_author_tests()) {
    plan skip_all => get_author_test_skip_message();
}

my %implied = (
   # Universal
   'SUPER' => 1,
);


my @pm;
find({wanted => sub {push @pm, $_ if m/\.pm\z/xms && !m/svn/xms}, no_chdir => 1}, 'lib');
plan tests => scalar @pm;
for my $file (@pm)
{
    SKIP:
   {
      my $doc = PPI::Document->new($file) || die 'Failed to parse '.$file;
      my %deps = map {$_->module => 1} @{$doc->find('PPI::Statement::Include')};
      my $thispkg = $doc->find('PPI::Statement::Package')->[0]->namespace;
      my @pkgs = @{$doc->find('PPI::Token::Word')};
      my %failed;
      for my $pkg (@pkgs)
      {
         my $name = "$pkg";
         next if ($name !~ m/::/xms);

         #diag("Check pkg $name");
         
         my $token = $pkg->next_sibling;
         if ($token =~ m/\A\(/xms)
         {
            $name =~ s/::\w+\z//xms;
         }
         if (!match($name, \%deps, $thispkg))
         {
            $failed{$name} = 1;
         }
      }
      my @failures = sort keys %failed;
      if (@failures)
      {
         diag("found deps @{[sort keys %deps]}");
         diag("Missed @failures");
      }
      ok(@failures == 0, $file);
   }
}

sub match
{
   my $pkg = shift;
   my $deps = shift;
   my $thispkg = shift;

   return 1 if ($pkg eq $thispkg);
   return 1 if ($deps->{$pkg});
   $pkg = $implied{$pkg};
   return 0 if (!defined $pkg);
   return 1 if ($pkg eq 1);
   return match($pkg, $deps, $thispkg);
}

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
