package Perl::Critic::Policy::InputOutput::RequireBracedFileHandleWithPrint;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :data_conversion };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Array my @POSTFIX_WORDS => qw( if unless for );
Readonly::Hash my %POSTFIX_WORDS => hashify( @POSTFIX_WORDS );
Readonly::Scalar my $PRINT_RX  => qr/ \A (?: print f? | say ) \z /xms;

Readonly::Scalar my $DESC => q{File handle for "print" or "printf" is not braced};
Readonly::Scalar my $EXPL => [ 217 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                      }
sub default_severity     { return $SEVERITY_LOWEST        }
sub default_themes       { return qw( core pbp cosmetic ) }
sub applies_to           { return 'PPI::Token::Word'      }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem !~ $PRINT_RX;
    return if ! is_function_call($elem);

    my @sib;

    $sib[0] = $elem->snext_sibling();
    return if !$sib[0];

    # Deal with situations where 'print' is called with parentheses
    if ( $sib[0]->isa('PPI::Structure::List') ) {
        my $expr = $sib[0]->schild(0);
        return if !$expr;
        $sib[0] = $expr->schild(0);
        return if !$sib[0];
    }

    $sib[1] = $sib[0]->next_sibling();
    return if !$sib[1];
    $sib[2] = $sib[1]->next_sibling();
    return if !$sib[2];

    # First token must be a scalar symbol or bareword;
    return if !( ($sib[0]->isa('PPI::Token::Symbol') && $sib[0] =~ m/\A \$/xms)
                 || $sib[0]->isa('PPI::Token::Word') );

    # First token must not be a builtin function or control
    return if is_perl_builtin($sib[0]);
    return if exists $POSTFIX_WORDS{ $sib[0] };

    # Second token must be white space
    return if !$sib[1]->isa('PPI::Token::Whitespace');

    # Third token must not be an operator
    return if $sib[2]->isa('PPI::Token::Operator');

    # Special case for postfix controls
    return if exists $POSTFIX_WORDS{ $sib[2] };

    return if $sib[0]->isa('PPI::Structure::Block');

    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::InputOutput::RequireBracedFileHandleWithPrint - Write C<print {$FH} $foo, $bar;> instead of C<print $FH $foo, $bar;>.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

The C<print> and C<printf> functions have a unique syntax that
supports an optional file handle argument.  Conway suggests wrapping
this argument in braces to make it visually stand out from the other
arguments.  When you put braces around any of the special
package-level file handles like C<STDOUT>, C<STDERR>, and C<DATA>, you
must the C<'*'> sigil or else it won't compile under C<use strict
'subs'>.

  print $FH   "Mary had a little lamb\n";  #not ok
  print {$FH} "Mary had a little lamb\n";  #ok

  print   STDERR   $foo, $bar, $baz;  #not ok
  print  {STDERR}  $foo, $bar, $baz;  #won't compile under 'strict'
  print {*STDERR}  $foo, $bar, $baz;  #perfect!


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>

=head1 COPYRIGHT

Copyright (c) 2005-2011 Imaginative Software Systems.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
