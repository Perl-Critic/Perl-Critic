#!perl

##################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 14;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

my $code;
my $policy;
my %config;

#----------------------------------------------------------------

$code = <<'END_PERL';
#Nothing!
END_PERL

$policy = 'Documentation::RequirePodAtEnd';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
__END__
#Nothing!
END_PERL

$policy = 'Documentation::RequirePodAtEnd';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
=head1 Foo

=cut
END_PERL

$policy = 'Documentation::RequirePodAtEnd';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
__END__

=head1 Foo

=cut
END_PERL

$policy = 'Documentation::RequirePodAtEnd';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';

=for comment
This POD is ok
=cut

__END__

=head1 Foo

=cut
END_PERL

$policy = 'Documentation::RequirePodAtEnd';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';

=for comment
This POD is ok
=cut

=head1 Foo

This POD is illegal

=cut

=begin comment

This POD is ok

This POD is also ok

=end comment

=cut

__END__

=head1 Bar

=cut
END_PERL

$policy = 'Documentation::RequirePodAtEnd';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';

=for comment
This is a one-line comment

=cut

my $baz = 'nuts';

__END__

END_PERL

$policy = 'Documentation::RequirePodAtEnd';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';

=begin comment

Multi-paragraph comment

Mutli-paragrapm comment

=end comment

=cut

__END__

END_PERL

$policy = 'Documentation::RequirePodAtEnd';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
=pod

=head1 NO CODE IN HERE

=cut
END_PERL

$policy = 'Documentation::RequirePodSections';
is( pcritique($policy, \$code), 0, 'No code');

#----------------------------------------------------------------

$code = <<'END_PERL';
#!/usr/bin/perl
print 'Hello World';
END_PERL

$policy = 'Documentation::RequirePodSections';
is( pcritique($policy, \$code), 0, 'No POD');

#----------------------------------------------------------------

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

#----------------------------------------------------------------

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


#----------------------------------------------------------------

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

#----------------------------------------------------------------

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


