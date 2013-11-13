package Perl::Critic::Policy::Subroutines::RequireVoidReturn;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification };
use base 'Perl::Critic::Policy';

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Value of "return" statement is used};
Readonly::Scalar my $EXPL => q{Do not use the return value of the "return" statement};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                 }
sub default_severity     { return $SEVERITY_HIGH     }
sub default_themes       { return qw( core bugs )    }
sub applies_to           { return 'PPI::Token::Word' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if ($elem ne 'return');
    return if is_in_void_context($elem);

    #my $sib = $elem->snext_sibling();
    #return if !$sib;
    #return if !$sib->isa('PPI::Token::Word');
    #return if $sib ne 'sort';

    # Must be 'return sort'
    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::RequireVoidReturn - Using the return value of "return" is probably a mistake.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.

=head1 DESCRIPTION

The C<return> keyword itself is an expression that returns a value.
It is perfectly legal Perl syntax to do this:

    sub foo {
        $x += return 3;
    }

This looks confusing, and may be a bug.  Consider this example:

    sub foo {
        if ( bar() ) {
            $x = 'blah blah' .
            return 1;
        }
        return;
    }

What was supposed to be a semicolon at the end of the C<$x> assignment
is a period, and the value of C<$x> gets an unexepcted concatenation.

The one exception to the void context rule is when the C<return>
follows a logical AND, C<&&>, as in:

    sub foo {
        /bar/ && return 'Found bar';
    }

=head1 CONFIGURATION

This Policy is not configurable except for the standard options.

=head1 CREDITS

This Policy was suggested by XXX XXX.

=head1 AUTHOR

Andy Lester <andy@petdance.com>

=head1 COPYRIGHT

Copyright (c) 2013 Andy Lester.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
