package Perl::Critic::Policy::Variables::ProhibitAugmentedAssignmentInDeclaration;

use 5.006001;
use strict;
use warnings;
use List::MoreUtils qw{ firstval };
use Readonly;

use Perl::Critic::Utils qw{ :severities :data_conversion };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Augmented assignment operator '%s' used in declaration};
Readonly::Scalar my $EXPL => q{Use simple assignment when initializing variables};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                         }
sub default_severity     { return $SEVERITY_HIGH             }
sub default_themes       { return qw( core bugs )            }
sub applies_to           { return 'PPI::Statement::Variable' }

#-----------------------------------------------------------------------------

my %augmented_assignments = hashify( qw( **= += -= .= *= /= %= x= &= |= ^= <<= >>= &&= ||= //= ) );

sub violates {
    my ( $self, $elem, undef ) = @_;

    # The assignment operator associated with a PPI::Statement::Variable
    # element is assumed to be the first immediate child of that element.
    # Other operators in the statement, e.g. the ',' in "my ( $a, $b ) = ();",
    # as assumed to never be immediate children.

    my $found = firstval { $_->isa('PPI::Token::Operator') } $elem->children();
    if ( $found ) {
        my $op = $found->content();
        if ( exists $augmented_assignments{ $op } ) {
            return $self->violation( sprintf( $DESC, $op ), $EXPL, $found );
        }
    }

    return;
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords O'Regan

=head1 NAME

Perl::Critic::Policy::Variables::ProhibitAugmentedAssignmentInDeclaration - Do not write C< my $foo .= 'bar'; >.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Variable declarations that also do initialization with '=' are common.
Perl also allows you to use operators like '.=', '+=', etc., but it
it is more clear to not do so.

    my $foo .= 'bar';              # same as my $foo = 'bar';
    our $foo *= 2;                 # same as our $foo = 0;
    my ( $foo, $bar ) += ( 1, 2 ); # same as my ( $foo, $bar ) = ( undef, 2 );
    local $Carp::CarpLevel += 1;   # same as local $Carp::CarpLevel = 1;
    state $foo += 2;               # adds 2 every time it's encountered

Such constructs are usually the result of botched cut-and-paste, and often are
bugs. Some produce warnings.

=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 AUTHOR

Mike O'Regan


=head1 COPYRIGHT

Copyright (c) 2011 Mike O'Regan.  All rights reserved.

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
