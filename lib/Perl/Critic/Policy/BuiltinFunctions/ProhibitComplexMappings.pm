package Perl::Critic::Policy::BuiltinFunctions::ProhibitComplexMappings;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Map blocks should have a single statement};
Readonly::Scalar my $EXPL => [ 113 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'max_statements',
            description     =>
                'The maximum number of statements to allow within a map block.',
            default_string  => '1',
            behavior        => 'integer',
            integer_minimum => 1,
        },
    );
}

sub default_severity  { return $SEVERITY_MEDIUM                     }
sub default_themes    { return qw( core pbp maintenance complexity) }
sub applies_to        { return 'PPI::Token::Word'                   }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem->content() ne 'map';
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
    # If it's not a block, it's an expression-style map, which is only one statement by definition
    return if !$arg;
    return if !$arg->isa('PPI::Structure::Block');

    # If we get here, we found a sort with a block as the first arg
    return if $self->{_max_statements} >= $arg->schildren()
        && 0 == grep {$_->isa('PPI::Statement::Compound')} $arg->schildren();

    # more than one child statements
    return $self->violation( $DESC, $EXPL, $elem );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Critic::Policy::BuiltinFunctions::ProhibitComplexMappings - Map blocks should have a single statement.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

The map function can be confusing to novices in the best of
circumstances.  Mappings with multiple statements are even worse.
They're also a maintainer's nightmare because any added complexity
decreases readability precipitously.  Why?  Because map is
traditionally a one-liner converting one array to another.  Trying to
cram lots of functionality into a one-liner is a bad idea in general.

The best solutions to a complex mapping are: 1) write a subroutine
that performs the manipulation and call that from map; 2) rewrite the
map as a for loop.


=head1 CAVEATS

This policy currently misses some compound statements inside of the
map.  For example, the following code incorrectly does not trigger a
violation:

    map { do { foo(); bar() } } @list


=head1 CONFIGURATION

By default this policy flags any mappings with more than one
statement.  While we do not recommend it, you can increase this limit
as follows in a F<.perlcriticrc> file:

    [BuiltinFunctions::ProhibitComplexMappings]
    max_statements = 2


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>


=head1 CREDITS

Initial development of this policy was supported by a grant from the
Perl Foundation.


=head1 COPYRIGHT

Copyright (c) 2007-2011 Chris Dolan.

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
