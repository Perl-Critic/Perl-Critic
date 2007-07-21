##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::Subroutines::RequireArgUnpacking;

use strict;
use warnings;
use Readonly;

use File::Spec;
use List::Util qw(first);
use List::MoreUtils qw(uniq any);
use English qw(-no_match_vars);
use Carp;

use Perl::Critic::Utils qw{ :severities &words_from_string };
use base 'Perl::Critic::Policy';

our $VERSION = 1.06;

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Always unpack @_ first};
Readonly::Scalar my $EXPL => [178];

#-----------------------------------------------------------------------------

sub supported_parameters { return qw(forbid_array_form forbid_shift_form
                                     short_subroutine_statements) }
sub default_severity     { return $SEVERITY_HIGH           }
sub default_themes       { return qw( core pbp maintance ) }
sub applies_to           { return 'PPI::Statement::Sub'    }

#-----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    my (%config) = @_;

    #Set configuration if defined
    $self->{_forbid_array_form} = $config{forbid_array_form} ? 1 : 0;
    $self->{_forbid_shift_form} = $config{forbid_shift_form} ? 1 : 0;
    if ($self->{_forbid_array_form} && $self->{_forbid_shift_form}) {
       croak q{Don't set both forbid_array_form and forbid_shift_form in your } .
           __PACKAGE__ . q{ configuration};
    }

    $self->{_short_subroutine_statements} = defined $config{short_subroutine_statements}
        && $config{short_subroutine_statements} =~ m/(\d+)/xms
            ? $1 : 1;

    return $self;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    # BEGIN, END, etc don't take arguments
    return if $elem->isa('PPI::Statement::Scheduled');

    # forward declaration?
    return if !$elem->block;

    # Ignore subs that are declared to take no args
    return if '()' eq $elem->prototype;

    my @statements = $elem->block->schildren;

    # empty sub?
    return if !@statements;

    # look for explicit dereferences of @_ (e.g. '$_[0]')
    # This is a violation even if the subroutine is short
    for my $statement (@statements) {
        if (any {'@_' eq $_->symbol && '$' eq $_->raw_type}
            @{$statement->find('PPI::Token::Magic') || []}) {
           return $self->violation( $DESC, $EXPL, $elem );
        }
    }

    # Don't apply policy to short subroutines

    # Should we instead be doing a find() for PPI::Statement
    # instances?  That is, should we count all statements instead of
    # just top-level statements?
    return if $self->{_short_subroutine_statements} >= @statements;

    # Now, examine the first statement to see if it unpacks @_
    my $first = $statements[0];

    # If the first statement is not a "my" declaration, it's no good
    if ($first->isa('PPI::Statement::Variable') && $first->type && 'my' eq $first->type) {
        # look for 'my $foo = shift;' or 'my ($foo) = @_;'
        my @children = $first->schildren();
        my $content = join q{ }, @children;

        return if !$self->{_forbid_shift_form} &&
            $content =~ m/\A my [ ] .*? [ ] = [ ] shift (?: [ ] ;)* \z/xms;
        return if !$self->{_forbid_array_form} &&
            $content =~ m/\A my [ ] .*? [ ] = [ ] \@_ (?: [ ] ;)* \z/xms;
    }

    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::RequireArgUnpacking

=head1 DESCRIPTION

WRITEIT!!

=head1 CONFIGURATION

Do you have a preference for C<my $foo = shift;> or C<my ($foo) =
@_;>?  You can set one of the C<forbid_array_form> or
C<forbid_shift_form> parameters to true to block the one you don't
like.  It's an error to set both of them.

This policy is lenient for subroutines which have C<N> or fewer
top-level statements, where C<N> defaults to C<1>.  You can override
this to set it to a higher (or lower!) number with the
C<short_subroutine_statements> setting.

To make changes like these, put entries in a F<.perlcriticrc> file
like this:

  [Subroutines::RequireArgUnpacking]
  forbid_shift_form = true
  short_subroutine_statements = 2

=head1 CREDITS

Initial development of this policy was supported by a grant from the Perl Foundation.

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2007 Chris Dolan.  Many rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
