#!perl

##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

use strict;
use warnings;
use Test::More tests => 6;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

my $code;
my $policy;
my %config;

#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------

$code = <<'END_PERL';
=pod

=head1 NO CODE IN HERE

=cut
END_PERL

$policy = 'Documentation::RequirePodSections';
is( pcritique($policy, \$code), 0, 'No code');

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
#!/usr/bin/perl
print 'Hello World';
END_PERL

$policy = 'Documentation::RequirePodSections';
is( pcritique($policy, \$code), 0, 'No POD');

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
#!/usr/bin/perl

print 'Hello World';

__END__

=head1 NAME  

Blah...

=head1   DESCRIPTION  

Blah...

=head1 USAGE

Blah...


END_PERL

$policy = 'Documentation::RequirePodSections';
is( pcritique($policy, \$code), 10, $policy);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
#No shebang, this is a library
#POD is inline with code too

=head1 NAME  

Blah...

=head1  DESCRIPTION

Blah...

=cut

print 'Hello World';

=head1  SUBROUTINES/METHODS 

Blah...

=cut

sub foobar {}

=head1 AUTHOR

Santa Claus

=cut

END_PERL

$policy = 'Documentation::RequirePodSections';
is( pcritique($policy, \$code), 8, $policy);


#-----------------------------------------------------------------------------

$code = <<'END_PERL';
#No shebang, this is a library

print 'Hello World';

__END__

=head1 MI NOMBRE

Blah...

=head1 EL DESCRIPCION

Blah...

=cut

END_PERL

%config = (lib_sections => 'mi nombre | el descripcion');
$policy = 'Documentation::RequirePodSections';
is( pcritique($policy, \$code, \%config), 0, $policy);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
#!/usr/bin/perl

__END__

=head1 MI NOMBRE

Blah...

=head1 EL DESCRIPCION

Blah...

=cut

END_PERL

%config = (script_sections => 'mi nombre | el descripcion');
$policy = 'Documentation::RequirePodSections';
is( pcritique($policy, \$code, \%config), 0, $policy);


# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
