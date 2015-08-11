package Perl::Critic::Policy::Variables::ProhibitReusedNames;

use 5.006001;
use strict;
use warnings;
use List::MoreUtils qw(part);
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :data_conversion };

use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Reused variable name in lexical scope: };
Readonly::Scalar my $EXPL => q{Invent unique variable names};

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'allow',
            description     => 'The variables to not consider as duplicates.',
            default_string  => '$self $class',    ## no critic (RequireInterpolationOfMetachars)
            behavior        => 'string list',
        },
    );
}

sub default_severity     { return $SEVERITY_MEDIUM           }
sub default_themes       { return qw( core bugs )            }
sub applies_to           { return 'PPI::Document' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    return $self->_get_violations_below_element_given_seen_vars($doc, {});
}

# modifies $seen_vars
sub _get_violations_below_element_given_seen_vars { 
	my ( $self, $elem, $seen_vars ) = @_;   

	return unless ($elem->isa('PPI::Node'));

	my @violations;

	foreach my $child_elem ($elem->schildren) {
	        if ($child_elem->isa('PPI::Statement::Variable') && $child_elem->type ne 'local') {
                    foreach my $var ($child_elem->variables) {
                        if (!$self->{_allow}{$var} && $seen_vars->{$var}++) {
                            push @violations, $self->violation( $DESC . $var, $EXPL, $child_elem );
                        }
                    }
                }
                push @violations, $self->_get_violations_below_element_given_seen_vars($child_elem, {%{$seen_vars}});
	}

	return @violations;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Variables::ProhibitReusedNames - Do not reuse a variable name in a lexical scope


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

It's really hard on future maintenance programmers if you reuse a
variable name in a lexical scope. The programmer is at risk of
confusing which variable is which. And, worse, the programmer could
accidentally remove the inner declaration, thus silently changing the
meaning of the inner code to use the outer variable.

    my $x = 1;
    for my $i (0 .. 10) {
        my $x = $i+1;  # not OK, "$x" reused
    }

With C<use warnings> in effect, Perl will warn you if you reuse a
variable name at the same scope level but not within nested scopes.  Like so:

    % perl -we 'my $x; my $x'
    "my" variable $x masks earlier declaration in same scope at -e line 1.

This policy takes that warning to a stricter level.


=head1 CAVEATS

=head2 Crossing subroutines

This policy looks across subroutine boundaries.  So, the following may
be a false positive for you:

    sub make_accessor {
        my ($self, $fieldname) = @_;
        return sub {
            my ($self) = @_;  # false positive, $self declared as reused
            return $self->{$fieldname};
        }
    }

This is intentional, though, because it catches bugs like this:

    my $debug_mode = 0;
    sub set_debug {
        my $debug_mode = 1;  # accidental redeclaration
    }

I've done this myself several times -- it's a strong habit to put that
"my" in front of variables at the start of subroutines.


=head1 CONFIGURATION

This policy has a single option, C<allow>, which is a list of names to
never count as duplicates.  It defaults to containing C<$self> and
C<$class>.  You add to this by adding something like this to your
F<.perlcriticrc>:

    [Variables::ProhibitReusedNames]
    allow = $self $class @blah


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

This policy is inspired by
L<http://use.perl.org/~jdavidb/journal/37548>.  Java does not allow
you to reuse variable names declared in outer scopes, which I think is
a nice feature.

=head1 COPYRIGHT

Copyright (c) 2008-2013 Chris Dolan

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

