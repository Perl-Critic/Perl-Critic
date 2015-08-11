package Perl::Critic::Policy::ControlStructures::ProhibitMutatingListFunctions;

use 5.006001;
use strict;
use warnings;
use Readonly;

use List::MoreUtils qw( none any );

use Perl::Critic::Utils qw{
    :booleans :characters :severities :data_conversion :classification :ppi
};

use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Array my @BUILTIN_LIST_FUNCS => qw( map grep );
Readonly::Array my @CPAN_LIST_FUNCS    => _get_cpan_list_funcs();

#-----------------------------------------------------------------------------

sub _get_cpan_list_funcs {
    return  qw( List::Util::first ),
        map { 'List::MoreUtils::'.$_ } _get_list_moreutils_funcs();
}

#-----------------------------------------------------------------------------

sub _get_list_moreutils_funcs {
    return  qw(any all none notall true false firstidx first_index
               lastidx last_index insert_after insert_after_string);
}

#-----------------------------------------------------------------------------

sub _is_topic {
    my $elem = shift;
    return defined $elem
        && $elem->isa('PPI::Token::Magic')
            && $elem->content() eq q{$_}; ##no critic (InterpolationOfMetachars)
}


#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Don't modify $_ in list functions};  ##no critic (InterpolationOfMetachars)
Readonly::Scalar my $EXPL => [ 114 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'list_funcs',
            description     => 'The base set of functions to check.',
            default_string  => join ($SPACE, @BUILTIN_LIST_FUNCS, @CPAN_LIST_FUNCS ),
            behavior        => 'string list',
        },
        {
            name            => 'add_list_funcs',
            description     => 'The set of functions to check, in addition to those given in list_funcs.',
            default_string  => $EMPTY,
            behavior        => 'string list',
        },
    );
}

sub default_severity { return $SEVERITY_HIGHEST  }
sub default_themes   { return qw(core bugs pbp certrule )  }
sub applies_to       { return 'PPI::Token::Word' }

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    my ($self, $config) = @_;

    $self->{_all_list_funcs} = {
        hashify keys %{ $self->{_list_funcs} }, keys %{ $self->{_add_list_funcs} }
    };

    return $TRUE;
}

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;

    # Is this element a list function?
    return if not $self->{_all_list_funcs}->{$elem};
    return if not is_function_call($elem);

    # Only the block form of list functions can be analyzed.
    return if not my $first_arg = first_arg( $elem );
    return if not $first_arg->isa('PPI::Structure::Block');
    return if not $self->_has_topic_side_effect( $first_arg, $doc );

    # Must be a violation
    return $self->violation( $DESC, $EXPL, $elem );
}

#-----------------------------------------------------------------------------

sub _has_topic_side_effect {
    my ( $self, $node, $doc ) = @_;

    # Search through all significant elements in the block,
    # testing each element to see if it mutates the topic.
    my $tokens = $node->find( 'PPI::Token' ) || [];
    for my $elem ( @{ $tokens } ) {
        next if not $elem->significant();
        return 1 if _is_assignment_to_topic( $elem );
        return 1 if $self->_is_topic_mutating_regex( $elem, $doc );
        return 1 if _is_topic_mutating_func( $elem );
        return 1 if _is_topic_mutating_substr( $elem );
    }
    return;
}

#-----------------------------------------------------------------------------

sub _is_assignment_to_topic {
    my $elem = shift;
    return if not _is_topic( $elem );

    my $sib = $elem->snext_sibling();
    if ($sib && $sib->isa('PPI::Token::Operator')) {
        return 1 if _is_assignment_operator( $sib );
    }

    my $psib = $elem->sprevious_sibling();
    if ($psib && $psib->isa('PPI::Token::Operator')) {
        return 1 if _is_increment_operator( $psib );
    }

    return;
}

#-----------------------------------------------------------------------------

sub _is_topic_mutating_regex {
    my ( $self, $elem, $doc ) = @_;
    return if ! ( $elem->isa('PPI::Token::Regexp::Substitute')
                  || $elem->isa('PPI::Token::Regexp::Transliterate') );

    # Exempt PPI::Token::Regexp::Transliterate objects IF the replacement
    # string is empty AND neither the /d or /s flags are specified, OR the
    # replacement string equals the match string AND neither the /c or /s
    # flags are specified. RT 44515.
    #
    # NOTE that, at least as of 5.14.2, tr/// does _not_ participate in the
    # 'use re /modifiers' mechanism. And a good thing, too, since the
    # modifiers that _are_ common (/s and /d) mean something completely
    # different in tr///.
    if ( $elem->isa( 'PPI::Token::Regexp::Transliterate') ) {
        my $subs = $elem->get_substitute_string();
        my %mods = $elem->get_modifiers();
        $mods{r} and return;    # Introduced in Perl 5.13.7
        if ( $EMPTY eq $subs ) {
            $mods{d} or $mods{s} or return;
        } elsif ( $elem->get_match_string() eq $subs ) {
            $mods{c} or $mods{s} or return;
        }
    }

    # As of 5.13.2, the substitute built-in supports the /r modifier, which
    # causes the operation to return the modified string and leave the
    # original unmodified. This does not parse under earlier Perls, so there
    # is no version check.

    if ( $elem->isa( 'PPI::Token::Regexp::Substitute' ) ) {
        my $re = $doc->ppix_regexp_from_element( $elem )
            or return;
        $re->modifier_asserted( 'r' )
            and return;
    }

    # If the previous sibling does not exist, then
    # the regex implicitly binds to $_
    my $prevsib = $elem->sprevious_sibling;
    return 1 if not $prevsib;

    # If the previous sibling does exist, then it
    # should be a binding operator.
    return 1 if not _is_binding_operator( $prevsib );

    # Check if the sibling before the biding operator
    # is explicitly set to $_
    my $bound_to = $prevsib->sprevious_sibling;
    return _is_topic( $bound_to );
}

#-----------------------------------------------------------------------------

sub _is_topic_mutating_func {
    my $elem = shift;
    return if not $elem->isa('PPI::Token::Word');
    my @mutator_funcs = qw(chop chomp undef);
    return if not any { $elem->content() eq $_ } @mutator_funcs;
    return if not is_function_call( $elem );

    # If these functions have no argument,
    # they default to mutating $_
    my $first_arg = first_arg( $elem );
    if (not defined $first_arg) {
        # undef does not default to $_, unlike the others
        return if $elem->content() eq 'undef';
        return 1;
    }
    return _is_topic( $first_arg );
}

#-----------------------------------------------------------------------------

Readonly::Scalar my $MUTATING_SUBSTR_ARG_COUNT => 4;

sub _is_topic_mutating_substr {
    my $elem = shift;
    return if $elem->content() ne 'substr';
    return if not is_function_call( $elem );

    # check and see if the first arg is $_
    my @args = parse_arg_list( $elem );
    return @args >= $MUTATING_SUBSTR_ARG_COUNT && _is_topic( $args[0]->[0] );
}

#-----------------------------------------------------------------------------

{
    ##no critic(ArgUnpacking)

    my %assignment_ops = hashify qw(
        = *= /= += -= %= **= x= .= &= |= ^=  &&= ||= <<= >>= //= ++ --
    );
    sub _is_assignment_operator { return exists $assignment_ops{$_[0]} }

    my %increment_ops = hashify qw( ++ -- );
    sub _is_increment_operator { return exists $increment_ops{$_[0]} }

    my %binding_ops = hashify qw( =~ !~ );
    sub _is_binding_operator { return exists $binding_ops{$_[0]} }
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Critic::Policy::ControlStructures::ProhibitMutatingListFunctions - Don't modify C<$_> in list functions.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

C<map>, C<grep> and other list operators are intended to transform
arrays into other arrays by applying code to the array elements one by
one.  For speed, the elements are referenced via a C<$_> alias rather
than copying them.  As a consequence, if the code block of the C<map>
or C<grep> modify C<$_> in any way, then it is actually modifying the
source array.  This IS technically allowed, but those side effects can
be quite surprising, especially when the array being passed is C<@_>
or perhaps C<values(%ENV)>!  Instead authors should restrict in-place
array modification to C<for(@array) { ... }> constructs instead, or
use C<List::MoreUtils::apply()>.

=head1 CONFIGURATION

By default, this policy applies to the following list functions:

    map grep
    List::Util qw(first)
    List::MoreUtils qw(any all none notall true false firstidx
                       first_index lastidx last_index insert_after
                       insert_after_string)

This list can be overridden the F<.perlcriticrc> file like this:

    [ControlStructures::ProhibitMutatingListFunctions]
    list_funcs = map grep List::Util::first

Or, one can just append to the list like so:

    [ControlStructures::ProhibitMutatingListFunctions]
    add_list_funcs = Foo::Bar::listmunge

=head1 LIMITATIONS

This policy deliberately does not apply to C<for (@array) { ... }> or
C<List::MoreUtils::apply()>.

Currently, the policy only detects explicit external module usage like
this:

    my @out = List::MoreUtils::any {s/^foo//} @in;

and not like this:

    use List::MoreUtils qw(any);
    my @out = any {s/^foo//} @in;

This policy looks only for modifications of C<$_>.  Other naughtiness
could include modifying C<$a> and C<$b> in C<sort> and the like.
That's beyond the scope of this policy.


=head1 SEE ALSO

There is discussion of this policy at
L<http://perlmonks.org/index.pl?node_id=743445>.


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

Michael Wolf <MichaelRWolf@att.net>


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
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :

