##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::NamingConventions::ProhibitAmbiguousNames;

use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :booleans :severities :data_conversion };
use base 'Perl::Critic::Policy';

our $VERSION = '1.081_001';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => 'Ambiguous name for variable or subroutine';
Readonly::Scalar my $EXPL => [ 48 ];

Readonly::Array my @DEFAULT_FORBID =>
    qw( last      contract
        set       record
        left      second
        right     close
        no        bases
        abstract
    );

#-----------------------------------------------------------------------------

sub supported_parameters { return qw( forbid )             }
sub default_severity { return $SEVERITY_MEDIUM         }
sub default_themes   { return qw(core pbp maintenance) }
sub applies_to       { return qw(PPI::Statement::Sub
                                 PPI::Statement::Variable) }

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    my ($self, $config) = @_;

    #Set configuration, if defined
    my @forbid;
    if ( defined $config->{forbid} ) {
        @forbid = words_from_string( $config->{forbid} );
    }
    else {
        @forbid = @DEFAULT_FORBID;
    }
    $self->{_forbid} = { hashify( @forbid ) };

    return $TRUE;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    if ( $elem->isa('PPI::Statement::Sub') ) {
        my @words = grep { $_->isa('PPI::Token::Word') } $elem->schildren();
        for my $word (@words) {

            # strip off any leading "Package::"
            my ($name) = $word =~ m/ (\w+) \z /xms;
            next if not defined $name; # should never happen, right?

            if ( exists $self->{_forbid}->{$name} ) {
                return $self->violation( $DESC, $EXPL, $elem );
            }
        }
        return;    # ok
    }
    else {         # PPI::Statement::Variable

        # Accumulate them since there can be more than one violation
        # per variable statement
        my @viols;

        # TODO: false positive bug - this can erroneously catch the
        # assignment half of a variable statement

        my $symbols = $elem->find('PPI::Token::Symbol');
        if ($symbols) {   # this should always be true, right?
            for my $symbol ( @{$symbols} ) {

                # Strip off sigil and any leading "Package::"
                # Beware that punctuation vars may have no
                # alphanumeric characters.

                my ($name) = $symbol =~ m/ (\w+) \z /xms;
                next if ! defined $name;

                if ( exists $self->{_forbid}->{$name} ) {
                    push @viols, $self->violation( $DESC, $EXPL, $elem );
                }
            }
        }
        return @viols;
    }
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords bioinformatics

=head1 NAME

Perl::Critic::Policy::NamingConventions::ProhibitAmbiguousNames

=head1 DESCRIPTION

Conway lists a collection of English words which are highly ambiguous
as variable or subroutine names.  For example, C<$last> can mean
previous or final.

This policy tests against a list of ambiguous words for variable
names.

=head1 CONFIGURATION

The default list of forbidden words is:

  last set left right no abstract contract record second close bases

This list can be changed by giving a value for C<forbid> of a series of
forbidden words separated by spaces.

For example, if you decide that C<bases> is an OK name for variables (e.g.
in bioinformatics), then put something like the following in
C<$HOME/.perlcriticrc>:

  [NamingConventions::ProhibitAmbiguousNames]
  forbid = last set left right no abstract contract record second close

=head1 METHODS

=over 8

=back

=head1 BUGS

Currently this policy checks the entire variable and subroutine name,
not parts of the name.  For example, it catches C<$last> but not
C<$last_record>.  Hopefully future versions will catch both cases.

Some variable statements will be false positives if they have
assignments where the right hand side uses forbidden names.  For
example, in this case the C<last> incorrectly triggers a violation.

    my $previous_record = $Foo::last;

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2007 Chris Dolan.  All rights reserved.

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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
