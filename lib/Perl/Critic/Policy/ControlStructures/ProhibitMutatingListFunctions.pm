##################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##################################################################

package Perl::Critic::Policy::ControlStructures::ProhibitMutatingListFunctions;

use strict;
use warnings;
use Perl::Critic::Utils;
use List::MoreUtils qw( none any );
use base 'Perl::Critic::Policy';

our $VERSION = 0.21;

my %modifying_ops = hashify qw( = *= /= += -= %= **= x= .= &= |= ^=  &&= ||= ++ -- );

my @builtin_list_funcs = qw( map grep );
my @cpan_list_funcs    = qw( List::Util::first ),
  map { 'List::MoreUtils::'.$_ } qw(any all none notall true false firstidx first_index
                                    lastidx last_index insert_after insert_after_string);

# Isolate this so we only need one "no critic"
my $TOPIC = q{$_};  ##no critic(RequireInterpolationOfMetachars)

#----------------------------------------------------------------------------

my $desc = q{Don't modify $_ in list functions};  ##no critic(RequireInterpolationOfMetachars)
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

    my $first_arg = first_arg($elem);
    return if !$first_arg;
    return if !$first_arg->isa('PPI::Structure::Block');

    return if !_has_topic_side_effect($first_arg);

    return $self->violation( $desc, $expl, $elem );
}

sub _has_topic_side_effect {
    my $node = shift;

    #print "Check node $node\n";

  CHILD:
    for my $child ($node->schildren) {

        ##no critic(ProhibitCascadingIfElse)

        if ( $child->isa('PPI::Node') ) {
            # Descend into children
            return 1 if ( _has_topic_side_effect($child) );

        } elsif ( $child->isa('PPI::Token::Magic') ) {
            # Look for explict $_, like "$_ = 1" or "$_ *= 2" or "$_ =~ s/f/g/"
            next CHILD if $child ne $TOPIC;
            my $sib = $child->snext_sibling;
            next CHILD if !$sib;
            next CHILD if !$sib->isa('PPI::Token::Operator');

            # Failed: explicit assignment operator to $_
            return 1 if $modifying_ops{$sib};

            # Check for explicit binding operator to $_
            if ( any { $sib eq $_ } qw( =~ !~) ) {
                my $re = $sib->snext_sibling;
                next CHILD if !$re;

                # Failed: explicit $_ modified by s/// or tr/// (or y///)
                return 1 if ( $re->isa('PPI::Token::Regexp::Substitute') ||
                              $re->isa('PPI::Token::Regexp::Transliterate') );
            }

        } elsif ( $child->isa('PPI::Token::Regexp::Substitute') ||
                  $child->isa('PPI::Token::Regexp::Transliterate') ) {
            # Look for implicit s/// or tr/// or y/// on $_
            my $prevsib = $child->sprevious_sibling;

            # Failed: implicit $_ modified by s/// or tr///
            # It's first operator in list, or it doesn't have previous binding operator.
            return 1 if !$prevsib;
            return 1 if none {$prevsib eq $_} qw( =~ !~ );

        } elsif ( $child->isa('PPI::Token::Word') ) {
            # look for chop, chomp, undef, or substr on $_

            if ( $child eq 'chop' || $child eq 'chomp' || $child eq 'undef' ) {
                next CHILD if !is_function_call( $child );

                my $first_arg = first_arg( $child );
                if (!$first_arg) {
                    return 1 if $child ne 'undef';
                } else {
                    return 1 if $first_arg eq $TOPIC;
                }
            } elsif ( $child eq 'substr' ) {
                next CHILD if !is_function_call( $child );

                my @args = parse_arg_list( $child );
                return 1 if @args >= 4 && "@{$args[0]}" eq $TOPIC;
            }
        }
    }
    return;
}

1;

#----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Critic::Policy::ControlStructures::ProhibitMutatingListFunctions

=head1 DESCRIPTION

C<map>, C<grep> and other list operators are intended to transform arrays into
other arrays by applying code to the array elements one by one.  For speed,
the elements are referenced via a C<$_> alias rather than copying them.  As a
consequence, if the code block of the C<map> or C<grep> modify C<$_> in any
way, then it is actually modifying the source array.  This IS technically
allowed, but those side effects can be quite surprising, especially when the
array being passed is C<@_> or perhaps C<values(%ENV)>!  Instead authors
should restrict in-place array modification to C<for(@array) { ... }>
constructs instead, or use C<List::MoreUtils::apply()>.

=head1 CONSTRUCTOR

By default, this policy applies to the following list functions:

  map grep
  List::Util qw(first)
  List::MoreUtils qw(any all none notall true false firstidx first_index
                     lastidx last_index insert_after insert_after_string)

This list can be overridden the F<.perlcriticrc> file like this:

 [ControlStructures::ProhibitMutatingListFunctions]
 list_funcs = map grep List::Util::first

Or, one can just append to the list like so:

 [ControlStructures::ProhibitMutatingListFunctions]
 add_list_funcs = Foo::Bar::listmunge

=head1 LIMITATIONS

This policy deliberately does not apply to C<for (@array) { ... }> or
C<List::MoreUtils::apply()>.

Currently, the policy only detects explict external module usage like this:

  my @out = List::MoreUtils::any {s/^foo//} @in;

and not like this:

  use List::MoreUtils qw(any);
  my @out = any {s/^foo//} @in;

This policy looks only for modifications of C<$_>.  Other nautiness could
include modifying C<$a> and C<$b> in C<sort> and the like.  That's beyond the
scope of this policy.

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

Michael Wolf <MichaelRWolf@att.net>

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
# ex: set ts=8 sts=4 sw=4 expandtab :

