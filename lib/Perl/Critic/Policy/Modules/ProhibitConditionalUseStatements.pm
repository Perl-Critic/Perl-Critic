package Perl::Critic::Policy::Modules::ProhibitConditionalUseStatements;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :booleans :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Conditional "use" statement};
Readonly::Scalar my $EXPL => q{Use "require" to conditionally include a module.};

# operators

Readonly::Hash my %OPS => map { $_ => 1 } qw( || && or and );

#-----------------------------------------------------------------------------

sub supported_parameters { return ()              }
sub default_severity     { return $SEVERITY_MEDIUM  }
sub default_themes       { return qw( core bugs ) }
sub applies_to           { return 'PPI::Statement::Include' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;
    return $self->violation( $DESC, $EXPL, $elem ) if $elem->type() eq 'use'
        && !$elem->pragma()
        && $elem->module()
        && $self->_is_in_conditional_logic($elem);
    return;
}

#-----------------------------------------------------------------------------

# is this a non-string eval statement

sub _is_eval {
    my ( $self, $elem ) = @_;
    $elem->isa('PPI::Statement') or return;
    my $first_elem = $elem->first_element();
    return $TRUE if $first_elem->isa('PPI::Token::Word')
        && $first_elem eq 'eval';
    return;
}

#-----------------------------------------------------------------------------

# is this in a conditional do block

sub _is_in_do_conditional_block {
    my ( $self, $elem ) = @_;
    return if !$elem->isa('PPI::Structure::Block');
    my $prev_sibling = $elem->sprevious_sibling() or return;
    if ($prev_sibling->isa('PPI::Token::Word') && $prev_sibling eq 'do') {
        my $next_sibling = $elem->snext_sibling();
        return $TRUE if $next_sibling
            && $next_sibling->isa('PPI::Token::Word');
        $prev_sibling = $prev_sibling->sprevious_sibling() or return;
        return $TRUE if $prev_sibling->isa('PPI::Token::Operator')
            && $OPS{$prev_sibling->content()};
    }
    return;
}

#-----------------------------------------------------------------------------

# is this a compound statement

sub _is_compound_statement {
    my ( $self, $elem ) = @_;
    return if !$elem->isa('PPI::Statement::Compound');
    return $TRUE if $elem->type() ne 'continue'; # exclude bare blocks
    return;
}

#-----------------------------------------------------------------------------

# is this contained in conditional logic

sub _is_in_conditional_logic {
    my ( $self, $elem ) = @_;
    while ($elem = $elem->parent()) {
        last if $elem->isa('PPI::Document');
        return $TRUE if $self->_is_compound_statement($elem)
            || $self->_is_eval($elem)
            || $self->_is_in_do_conditional_block($elem);
    }
    return;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords evals

=head1 NAME

Perl::Critic::Policy::Modules::ProhibitConditionalUseStatements - Avoid putting conditional logic around compile-time includes.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Modules included via "use" are loaded at compile-time.  Placing conditional
logic around the "use" statement has no effect on whether the module will be
loaded.  Doing so can also serve to confuse the reader as to the author's
original intent.

If you need to conditionally load a module you should be using "require"
instead.

This policy will catch the following forms of conditional "use" statements:

    # if-elsif-else
    if ($a == 1) { use Module; }
    if ($a == 1) { } elsif ($a == 2) { use Module; }
    if ($a == 1) { } else { use Module; }

    # for/foreach
    for (1..$a) { use Module; }
    foreach (@a) { use Module; }

    # while
    while ($a == 1) { use Module; }

    # unless
    unless ($a == 1) { use Module; }

    # until
    until ($a == 1) { use Module; }

    # do-condition
    do { use Module; } if $a == 1;
    do { use Module; } while $a == 1;
    do { use Module; } unless $a == 1;
    do { use Module; } until $a == 1;

    # operator-do
    $a == 1 || do { use Module; };
    $a == 1 && do { use Module; };
    $a == 1 or do { use Module; };
    $a == 1 and do { use Module; };

    # non-string eval
    eval { use Module; };

Including a module via "use" in bare blocks, standalone do blocks, or
string evals is allowed.

    # bare block
    { use Module; }

    # do
    do { use Module; }

    # string eval
    eval "use Module";

=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 AUTHOR

Peter Guzis <pguzis@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2010-2011 Peter Guzis.  All rights reserved.

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
