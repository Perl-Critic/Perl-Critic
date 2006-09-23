#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
if (!$ENV{TEST_AUTHOR}) {
    plan skip_all => 'Author test';
}

eval
{
   require Test::Kwalitee;
   Test::Kwalitee->import( tests => [ '-no_symlinks' ] );
};
plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;
