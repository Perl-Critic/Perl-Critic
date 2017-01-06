package Perl::Critic::Policy::Variables::RequireLexicalLoopIterators;

use 5.006001;
use strict;
use warnings;
use Readonly;
use version ();

use Perl::Critic::Utils qw{ :booleans :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Loop iterator is not lexical};
Readonly::Scalar my $EXPL => [ 108 ];

Readonly::Scalar my $MINIMUM_PERL_VERSION => version->new( 5.004 );

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                         }
sub default_severity     { return $SEVERITY_HIGHEST          }
sub default_themes       { return qw(core pbp bugs certrec )          }
sub applies_to           { return 'PPI::Statement::Compound' }

#-----------------------------------------------------------------------------

sub prepare_to_scan_document {
    my ( $self, $document ) = @_;
    # perl5004delta says that is when lexical iterators were introduced,
    # so ... (RT 67760)
    my $version = $document->highest_explicit_perl_version();
    return ! $version || $version >= $MINIMUM_PERL_VERSION;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    # First child will be 'for' or 'foreach' keyword
    return if $elem->type() ne 'foreach';

    my $first_child = $elem->schild(0);
    return if not $first_child;
    my $start = $first_child->isa('PPI::Token::Label') ? 1 : 0;

    my $potential_scope = $elem->schild($start + 1);
    return if not $potential_scope;
    return if $potential_scope->isa('PPI::Structure::List');

    return if $potential_scope eq 'my';

    return $self->violation( $DESC, $EXPL, $elem );
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords foreach perlsyn

=head1 NAME

Perl::Critic::Policy::Variables::RequireLexicalLoopIterators - Write C<for my $element (@list) {...}> instead of C<for $element (@list) {...}>.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

This policy asks you to use C<my>-style lexical loop iterator variables:

    foreach my $zed (...) {
        ...
    }

Unless you use C<my>, C<for>/C<foreach> loops use a global variable with
its value C<local> to the block. In other words,

    foreach $zed (...) {
        ...
    }

is more-or-less equivalent to

    {
        local $zed
        foreach $zed (...) {
            ...
        }
    }

This may not seem like a big deal until you see code like

    my $bicycle;
    for $bicycle (@things_attached_to_the_bike_rack) {
        if (
                $bicycle->is_red()
            and $bicycle->has_baseball_card_in_spokes()
            and $bicycle->has_bent_kickstand()
        ) {
            $bicycle->remove_lock();

            last;
        }
    }

    if ( $bicycle and $bicycle->is_unlocked() ) {
        ride_home($bicycle);
    }

which is not going to allow you to arrive in time for dinner with your
family because the C<$bicycle> outside the loop is not changed by the
loop. You may have unlocked your bicycle, but you can't remember which
one it was.

Lexical loop variables were introduced in Perl 5.004. This policy does
not report violations on code which explicitly specifies an earlier
version of Perl (e.g. C<require 5.002;>).


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 SEE ALSO

L<"Foreach Loops" in perlsyn|perlsyn/Foreach Loops>

L<"my() in Control Structures" in perl5004delta|perl5004delta/my() in control structures>


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2005-2011 Imaginative Software Systems.  All rights reserved.

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
