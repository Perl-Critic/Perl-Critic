#!/usr/bin/perl -w

# This program is a developer convenience.  It may be WRONG or out of
# date!  Run with a "-d" flag to see diffs before running for real
# with "-w" to write.  Make sure to edit the $author vars
my $SYNTAX = "Syntax: $0 [-d|-w] <name> <description> <severity>";

use warnings;
use strict;
use File::Slurp;


my $authorname  = 'Chris Dolan';
my $authoremail = 'cdolan@cpan.org';

my $action = shift;
my $name = shift;
my $description = shift;
my $severity = shift;

if (!$action || $action !~ m/\A-[dw]\z/xms ||
    !$name || $name !~ m/\A[^:]+::[^:]+\z/xms ||
    !$description ||
    !$severity || $severity !~ m/\A[1-5]\z/xms)
{
   die "$SYNTAX\n";
}

my $pkg = "Perl::Critic::Policy::$name";
(my $path = "lib/$pkg.pm") =~ s{::}{/}gxms;
if (-e $path)
{
   die "File $path already exists\n";
}

# Edit t/20_policies.t to update test count and add 2 placeholder tests
my ($cat) = $name =~ m/([^:]+)/xms;
my $lccat = lc $cat;
my $testfile = "t/20_policies_$lccat.t";
my $testskeleton = testskeleton($name);
change(sub {add_tests(2); s/\z/$testskeleton$testskeleton/xms; }, $testfile);

# Create the .pm file
if ($action eq '-w')
{
   write_file($path, moduleskeleton($name, $description, $severity));
}

# Add new policy to list in Config.pm
change(sub {s/(sub \s+ native_policy_names \s+ {[^\}]+})/::native_policies::/xms;  # extract whole sub
            my $sub = $1;
            my @mods = $sub =~ m/(Perl::Critic::Policy::\S+)/gxms;             # extract policy pkgs
            @mods = sort @mods, $pkg;                                          # add new policy and sort
            $sub =~ s/qw\([^)]+\)/join("\n      ",'qw(',@mods)."\n    )"/exms; # put policies back
            s/::native_policies::/$sub/xms; },                                 # put sub back
       'lib/Perl/Critic/PolicyFactory.pm');

# Update the number of .pm files for module tests
change(sub {add_tests(14); },'t/00_modules.t');

# Add entry in policy summary POD
change(sub {s/(=head1 \s+ POLICIES\s+)(=head2.*?)(\n=head1)/$1::policies::$3/xms;  # extract all policies
            my %pols = map {m/\A L<([^>]+)>\s+(.*?)\s*\z/xms}                      # extract policy name =>
                       split m/=head2\s+/xms, $2;                                  #         description
            $pols{$pkg} = "$description [Severity $severity]";                     # add the new one
            my $pols = join "\n", map {"=head2 L<$_>\n\n$pols{$_}\n"}              # reformat the POD entries,
                       sort keys %pols;                                            #   sorted
            s/::policies::/$pols/xms; },                                           # put policies back
       'lib/Perl/Critic/PolicySummary.pod');

# * Add it to MANIFEST (via "Build manifest")
# * Mention it in Changes
# * svn add lib/Perl/Critic/Policy/[category]/[name].pm
# * svn propset svn:keyword "HeadURL Author Revision Date" lib/Perl/Critic/Policy/[category]/[name].pm

sub add_tests
{
   # acts on $_ !!!
   my $n = shift;
   s/(use \s+ Test::More \s+ tests \s+ => \s+ )(\d+)/"$1".($2+$n)/exms;
}

sub change
{
   my $cmd = shift;
   my @files = @_;

   my @missing = grep {! -e $_} @files;
   if (@missing)
   {
      die "File(s) missing: @missing\n";
   }

   for my $file (@files)
   {
      local $_ = read_file($file);
      $cmd->();
      if ($action eq '-d')
      {
         write_file('/tmp/change', $_);
         system '/usr/bin/diff', '-u', $file, '/tmp/change';
      }
      elsif ($action eq '-w')
      {
         write_file($file, $_);
      }
   }
}

sub testskeleton
{
   my $name = shift;
   my $skeleton = <<'EOF';

#----------------------------------------------------------------

$code = <<'END_PERL';
END_PERL

$policy = '{name}';
is( pcritique($policy, \$code), 0, $policy );
EOF
   $skeleton =~ s/\{name}/$name/gxms;
   return $skeleton;
}

sub moduleskeleton
{
   my $name = shift;
   my $description = shift;
   my $severity = shift;
   my $skeleton = <<'EOF';
##################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##################################################################

package Perl::Critic::Policy::{name};

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.21;

#----------------------------------------------------------------------------

my $desc = q{{desc}};
my $expl = [ 0 ];

#----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_{severity} }
sub default_themes   { return qw({severity_theme}) }
sub applies_to       { return 'PPI::Token::Word' }

#----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;
    return $self->violation( $desc, $expl, $elem );
    return; #ok!
}

1;

#----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Critic::Policy::{name}

=head1 DESCRIPTION


=head1 AUTHOR

{authorname} <{authoremail}>

=head1 COPYRIGHT

Copyright (C) {year} {authorname}.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
EOF
   $skeleton =~ s/\{authorname}/$authorname/gxms;
   $skeleton =~ s/\{authoremail}/$authoremail/gxms;
   $skeleton =~ s/\{name}/$name/gxms;
   $skeleton =~ s/\{desc}/$description/gxms;
   my $year = [localtime]->[5]+1900;
   $skeleton =~ s/\{year}/$year/gxms;
   my %severity_words = (1 => 'LOWEST', 2 => 'LOW', 3 => 'MEDIUM',
                         4 => 'HIGH', 5 => 'HIGHEST');
   my %severity_themes = (1 => 'cosmetic', 2 => 'readability', 3 => 'unreliable',
                          4 => 'risky', 5 => 'danger');
   $skeleton =~ s/\{severity}/$severity_words{$severity}/gxms;
   $skeleton =~ s/\{severity_theme}/$severity_themes{$severity}/gxms;
   return $skeleton;
}
