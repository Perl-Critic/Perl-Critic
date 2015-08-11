package Perl::Critic::Policy::RegularExpressions::ProhibitCaptureWithoutTest;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :booleans :data_conversion :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Hash my %CONDITIONAL_OPERATOR => hashify( qw{ && || ? and or xor } );
Readonly::Hash my %UNAMBIGUOUS_CONTROL_TRANSFER => hashify(
    qw< next last redo return > );

Readonly::Scalar my $DESC => q{Capture variable used outside conditional};
Readonly::Scalar my $EXPL => [ 253 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return (
        {
            name        => 'exception_source',
            description => 'Names of ways to generate exceptions',
            behavior    => 'string list',
            list_always_present_values => [ qw{ die croak confess } ],
        }
    );
}
sub default_severity     { return $SEVERITY_MEDIUM         }
sub default_themes       { return qw(core pbp maintenance certrule ) }
sub applies_to           { return 'PPI::Token::Magic'      }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;
    # TODO named capture variables
    return if $elem !~ m/\A \$[1-9] \z/xms;
    return if _is_in_conditional_expression($elem);
    return if $self->_is_in_conditional_structure($elem);
    return $self->violation( $DESC, $EXPL, $elem );
}

sub _is_in_conditional_expression {
    my $elem = shift;

    # simplistic check: is there a conditional operator between a match and
    # the capture var?
    my $psib = $elem->sprevious_sibling;
    while ($psib) {
        if ($psib->isa('PPI::Token::Operator')) {
            my $op = $psib->content;
            if ( $CONDITIONAL_OPERATOR{ $op } ) {
                $psib = $psib->sprevious_sibling;
                while ($psib) {
                    return 1 if ($psib->isa('PPI::Token::Regexp::Match'));
                    return 1 if ($psib->isa('PPI::Token::Regexp::Substitute'));
                    $psib = $psib->sprevious_sibling;
                }
                return; # false
            }
        }
        $psib = $psib->sprevious_sibling;
    }

    return; # false
}

sub _is_in_conditional_structure {
    my ( $self, $elem ) = @_;

    my $stmt = $elem->statement();
    while ($stmt && $elem->isa('PPI::Statement::Expression')) {
       #return if _is_in_conditional_expression($stmt);
       $stmt = $stmt->statement();
    }
    return if !$stmt;

    # Check if any previous statements in the same scope have regexp matches
    my $psib = $stmt->sprevious_sibling;
    while ($psib) {
        if ( $psib->isa( 'PPI::Node' ) and
            my $match = _find_exposed_match_or_substitute( $psib ) ) {
            return _is_control_transfer_to_left( $self, $match, $elem ) ||
                _is_control_transfer_to_right( $self, $match, $elem );
        }
        $psib = $psib->sprevious_sibling;
    }

    # Check for an enclosing 'if', 'unless', 'elsif', 'else', or 'when'
    my $parent = $stmt->parent;
    while ($parent) { # never false as long as we're inside a PPI::Document
        if ($parent->isa('PPI::Statement::Compound') ||
            $parent->isa('PPI::Statement::When' )
        ) {
            return 1;
        }
        elsif ($parent->isa('PPI::Structure')) {
           return 1 if _is_in_conditional_expression($parent);
           return 1 if $self->_is_in_conditional_structure($parent);
           $parent = $parent->parent;
        }
        else {
           last;
        }
    }

    return; # fail
}

# This subroutine returns true if there is a control transfer to the left of
# the match operation which would bypass the capture variable. The arguments
# are the match operation and the capture variable.
sub _is_control_transfer_to_left {
    my ( $self, $match, $elem ) = @_;
    # If a regexp match is found, we succeed if a match failure
    # appears to throw an exception, and fail otherwise. RT 36081
    my $prev = $match->sprevious_sibling() or return;
    while ( not ( $prev->isa( 'PPI::Token::Word' ) &&
            q<unless> eq $prev->content() ) ) {
        $prev = $prev->sprevious_sibling() or return;
    }
    # In this case we analyze the first thing to appear in the parent of the
    # 'unless'. This is the simplest case, and it will not be hard to dream up
    # cases where this is insufficient (e.g. do {something(); die} unless ...)
    my $parent = $prev->parent() or return;
    my $first = $parent->schild( 0 ) or return;
    if ( my $method = _get_method_name( $first ) ) {
        # Methods can also be exception sources.
        return $self->{_exception_source}{ $method->content() };
    }
    return $self->{_exception_source}{ $first->content() } ||
        _unambiguous_control_transfer( $first, $elem );
}

# This subroutine returns true if there is a control transfer to the right of
# the match operation which would bypass the capture variable. The arguments
# are the match operation and the capture variable.
sub _is_control_transfer_to_right {
    my ( $self, $match, $elem ) = @_;
    # If a regexp match is found, we succeed if a match failure
    # appears to throw an exception, and fail otherwise. RT 36081
    my $oper = $match->snext_sibling() or return;   # fail
    my $oper_content = $oper->content();
    # We do not check 'dor' or '//' because a match failure does not
    # return an undefined value.
    q{or} eq $oper_content
        or q{||} eq $oper_content
        or return;                                  # fail
    my $next = $oper->snext_sibling() or return;    # fail
    if ( my $method = _get_method_name( $next ) ) {
        # Methods can also be exception sources.
        return $self->{_exception_source}{ $method->content() };
    }
    return $self->{_exception_source}{ $next->content() } ||
        _unambiguous_control_transfer( $next, $elem );
}

# Given a PPI::Node, find the last regexp match or substitution that is
# in-scope to the node's next sibling.
sub _find_exposed_match_or_substitute { # RT 36081
    my $elem = shift;
FIND_REGEXP_NOT_IN_BLOCK:
    foreach my $regexp ( reverse @{ $elem->find(
            sub {
                return $_[1]->isa( 'PPI::Token::Regexp::Substitute' )
                    || $_[1]->isa( 'PPI::Token::Regexp::Match' );
            }
        ) || [] } ) {
        my $parent = $regexp->parent();
        while ( $parent != $elem ) {
            $parent->isa( 'PPI::Structure::Block' )
                and next FIND_REGEXP_NOT_IN_BLOCK;
            $parent = $parent->parent()
                or next FIND_REGEXP_NOT_IN_BLOCK;
        }
        return $regexp;
    }
    return;
}

# If the argument introduces a method call, return the method name;
# otherwise just return.
sub _get_method_name {
    my ( $elem ) = @_;
    # We fail unless the element we were given looks like it might be an
    # object or a class name.
    $elem or return;
    (
        $elem->isa( 'PPI::Token::Symbol' ) &&
        q<$> eq $elem->raw_type() ||
        $elem->isa( 'PPI::Token::Word' ) &&
        $elem->content() =~ m/ \A [\w:]+ \z /smx
    ) or return;
    # We skip over all the subscripts and '->' operators to the right of
    # the original element, failing if we run out of objects.
    my $prior;
    my $next = $elem->snext_sibling() or return;
    while ( $next->isa( 'PPI::Token::Subscript' ) ||
        $next->isa( 'PPI::Token::Operator' ) &&
        q{->} eq $next->content() ) {
        $prior = $next;
        $next = $next->snext_sibling or return; # fail
    }
    # A method call must have a '->' operator before it.
    ( $prior &&
        $prior->isa( 'PPI::Token::Operator' ) &&
        q{->} eq $prior->content()
    ) or return;
    # Anything other than a PPI::Token::Word can not be statically
    # recognized as a method name.
    $next->isa( 'PPI::Token::Word' ) or return;
    # Whatever we have left at this point looks very like a method name.
    return $next;
}

# Determine whether the given element represents an unambiguous transfer of
# control around anything that follows it in the same block. The arguments are
# the element to check, and the capture variable that is the subject of this
# call to the policy.
sub _unambiguous_control_transfer { # RT 36081.
    my ( $xfer, $elem ) = @_;

    my $content = $xfer->content();

    # Anything in the hash is always a transfer of control.
    return $TRUE if $UNAMBIGUOUS_CONTROL_TRANSFER{ $content };

    # A goto is not unambiguous on the face of it, but at least some forms of
    # it can be accepted.
    q<goto> eq $content
        and return _unambiguous_goto( $xfer, $elem );

    # Anything left at this point is _not_ an unambiguous transfer of control
    # around whatever follows it.
    return;
}

# Determine whether the given goto represents an unambiguous transfer of
# control around anything that follows it in the same block. The arguments are
# the element to check, and the capture variable that is the subject of this
# call to the policy.
sub _unambiguous_goto {
    my ( $xfer, $elem ) = @_;

    # A goto without a target?
    my $target = $xfer->snext_sibling() or return;

    # The co-routine form of goto is an unambiguous transfer of control.
    $target->isa( 'PPI::Token::Symbol' )
        and q<&> eq $target->raw_type()
        and return $TRUE;

    # The label form of goto is an unambiguous transfer of control,
    # provided the label does not occur between the goto and the capture
    # variable.
    if ( $target->isa( 'PPI::Token::Word' ) ) {

        # We need to search in our most-local block, or the document if
        # there is no enclosing block.
        my $container = $target;
        while ( my $parent = $container->parent() ) {
            $container = $parent;
            $container->isa( 'PPI::Structure::Block' ) and last;
        }

        # We search the container for our label. If we find it, we return
        # true if it occurs before the goto or after the capture variable,
        # otherwise we return false. If we do not find it we return true.
        # Note that perl does not seem to consider duplicate labels an
        # error, but also seems to take the first one in the relevant
        # scope when this happens.
        my $looking_for = qr/ \A @{[ $target->content() ]} \s* : \z /smx;
        my ($start_line, $start_char) = @{ $xfer->location() || [] };
        defined $start_line or return;  # document not indexed.
        my ($end_line,   $end_char)   = @{ $elem->location() || [] };
        foreach my $label (
            @{ $container->find( 'PPI::Token::Label' ) || [] } )
        {
            $label->content() =~ m/$looking_for/smx or next;
            my ( $line, $char ) = @{ $label->location() || [] };
            return $TRUE
                if $line < $start_line ||
                    $line == $start_line && $char < $start_char;
            return $TRUE
                if $line > $end_line ||
                    $line == $end_line && $char > $end_char;
            return;
        }
        return $TRUE;
    }

    # Any other form of goto can not be statically analyzed, and so is not
    # an unambiguous transfer of control around the capture variable.
    return;
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Critic::Policy::RegularExpressions::ProhibitCaptureWithoutTest - Capture variable used outside conditional.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

If a regexp match fails, then any capture variables (C<$1>, C<$2>,
...) will be undefined.  Therefore it's important to check the return
value of a match before using those variables.

This policy checks that the previous regexp for which the capture
variable is in-scope is either in a conditional or causes an exception
or other control transfer (i.e. C<next>, C<last>, C<redo>, C<return>, or
sometimes C<goto>) if the match fails.

A C<goto> is only accepted by this policy if it is a co-routine call
(i.e.  C<goto &foo>) or a C<goto LABEL> where the label does not fall
between the C<goto> and the capture variable in the scope of the
C<goto>. A computed C<goto> (i.e. something like C<goto (qw{foo bar
baz})[$i]>) is not accepted by this policy because its target can not be
statically determined.

This policy does not check whether that conditional is actually
testing a regexp result, nor does it check whether a regexp actually
has a capture in it.  Those checks are too hard.

This policy also does not check arbitrarily complex conditionals guarding
regexp results, for pretty much the same reason.  Simple things like

 m/(foo)/ or die "No foo!";
 die "No foo!" unless m/(foo)/;

will be handled, but something like

 m/(foo) or do {
   ... lots of complicated calculations here ...
   die "No foo!";
 };

are beyond its scope.


=head1 CONFIGURATION

By default, this policy considers C<die>, C<croak>, and C<confess> to
throw exceptions. If you have additional subroutines or methods that may
be used in lieu of one of these, you can configure them in your
perlcriticrc as follows:

 [RegularExpressions::ProhibitCaptureWithoutTest]
 exception_source = my_exception_generator

=head1 BUGS

This policy does not recognize named capture variables. Yet.

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
