package Perl::Critic::Policy::ControlStructures::ProhibitPostfixControls;

use strict;
use warnings;
use Perl::Critic::Violation;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = '0.13';
$VERSION = eval $VERSION;    ## no critic

my %pages_of = (
    if     => [ 93, 94 ],
    unless => [ 96, 97 ],
    until  => [ 96, 97 ],
    for    => [ 96     ],
    while  => [ 96     ],
);

my %exemptions = (
    warn    => 1, 
    die     => 1, 
    carp    => 1,
    croak   => 1,  
    cluck   => 1, 
    confess => 1,
    goto    => 1,
);

#----------------------------------------------------------------------------

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;
    $self->{_allow} = {};

    #Set config, if defined
    if ( defined $args{allow} ) {
        for my $control ( split m{ \s+ }mx, $args{allow} ) {
            $self->{_allow}->{$control} = 1;
        }
    }
    return $self;
}

sub violates {
    my ( $self, $elem, $doc ) = @_;
    $elem->isa('PPI::Token::Word') && exists $pages_of{$elem} || return;
    return if is_hash_key($elem);

    # Skip controls that are allowed
    return if exists $self->{_allow}{$elem};

    # Skip Compound variety (these are good)
    my $stmnt = $elem->statement() || return;
    return if $stmnt->isa('PPI::Statement::Compound');
    
    #Handle special cases
    if ( $elem eq 'if' ) {
	#Postfix 'if' allowed with loop breaks, or other
	#flow-controls like 'die', 'warn', and 'croak'
	return if $stmnt->isa('PPI::Statement::Break');
	return if defined $exemptions{ $stmnt->schild(0) };
    }
	
	
    # If we get here, it must be postfix.
    my $desc = qq{Postfix control '$elem' used};
    my $expl = $pages_of{$elem};
    return Perl::Critic::Violation->new( $desc, $expl, $elem->location() );
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::ControlStructures::ProhibitPostfixControls

=head1 DESCRIPTION

Conway discourages using postfix control structures (C<if>, C<for>,
C<unless>, C<until>, C<while>).  The C<unless> and C<until> controls
are particularly evil becuase the lead to double-negatives that are
hard to comprehend.  The only tolerable usage of a postfix C<if> is
when it follows a loop break such as C<last>, C<next>, C<redo>, or
C<continue>.

  do_something() if $condition;         #not ok
  if($condition){ do_something() }      #ok

  do_something() while $condition;      #not ok
  while($condition){ do_something() }   #ok

  do_something() unless $condition;     #not ok
  do_something() unless ! $condition;   #really bad
  if(! $condition){ do_something() }    #ok

  do_something() until $condition;      #not ok
  do_something() until ! $condition;    #really bad
  while(! $condition){ do_something() } #ok 

  do_something($_) for @list;           #not ok

 LOOP:
  for my $n (0..100){
      next if $condition;               #ok
      last LOOP if $other_condition;    #also ok
  }

=head1 CONSTRUCTOR

This policy accepts an additional key-value pair in the C<new> method.
The key should be 'allow' and the value is a string of space-delimited
keywords.  Choose from C<if>, C<for>, C<unless>, C<until>,and
C<while>.  When using the L<Perl::Critic> engine, these can be
configured in the F<.perlcriticrc> file like this:

 [ControlStructures::ProhibitPostfixControls]
 allow = for if until

By default, all postfix control keywords are prohibited.

=head1 NOTES

The C<die>, C<croak>, and C<confess> functions are frequently used as
flow-controls just like C<next> or C<last>.  So this Policy does
permit you to use a postfix C<if> when the statement begins with one
of those functions.  It is also pretty common to use C<warn>, C<carp>,
and C<cluck> with a postfix C<if>, so those are allowed too.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
