package Perl::Critic::Policy::ValuesAndExpressions::ProhibitMixedBooleanOperators;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :data_conversion };
use base 'Perl::Critic::Policy';


#-----------------------------------------------------------------------------

our $VERSION = '1.126';
#-----------------------------------------------------------------------------

Readonly::Hash my %LOW_BOOLEANS  => hashify( qw( not or and ) );
Readonly::Hash my %HIGH_BOOLEANS => hashify( qw( ! || && ||= &&= //=) );

Readonly::Hash my %EXEMPT_TYPES => hashify(
    qw(
        PPI::Statement::Block
        PPI::Statement::Scheduled
        PPI::Statement::Package
        PPI::Statement::Include
        PPI::Statement::Sub
        PPI::Statement::Variable
        PPI::Statement::Compound
        PPI::Statement::Data
        PPI::Statement::End
    )
);

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Mixed high and low-precedence booleans};
Readonly::Scalar my $EXPL => [ 70 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                  }
sub default_severity     { return $SEVERITY_HIGH      }
sub default_themes       { return qw( core bugs pbp certrec ) }
sub applies_to           { return 'PPI::Statement'    }

#-----------------------------------------------------------------------------

sub violates {

    my ( $self, $elem, undef ) = @_;

    # PPI::Statement is the ancestor of several types of PPI elements.
    # But for this policy, we only want the ones that generally
    # represent a single statement or expression.  There might be
    # better ways to do this, such as scanning for a semi-colon or
    # some other marker.

    return if exists $EXEMPT_TYPES{ ref $elem };

    if (    $elem->find_first(\&_low_boolean)
         && $elem->find_first(\&_high_boolean) ) {

        return $self->violation( $DESC, $EXPL, $elem );
    }
    return;    #ok!
}

#-----------------------------------------------------------------------------

sub _low_boolean {
    my (undef, $elem) = @_;
    return if $elem->isa('PPI::Statement');
    $elem->isa('PPI::Token::Operator') || return 0;
    return exists $LOW_BOOLEANS{$elem};
}

#-----------------------------------------------------------------------------

sub _high_boolean {
    my (undef, $elem) = @_;
    return if $elem->isa('PPI::Statement');
    $elem->isa('PPI::Token::Operator') || return 0;
    return exists $HIGH_BOOLEANS{$elem};
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitMixedBooleanOperators - Write C< !$foo && $bar || $baz > instead of C< not $foo && $bar or $baz>.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Conway advises against combining the low-precedence booleans ( C<and
or not> ) with the high-precedence boolean operators ( C<&& || !> ) in
the same expression.  Unless you fully understand the differences
between the high and low-precedence operators, it is easy to
misinterpret expressions that use both.  And even if you do understand
them, it is not always clear if the author actually intended it.

    next if not $foo || $bar;  #not ok
    next if !$foo || $bar;     #ok
    next if !( $foo || $bar ); #ok


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


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
