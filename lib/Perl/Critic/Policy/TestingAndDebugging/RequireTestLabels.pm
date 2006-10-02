##################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##################################################################

package Perl::Critic::Policy::TestingAndDebugging::RequireTestLabels;

use strict;
use warnings;
use List::MoreUtils qw(any);
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.20;

my %label_arg_pos = (
   ok => 1,
   is => 2,
   isnt => 2,
   like => 2,
   unlike => 2,
   cmp_ok => 3,
   is_deeply => 2,
   pass => 0,
   fail => 0,
);

#----------------------------------------------------------------------------

my $desc = q{Test without a label};
my $expl = q{Add a label argument to all Test::More functions};

#----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_MEDIUM }
sub applies_to { return 'PPI::Token::Word' }

#----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;

    my $arg_index = $label_arg_pos{$elem};
    return if !defined $arg_index; # this is the fastest conditional, so do it first
    return if !is_function_call($elem);
    return if !_has_test_more($doc);

    # Does the function call have enough arguments?
    my @args = parse_arg_list($elem);
    return if ( @args > $arg_index );

    return $self->violation( $desc, $expl, $elem );
}

sub _has_test_more {
    my ( $doc ) = @_;

    my $includes = $doc->find('PPI::Statement::Include');
    return if !$includes;
    return any { $_->module() eq 'Test::More' } @{ $includes };
}

1;

#----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Critic::Policy::TestingAndDebugging::RequireTestLabels

=head1 DESCRIPTION

Most Perl modules with regression tests use L<Test::More> as
infrastructure for writing and running those tests.  It has an easy,
procedural syntax for writing comparisons of results to expectations.

Most of the Test::More functions allow the programmer to add an
optional label that describes what each test is trying to judge.  When
a test goes wrong, these labels are very useful for quickly
determining where the problem originated.

This policy enforces that all Test::More functions have labels where
applicable.  This only applies to code that has a C<use Test::More> or
C<require Test::More> declaration.

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2006 Chris Dolan.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
