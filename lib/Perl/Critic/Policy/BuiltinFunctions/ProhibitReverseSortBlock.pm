package Perl::Critic::Policy::BuiltinFunctions::ProhibitReverseSortBlock;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Forbid $b before $a in sort blocks}; ## no critic (InterpolationOfMetachars)
Readonly::Scalar my $EXPL => [ 152 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                    }
sub default_severity     { return $SEVERITY_LOWEST      }
sub default_themes       { return qw(core pbp cosmetic) }
sub applies_to           { return 'PPI::Token::Word'    }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;

    return if $elem->content() ne 'sort';
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
                    return $self->violation( $DESC, $EXPL, $elem );
                }
            }
        }
    }
    return; #ok
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Critic::Policy::BuiltinFunctions::ProhibitReverseSortBlock - Forbid $b before $a in sort blocks.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Conway says that it is much clearer to use C<reverse> than to flip
C<$a> and C<$b> around in a C<sort> block.  He also suggests that, in
newer perls, C<reverse> is specifically looked for and optimized, and
in the case of a simple reversed string C<sort>, using C<reverse> with
a C<sort> with no block is faster even in old perls.

    my @foo = sort { $b cmp $a } @bar;         #not ok
    my @foo = reverse sort @bar;               #ok

    my @foo = sort { $b <=> $a } @bar;         #not ok
    my @foo = reverse sort { $a <=> $b } @bar; #ok


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2006-2011 Chris Dolan.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
