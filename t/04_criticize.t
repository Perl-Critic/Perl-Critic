use blib;
use strict;
use warnings;
use Test::More;

eval 'use Test::Perl::Critic';
plan skip_all => 'Test::Perl::Critic required to criticise code' if $@;
all_critic_ok('lib', 'bin');