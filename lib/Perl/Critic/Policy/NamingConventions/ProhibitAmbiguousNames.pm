package Perl::Critic::Policy::NamingConventions::ProhibitAmbiguousNames;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :data_conversion };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL => [ 48 ];

Readonly::Scalar my $DEFAULT_FORBID =>
    'abstract bases close contract last left no record right second set';

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'forbid',
            description     => 'The variable names that are not to be allowed.',
            default_string  => $DEFAULT_FORBID,
            behavior        => 'string list',
        },
    );
}

sub default_severity { return $SEVERITY_MEDIUM         }
sub default_themes   { return qw(core pbp maintenance) }
sub applies_to       { return qw(PPI::Statement::Sub
                                 PPI::Statement::Variable) }

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
                return $self->violation(
                    qq<Ambiguously named subroutine "$name">,
                    $EXPL,
                    $elem,
                );
            }
        }
        return;    # ok
    }

    # PPI::Statement::Variable

    # Accumulate them since there can be more than one violation
    # per variable statement
    my @violations;

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
                push
                    @violations,
                    $self->violation(
                        qq<Ambiguously named variable "$name">,
                        $EXPL,
                        $elem,
                    );
            }
        }
    }

    return @violations;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords bioinformatics

=head1 NAME

Perl::Critic::Policy::NamingConventions::ProhibitAmbiguousNames - Don't use vague variable or subroutine names like 'last' or 'record'.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Conway lists a collection of English words which are highly ambiguous
as variable or subroutine names.  For example, C<$last> can mean
previous or final.

This policy tests against a list of ambiguous words for variable
names.


=head1 CONFIGURATION

The default list of forbidden words is:

    abstract bases close contract last left no record right second set

This list can be changed by giving a value for C<forbid> of a series
of forbidden words separated by spaces.

For example, if you decide that C<bases> is an OK name for variables
(e.g.  in bioinformatics), then put something like the following in
C<$HOME/.perlcriticrc>:

    [NamingConventions::ProhibitAmbiguousNames]
    forbid = last set left right no abstract contract record second close


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

Copyright (c) 2005-2011 Chris Dolan.

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
