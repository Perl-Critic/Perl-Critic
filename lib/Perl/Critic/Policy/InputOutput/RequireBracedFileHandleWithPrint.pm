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
    my $sib_2 = $sib_1->next_sibling()  || return;
    my $sib_3 = $sib_2->snext_sibling() || return;

    # Deal with situations where 'print' is called with parens
    if ( $sib_1->isa('PPI::Structure::List') ) {
        my $expr = $sib_1->schild(0) || return;
        $sib_1 = $expr->schild(0)    || return;
        $sib_2 = $expr->child(1)     || return;
        $sib_3 = $expr->child(2)     || return;
    }

    return if $sib_1 eq $SCOLON;
    return if $sib_2 eq $SCOLON;

    if ( !$sib_1->isa('PPI::Structure::Block') ) {
        if ( !( $sib_2->isa('PPI::Token::Operator') && $sib_2 eq $COMMA) ) {
            my $sev = $self->get_severity();
            return Perl::Critic::Violation->new( $desc, $expl, $elem, $sev );
        }
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


=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
