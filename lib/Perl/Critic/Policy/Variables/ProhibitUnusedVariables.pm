package Perl::Critic::Policy::Variables::ProhibitUnusedVariables;

use 5.006001;
use strict;
use warnings;

use Readonly;
use List::MoreUtils qw< any >;

use PPI::Token::Symbol;

use Perl::Critic::Utils qw< :characters :severities >;
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL =>
    q<Unused variables clutter code and make it harder to read>;

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                     }
sub default_severity     { return $SEVERITY_MEDIUM       }
sub default_themes       { return qw< core maintenance certrec > }
sub applies_to           { return qw< PPI::Document >    }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $document ) = @_;

    my %symbol_usage;
    _get_symbol_usage( \%symbol_usage, $document );
    _get_regexp_symbol_usage( \%symbol_usage, $document );
    return if not %symbol_usage;

    my $declarations = $document->find('PPI::Statement::Variable');
    return if not $declarations;

    my @violations;

    DECLARATION:
    foreach my $declaration ( @{$declarations} ) {
        next DECLARATION if 'my' ne $declaration->type();

        my @children = $declaration->schildren();
        next DECLARATION if any { $_->content() eq q<=> } @children;

        VARIABLE:
        foreach my $variable ( $declaration->variables() ) {
            my $count = $symbol_usage{ $variable };
            next VARIABLE if not $count; # BUG!
            next VARIABLE if $count > 1;

            push
                @violations,
                $self->violation(
                    qq<"$variable" is declared but not used.>,
                    $EXPL,
                    $declaration,
                );
        }
    }

    return @violations;
}

sub _get_symbol_usage {
    my ( $symbol_usage, $document ) = @_;

    my $symbols = $document->find('PPI::Token::Symbol');
    return if not $symbols;

    foreach my $symbol ( @{$symbols} ) {
        $symbol_usage->{ $symbol->symbol() }++;
    }

    return;
}

sub _get_regexp_symbol_usage {
    my ( $symbol_usage, $document ) = @_;

    foreach my $class ( qw{
        PPI::Token::Regexp::Match
        PPI::Token::Regexp::Substitute
        PPI::Token::QuoteLike::Regexp
        } ) {

        foreach my $regex ( @{ $document->find( $class ) || [] } ) {

            my $ppix = $document->ppix_regexp_from_element( $regex ) or next;
            $ppix->failures() and next;

            foreach my $code ( @{
                $ppix->find( 'PPIx::Regexp::Token::Code' ) || [] } ) {
                my $subdoc = $code->ppi() or next;
                _get_symbol_usage( $symbol_usage, $subdoc );
            }

        }

    }

    return;
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Variables::ProhibitUnusedVariables - Don't ask for storage you don't need.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Unused variables clutter code and require the reader to do mental
bookkeeping to figure out if the variable is actually used or not.

At present, this Policy is very limited in order to ensure that there
aren't any false positives.  Hopefully, this will become more
sophisticated soon.

Right now, this only looks for simply declared, uninitialized lexical
variables.

    my $x;          # not ok, assuming no other appearances.
    my @y = ();     # ok, not handled yet.
    our $z;         # ok, global.
    local $w;       # ok, global.

This module is very dumb: it does no scoping detection, i.e. if the
same variable name is used in two different locations, even if they
aren't the same variable, this Policy won't complain.

Have to start somewhere.


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 AUTHOR

Elliot Shank C<< <perl@galumph.com> >>


=head1 COPYRIGHT

Copyright (c) 2008-2011 Elliot Shank.

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
