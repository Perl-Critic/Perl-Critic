package Perl::Critic::Policy::ClassHierarchies::ProhibitOneArgBless;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.13';
$VERSION = eval $VERSION; ## no critic

my $desc = q{One-argument 'bless' used};
my $expl = [ 365 ];

#--------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;
    $elem->isa('PPI::Token::Word') && $elem eq 'bless' || return;
    return if is_method_call($elem);
    return if is_hash_key($elem);
    
    if( scalar parse_arg_list($elem) == 1 ) {
	return Perl::Critic::Violation->new($desc, $expl, $elem->location() );
    }
    return; #ok!
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::ClassHierarchies::ProhibitOneArgBless

=head1 DESCRIPTION

Always use the two-argument form of C<bless> because it allows
subclasses to inherit your constructor.

  sub new {
      my $class = shift;
      my $self = bless {};          # not ok
      my $self = bless {}, $class;  # ok
      return $self;
  }

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
