##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::BuiltinFunctions::ProhibitReverseSortBlock;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.21;

#----------------------------------------------------------------------------

my $desc = q{Forbid $b before $a in sort blocks};
my $expl = [ 152 ];

#----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_LOWEST    }
sub default_themes   { return qw(pbp cosmetic)    }
sub applies_to       { return 'PPI::Token::Word'  }

#----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;

    return if $elem ne 'sort';
    return if ! is_function_call($elem);

    my $sib = $elem->snext_sibling();
    return if !$sib;

    my $arg = $sib;
    if ( $arg->isa('PPI::Structure::List') ) {
        $arg = $arg->schild(0);
        # Forward looking: PPI might change in v1.200 so schild(0) is a PPI::Statement::Expression
        if ( $arg && $arg->isa('PPI::Statement::Expression') ) {
            $arg = $arg->schild(0);
        }
    }
    return if !$arg || !$arg->isa('PPI::Structure::Block');

    # If we get here, we found a sort with a block as the first arg

    # Look at each statement in the block separately.
    # $a is +1, $b is -1, sum should always be >= 0.
    # This may go badly if there are conditionals or loops or other
    # sub-statements...
    for my $statement ($arg->children) {
        my @sort_vars = $statement =~ m/\$([ab])\b/gxms;
        my $count = 0;
        for my $sort_var (@sort_vars) {
            if ($sort_var eq 'a') {
                $count++;
            } else {
                $count--;
                if ($count < 0) {
                    # Found too many C<$b>s too early
                    my $sev = $self->get_severity();
                    return $self->violation( $desc, $expl, $elem, $sev );
                }
            }
        }
    }
    return; #ok
}

1;

#----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Critic::Policy::BuiltinFunctions::ProhibitReverseSortBlock

=head1 DESCRIPTION


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2006 Chris Dolan.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
