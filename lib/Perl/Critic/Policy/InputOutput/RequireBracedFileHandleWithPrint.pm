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
use base 'Perl::Critic::Policy';

our $VERSION = '0.18';
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
    return if is_subroutine_name($elem);

    my @sib;
    $sib[0] = $elem->snext_sibling()  || return;

    # Deal with situations where 'print' is called with parens
    if ( $sib[0]->isa('PPI::Structure::List') ) {
        my $expr = $sib[0]->schild(0) || return;
        $sib[0] = $expr->schild(0)    || return;
    }

    $sib[1] = $sib[0]->next_sibling() || return;
    $sib[2] = $sib[1]->next_sibling() || return;

    # First token must be a symbol or bareword;
    return if !(    $sib[0]->isa('PPI::Token::Symbol')
                 || $sib[0]->isa('PPI::Token::Word') );

    # First token must not be a builtin function
    return if is_perl_builtin($sib[0]);

    # Second token must be white space
    return if !$sib[1]->isa('PPI::Token::Whitespace');

    # Third token must not be an operator
    return if $sib[2]->isa('PPI::Token::Operator');

    # Special case for postfix controls
    return if exists $postfix_words{ $sib[2] };

    if ( !$sib[0]->isa('PPI::Structure::Block') ) {
        return $self->violation( $desc, $expl, $elem );
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
braces to make it visually stand out from the other arguments.  When
you put braces around any of the special package-level file handles
like C<STDOUT>, C<STDERR>, and C<DATA>, you must the C<'*'> sigil or
else it won't compile under C<use strict 'subs'>.

  print $FH   "Mary had a little lamb\n";  #not ok
  print {$FH} "Mary had a little lamb\n";  #ok

  print   STDERR   $foo, $bar, $baz;  #not ok
  print  {STDERR}  $foo, $bar, $baz;  #won't compile under 'strict'
  print {*STDERR}  $foo, $bar, $baz;  #perfect!

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
