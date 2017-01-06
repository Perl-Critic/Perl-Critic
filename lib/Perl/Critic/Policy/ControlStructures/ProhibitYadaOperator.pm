package Perl::Critic::Policy::ControlStructures::ProhibitYadaOperator;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :characters :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{yada operator (...) used};
Readonly::Scalar my $EXPL => q{The yada operator is a placeholder for code you have not yet written.};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                         }
sub default_severity     { return $SEVERITY_HIGH             }
sub default_themes       { return qw( core pbp maintenance ) }
sub applies_to           { return 'PPI::Token::Operator' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    if ( _is_yada( $elem ) ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }
    return;    #ok!
}

sub _is_yada {
    my ( $elem ) = @_;

    return if $elem ne '...';
    #return if not defined $elem->statement;

    # if there is something significant on both sides of the element it's
    # probably the three dot range operator
    return if ($elem->snext_sibling and $elem->sprevious_sibling);

    return 1;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords yada Berndt

=head1 NAME

Perl::Critic::Policy::ControlStructures::ProhibitYadaOperator - Never use C<...> in production code.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

The yada operator C<...> is not something you'd want in production code but
it is perfectly useful less critical environments.

=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 AUTHOR

Alan Berndt <alan@eatabrick.org>

=head1 COPYRIGHT

Copyright (c) 2015 Alan Berndt.  All rights reserved.

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
