package Perl::Critic::Policy::ControlStructures::ProhibitDeepNests;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Code structure is deeply nested};
Readonly::Scalar my $EXPL => q{Consider refactoring};

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'max_nests',
            description     => 'The maximum number of nested constructs to allow.',
            default_string  => '5',
            behavior        => 'integer',
            integer_minimum => 1,
        },
    );
}

sub default_severity { return $SEVERITY_MEDIUM                }
sub default_themes   { return qw(core maintenance complexity) }
sub applies_to       { return 'PPI::Statement::Compound'      }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    my $nest_count = 1;  #For _this_ element
    my $parent = $elem;

    while ( $parent = $parent->parent() ){
        if( $parent->isa('PPI::Statement::Compound') ) {
            $nest_count++;
        }
    }

    if ( $nest_count > $self->{_max_nests} ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }
    return;    #ok!
}


1;

__END__


#-----------------------------------------------------------------------------

=pod

=for stopwords refactored

=head1 NAME

Perl::Critic::Policy::ControlStructures::ProhibitDeepNests - Don't write deeply nested loops and conditionals.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Deeply nested code is often hard to understand and may be a sign that
it needs to be refactored.  There are several good books on how to
refactor code.  I like Martin Fowler's "Refactoring: Improving The
Design of Existing Code".


=head1 CONFIGURATION

The maximum number of nested control structures can be configured via
a value for C<max_nests> in a F<.perlcriticrc> file.  Each for-loop,
if-else, while, and until block is counted as one nest.  Postfix forms
of these constructs are not counted.  The default maximum is 5.
Customization in a F<.perlcriticrc> file looks like this:

    [ControlStructures::ProhibitDeepNests]
    max_nests = 3

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
