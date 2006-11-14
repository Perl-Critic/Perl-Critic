##################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##################################################################

package Perl::Critic::Policy::Variables::ProhibitListProcessingSideEffects;

use strict;
use warnings;
use Perl::Critic::Utils;
use List::MoreUtils qw(none);
use base 'Perl::Critic::Policy';

our $VERSION = 0.21;

my %modifying_ops = hashify qw( = *= /= += -= %= **= x= .= &= |= ^=  &&= ||= ++ -- );

my @builtin_list_funcs = qw( map grep );
my @cpan_list_funcs    = qw( List::MoreUtils::first );

print "lists: @builtin_list_funcs, @cpan_list_funcs\n";

#----------------------------------------------------------------------------

my $desc = q{Don't modify $_ in list functions};
my $expl = [ 114 ];

#----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGHEST }
sub default_themes   { return qw(danger) }
sub applies_to       { return 'PPI::Token::Word' }

#----------------------------------------------------------------------------

sub new {
    my ( $class, %config ) = @_;
    my $self = bless {}, $class;

    my @list_funcs;
    @list_funcs = $config{list_funcs}
        ? ( grep {$_} split m/\s+/xms, $config{list_funcs} )
        : ( @builtin_list_funcs, @cpan_list_funcs );

    if ( $config{add_list_funcs} ) {
        push @list_funcs, grep {$_} split m/\s+/xms, $config{add_list_funcs};
    }

    $self->{_list_funcs} = { hashify @list_funcs };

    return $self;
}

#----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;

    return if !$self->{_list_funcs}->{$elem};
    return if !is_function_call($elem);

    my $first_arg = _first_arg($elem);
    return if !$first_arg;
    return if !$first_arg->isa('PPI::Structure::Block');

    return if !_has_topic_side_effect($first_arg);

    return $self->violation( $desc, $expl, $elem );
}

# TODO: should be factored out as a common utility!  Was copied from
# BuildinFunctions::RequireBlockGrep

sub _first_arg {
    my $elem = shift;

    my $arg = $elem->snext_sibling();
    while ($arg) {
        last if !$arg->isa('PPI::Structure::List') && !$arg->isa('PPI::Statement');
        $arg = $arg->schild(0);
    }
    return $arg;
}

sub _has_topic_side_effect {
    my $node = shift;

    #print "Check node $node\n";

    for my $child ($node->schildren) {
        if ($child->isa('PPI::Node')) {  ##no critic(ProhibitCascadingIfElse)
            return 1 if ( _has_topic_side_effect($child) );
        } elsif ($child->isa('PPI::Token::Magic')) {
            # Look for explict $_, like "$_ = 1" or "$_ *= 2" or "$_ =~ s/f/g/"
            if ($child eq '$_') { ##no critic(RequireInterpolationOfMetachars)
                my $sib = $child->snext_sibling;
                if ($sib && $sib->isa('PPI::Token::Operator')) {

                    # Failed: explicit assignment operator to $_
                    return 1 if $modifying_ops{$sib};

                    # Check for explicit binding operator to $_
                    if ($sib eq q{=~} || $sib eq q{!~}) {
                        my $re = $sib->snext_sibling;
                        # Failed: exilicit $_ modified by s/// or tr/// (or y///)
                        return 1 if ($re && ($re->isa('PPI::Token::Regexp::Substitute')
                                             || $re->isa('PPI::Token::Regexp::Transliterate')));
                    }
                }
            }
        } elsif ($child->isa('PPI::Token::Regexp::Substitute')
                 || $child->isa('PPI::Token::Regexp::Transliterate')) {
            # Looking for implicit s/// or tr/// on $_
            my $prevsib = $child->sprevious_sibling;

            # Failed: implicit $_ modified by s/// or tr///
            # It's first operator in list, or it doesn't have previous binding operator.
            return 1 if !$prevsib;
            return 1 if none {$prevsib eq $_}  qw( =~ !~ );

            # Failed: explicit $_ modified by s/// or tr///
            # return 1 if ( any {$_ eq $prevsib} qw(=~ !~) && $prevsib->sprevious_sibling eq "$_");

            # failed: not binding regexp explicitly to some variable


        } elsif ($child->isa('ppi::token::word')) {
            # ...
        }
    }
    return;
}

1;

#----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Critic::Policy::Variables::ProhibitListProcessingSideEffects

=head1 DESCRIPTION


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2006 Chris Dolan.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
# End:
# ex: set ts=8 sts=4 sw=4 expandtab

