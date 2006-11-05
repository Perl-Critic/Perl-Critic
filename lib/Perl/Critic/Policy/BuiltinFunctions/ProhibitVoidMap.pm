##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
##############################################################################

package Perl::Critic::Policy::BuiltinFunctions::ProhibitVoidMap;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.21;

#----------------------------------------------------------------------------

my $desc = q{"map" used in void context};
my $expl = [];

#----------------------------------------------------------------------------

sub default_severity  { return $SEVERITY_MEDIUM     }
sub default_themes    { return qw(pbp unreliable)   }
sub applies_to        { return 'PPI::Token::Word'   }

#----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem ne 'map';
    return if not is_function_call($elem);

    if( my $sib = $elem->sprevious_sibling() ){
        return if $sib;
    }

    if( my $parent = $elem->statement()->parent() ){
        return if $parent->isa('PPI::Structure::List');
        return if $parent->isa('PPI::Structure::ForLoop');
        return if $parent->isa('PPI::Structure::Condition');
        return if $parent->isa('PPI::Structure::Constructor');

        if (my $grand_parent = $parent->parent() ){
            return if $parent->isa('PPI::Structure::Block') &&
                !$grand_parent->isa('PPI::Statement::Compound');
        }
    }

    #Otherwise, must be void context
    return $self->violation( $desc, $expl, $elem );
}


1;

__END__

#----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::BuiltinFunctions::ProhibitVoidMap

=head1 DESCRIPTION

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
