########################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
########################################################################

package Perl::Critic::Policy::InputOutput::RequireBracedFileHandleWithPrint;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.14_02';
$VERSION = eval $VERSION;    ## no critic

#----------------------------------------------------------------------------

my %postfix_words = ('if' => 1, 'unless' => 1, 'for' => 1);
my $desc = q{File handle for 'print' is not braced};
my $expl = [ 211 ];

#----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_LOWEST }
sub applies_to { return 'PPI::Token::Word' }

#----------------------------------------------------------------------------

sub violates {

    my ( $self, $elem, $doc ) = @_;
    return if !($elem eq 'print');
    return if is_method_call($elem);
    return if is_hash_key($elem);

    my $sib_1 = $elem->snext_sibling()  || return;

    # Deal with situations where 'print' is called with parens
    if ( $sib_1->isa('PPI::Structure::List') ) {
        my $expr = $sib_1->schild(0) || return;
        $sib_1 = $expr->schild(0)    || return;
    }

    my $sib_2 = $sib_1->next_sibling() || return;
    my $sib_3 = $sib_2->next_sibling() || return;

    # First token must not be a builtin function
    return if is_perl_builtin($sib_1);

    # Second token must be white space
    return if !$sib_2->isa('PPI::Token::Whitespace');

    # Third token must not be an operator
    return if $sib_3->isa('PPI::Token::Operator');

    # Special case for postfix controls
    return if exists $postfix_words{ $sib_3 };

    if ( !$sib_1->isa('PPI::Structure::Block') ) {
        my $sev = $self->get_severity();
        return Perl::Critic::Violation->new( $desc, $expl, $elem, $sev );
    }

    return;  #ok!
}

1;

__END__

#----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::InputOutput::RequireBracedFileHandleWithPrint

=head1 DESCRIPTION

The C<print> function has a unique syntax that supports an optional
file handle argument.  Conway suggests wrapping this argument in
braces to make it visually stand out from the other arguments.

  print $FH   "Mary had a little lamb\n";  #not ok
  print {$FH} "Mary had a little lamb\n";  #ok

  print STDERR   $foo, $bar, $baz;  #not ok
  print {STDERR} $foo, $bar, $baz;  #ok

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
