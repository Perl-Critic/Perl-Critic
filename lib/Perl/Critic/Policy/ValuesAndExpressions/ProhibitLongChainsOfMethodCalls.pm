package Perl::Critic::Policy::ValuesAndExpressions::ProhibitLongChainsOfMethodCalls;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :characters :severities };
use Perl::Critic::Utils::PPI qw{ is_ppi_expression_or_generic_statement };

use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL =>
    q{Long chains of method calls indicate code that is too tightly coupled};

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'max_chain_length',
            description     => 'The number of chained calls to allow.',
            default_string  => '3',
            behavior        => 'integer',
            integer_minimum => 1,
        },
    );
}

sub default_severity { return $SEVERITY_LOW          }
sub default_themes   { return qw( core maintenance ) }
sub applies_to       { return qw{ PPI::Statement };  }

#-----------------------------------------------------------------------------

sub _max_chain_length {
    my ( $self ) = @_;

    return $self->{_max_chain_length};
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if not is_ppi_expression_or_generic_statement($elem);

    my $chain_length = 0;
    my $max_chain_length = $self->_max_chain_length();
    my @children = $elem->schildren();
    my $child = shift @children;

    while ($child) {
        # if it looks like we've got a subroutine call, drop the parameter
        # list.
        if (
                $child->isa('PPI::Token::Word')
            and @children
            and $children[0]->isa('PPI::Structure::List')
        ) {
            shift @children;
        }

        if (
                $child->isa('PPI::Token::Word')
            or  $child->isa('PPI::Token::Symbol')
        ) {
            if ( @children ) {
                if ( $children[0]->isa('PPI::Token::Operator') ) {
                    if ( q{->} eq $children[0]->content() ) {
                        $chain_length++;
                        shift @children;
                    }
                }
                elsif ( not  $children[0]->isa('PPI::Token::Structure') ) {
                    $chain_length = 0;
                }
            }
        }
        else {
            if ($chain_length > $max_chain_length) {
                return
                    $self->violation(
                        "Found method-call chain of length $chain_length.",
                        $EXPL,
                        $elem,
                    );
            }

            $chain_length = 0;
        }

        $child = shift @children;
    }

    if ($chain_length > $max_chain_length) {
        return
            $self->violation(
                "Found method-call chain of length $chain_length.",
                $EXPL,
                $elem,
            );
    }

    return;
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords MSCHWERN

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitLongChainsOfMethodCalls - Long chains of method calls indicate tightly coupled code.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

A long chain of method calls usually indicates that the code knows too
much about the interrelationships between objects.  If the code is
able to directly navigate far down a network of objects, then when the
network changes structure in the future, the code will need to be
modified to deal with the change.  The code is too tightly coupled and
is brittle.


    $x = $y->a;           #ok
    $x = $y->a->b;        #ok
    $x = $y->a->b->c;     #questionable, but allowed by default
    $x = $y->a->b->c->d;  #not ok


=head1 CONFIGURATION

This policy has one option: C<max_chain_length> which controls how far
the code is allowed to navigate.  The default value is 3.


=head1 TO DO

Add a C<class_method_exemptions> option to allow for things like

    File::Find::Rule
        ->name('*.blah')
        ->not_name('thingy')
        ->readable()
        ->directory()
        ->in(@roots);


=head1 AUTHOR

Elliot Shank C<< <perl@galumph.com> >>


=head1 COPYRIGHT

Copyright (c) 2007-2011 Elliot Shank.

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
