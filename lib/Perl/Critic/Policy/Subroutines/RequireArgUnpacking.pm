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

Readonly::Scalar my $AT => q{@}; ##no critic(Interpolation)
Readonly::Scalar my $AT_ARG => q{@_}; ##no critic(Interpolation)

Readonly::Scalar my $DESC => qq{Always unpack $AT_ARG first};
Readonly::Scalar my $EXPL => [178];

#-----------------------------------------------------------------------------

sub supported_parameters { return qw(short_subroutine_statements) }
sub default_severity     { return $SEVERITY_HIGH           }
sub default_themes       { return qw( core pbp maintance ) }
sub applies_to           { return 'PPI::Statement::Sub'    }

#-----------------------------------------------------------------------------

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);

    my %config = @args;

    #Set configuration if defined
    $self->{_short_subroutine_statements} = defined $config{short_subroutine_statements}
        && $config{short_subroutine_statements} =~ m/(\d+)/xms
            ? $1 : 0;

    return $self;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    # forward declaration?
    return if !$elem->block;

    my @statements = $elem->block->schildren;

    # empty sub?
    return if !@statements;

    # Don't apply policy to short subroutines

    # Should we instead be doing a find() for PPI::Statement
    # instances?  That is, should we count all statements instead of
    # just top-level statements?
    return if $self->{_short_subroutine_statements} >= @statements;

    # look for explicit dereferences of @_, including '$_[0]'
    # You may use "... = @_;" in the first paragraph of the sub
    # Don't descend into nested or anonymous subs
    my $state = 'unpacking'; # still in unpacking paragraph
    for my $statement (@statements) {

        my @magic = _get_arg_symbols($statement);

        my $saw_unpack = 0;
      MAGIC:
        for my $magic (@magic) {
            if ($AT eq $magic->raw_type) {  # this is '@_', not '$_[0]'
                my $prev = $magic->sprevious_sibling;
                my $next = $magic->snext_sibling;

                # allow conditional checks on the size of @_
                next MAGIC if _is_size_check($magic);

                if ('unpacking' eq $state) {
                    if (_is_unpack($magic)) {
                        $saw_unpack = 1;
                        next MAGIC;
                    }
                }
            }
            return $self->violation( $DESC, $EXPL, $elem );
        }
        if (!$saw_unpack) {
            $state = 'post_unpacking';
        }
    }
    return;  # OK
}

sub _is_unpack {
    my ($magic) = @_;

    my $prev = $magic->sprevious_sibling;
    my $next = $magic->snext_sibling;

    return 1 if ($prev && $prev->isa('PPI::Token::Operator') && q{=} eq $prev &&
                 (!$next || ($next->isa('PPI::Token::Structure') && q{;} eq $next)));
    return;
}

sub _is_size_check {
    my ($magic) = @_;

    my $prev = $magic->sprevious_sibling;
    my $next = $magic->snext_sibling;

    return 1 if !$next && $prev && $prev->isa('PPI::Token::Operator') &&
      (q{==} eq $prev || q{!=} eq $prev);
    return 1 if !$prev && $next && $next->isa('PPI::Token::Operator') &&
      (q{==} eq $next || q{!=} eq $next);
    return;
}

sub _get_arg_symbols {
    my ($statement) = @_;

    return grep {$AT_ARG eq $_->symbol} @{$statement->find(\&_magic_finder) || []};
}

sub _magic_finder {
    # Find all @_ and $_[\d+] not inside of nested subs
    my (undef, $elem) = @_;
    return 1 if $elem->isa('PPI::Token::Magic'); # match

    if ($elem->isa('PPI::Structure::Block')) {
        # don't descend into a nested named sub
        return if $elem->statement->isa('PPI::Statement::Sub');

        my $prev = $elem->sprevious_sibling;
        # don't descend into a nested anon sub block
        return if $prev && $prev->isa('PPI::Token::Word') && 'sub' eq $prev;
    }

    return 0; # no match, descend
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::RequireArgUnpacking

=head1 DESCRIPTION

Subroutines that use C<@_> directly instead of unpacking the arguments to
local variables first have two major problems.  First, they are very hard to
read.  If you're going to refer to your variables by number instead of by
name, you may as well be writing assembler code!  Second, C<@_> contains
aliases to the original variables!  If you modify the contents of a C<@_>
entry, then you are modifying the variable outside of your subroutine.  For
example:

   sub print_local_var_plus_one {
       my ($var) = @_;
       print ++$var;
   }
   sub print_var_plus_one {
       print ++$_[0];
   }

   my $x = 2;
   print_local_var_plus_one($x); # prints "3", $x is still 2
   print_var_plus_one($x);       # prints "3", $x is now 3 !
   print $x;                     # prints "3"

This is spooky action-at-a-distance and is very hard to debug if it's not
intentional and well-documented (like C<chop> or C<chomp>).

=head1 CONFIGURATION

This policy is lenient for subroutines which have C<N> or fewer top-level
statements, where C<N> defaults to ZERO.  You can override this to set it to a
higher number with the C<short_subroutine_statements> setting.  This is very
much not recommended but perhaps you REALLY need high performance.  To do
this, put entries in a F<.perlcriticrc> file like this:

  [Subroutines::RequireArgUnpacking]
  short_subroutine_statements = 2

=head1 CAVEATS

PPI doesn't currently detect anonymous subroutines, so we don't check those.
This should just work when PPI gains that feature.

We don't check for C<@ARG>, the alias for C<@_> from English.pm.  That's
deprecated anyway.

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
