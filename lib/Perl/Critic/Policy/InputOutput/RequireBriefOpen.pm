##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::InputOutput::RequireBriefOpen;

use strict;
use warnings;
use Readonly;
use List::MoreUtils qw(any);

use Perl::Critic::Utils qw{ :severities :classification :booleans parse_arg_list };
use base 'Perl::Critic::Policy';

our $VERSION = 1.078;

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Close filehandles as soon as possible after opening them};
Readonly::Scalar my $EXPL => [209];

Readonly::Scalar my $DEFAULT_LINES => 9;

Readonly::Scalar my $DOLLAR => q{$};  ## no critic (Interpolation)

#-----------------------------------------------------------------------------

sub supported_parameters { return qw(lines)              }
sub default_severity     { return $SEVERITY_HIGH         }
sub default_themes       { return qw( core pbp maintenance ) }
sub applies_to           { return 'PPI::Token::Word'     }

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    my ($self, $config) = @_;

    #Set configuration if defined
    $self->{_lines} =
            defined $config->{lines}
        &&  $config->{lines} =~ m/(\d+)/mx
        &&  $1 > 0
            ? $1 : $DEFAULT_LINES;

    return $TRUE;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    # Is it a call to open?
    return if $elem ne 'open';
    return if ! is_function_call($elem);
    my @open_args = parse_arg_list($elem);
    return if 2 > @open_args; # not a valid call to open()

    my ($is_lexical, $fh) = _get_opened_fh($open_args[0]);
    if (!$fh) {
        # not a lexical filehandle nor a glob fliehandle

        #print {*STDERR} 'Failed to get fh: ', $elem->parent, "\n";
        return;
    }

    for my $close_token ($self->_find_close_invocations_or_return($elem)) {
        # The $close_token might be a close() or a return()
        #  It doesn't matter which -- both satisfy this policy
        if (is_function_call($close_token)) {
            my @close_args = parse_arg_list($close_token);
            return if $close_args[0] && $fh eq $close_args[0]->[0];
        } elsif ($is_lexical && is_method_call($close_token)) {
            my $tok = $close_token->sprevious_sibling->sprevious_sibling;
            return if $fh eq $tok;
        }
    }

    return $self->violation( $DESC, $EXPL, $elem );
}

sub _find_close_invocations_or_return {
    my ($self, $elem) = @_;

    my $parent = _get_scope($elem);
    return if !$parent; # I can't think of a scenario where this would happen

    my $open_loc = $elem->location;
    # we don't actually allow _lines to be zero or undef, but maybe we will
    my $end_line = $self->{_lines} ? $open_loc->[0] + $self->{_lines} : undef;

    my $closes = $parent->find(sub {
        ##no critic (ProhibitExplicitReturnUndef)
        my ($parent, $candidate) = @_;
        return undef if $candidate->isa('PPI::Statement::Sub');
        my $candidate_loc = $candidate->location;
        return undef if !defined $candidate_loc->[0];
        return 0 if $candidate_loc->[0] < $open_loc->[0];
        return 0 if $candidate_loc->[0] == $open_loc->[0] && $candidate_loc->[1] <= $open_loc->[1];
        return undef if defined $end_line && $candidate_loc->[0] > $end_line;
        return 0 if !$candidate->isa('PPI::Token::Word');
        return 1 if $candidate eq 'close' || $candidate eq 'return';
        return 0;
    });
    return @{$closes || []};
}

sub _get_scope {
    my ($elem) = @_;

    while ($elem = $elem->parent) {
        return $elem if $elem->scope;
    }
    return;  # should never happen if we are in a PPI::Document
}

sub _get_opened_fh {
    my ($tokens) = shift;

    my $is_lexical;
    my $fh;

    if (2 == @{$tokens}) {

       if ('my' eq $tokens->[0] &&
           $tokens->[1]->isa('PPI::Token::Symbol') &&
           $DOLLAR eq $tokens->[1]->raw_type) {

          $is_lexical = 1;
          $fh = $tokens->[1];
       }

    } elsif (1 == @{$tokens}) {

       my $arg = $tokens->[0];
       if ($arg->isa('PPI::Token::Symbol') &&
           $DOLLAR eq $arg->raw_type) {

          $is_lexical = 1;
          $fh = $arg;

       } elsif ($arg->isa('PPI::Token::Word') && $arg eq uc $arg) {

          $is_lexical = 0;
          $fh = $arg;
       }
    }

    return ($is_lexical, $fh);
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords redeclared

=head1 NAME

Perl::Critic::Policy::InputOutput::RequireBriefOpen

=head1 DESCRIPTION

One way that production systems fail unexpectedly is by running out of
filehandles.  Filehandles are a finite resource on every operating system that
I'm aware of, and running out of them is virtually impossible to recover from.
The solution is to not run out in the first place.  What causes programs to
run out of filehandles?  Usually, it's leaks: you open a filehandle and forget
to close it, or just wait a really long time before closing it.

This problem is rarely exposed by test systems, because the tests rarely run
long enough or have enough load to hit the filehandle limit.  So, the best way
to avoid the problem is 1) always close all filehandles that you open and 2)
close them as soon as is practical.

This policy takes note of calls to C<open()> where there is no matching
C<close()> call within C<N> lines of code.  If you really need to do a lot of
processing on an open filehandle, then you can move that processing to another
method like this:

    sub process_data_file {
        my ($self, $filename) = @_;
        open my $fh, '<', $filename
            or croak 'Failed to read datafile ' .  $filename . '; ' . $OS_ERROR;
        $self->_parse_input_data($fh);
        close $fh;
        return;
    }
    sub _parse_input_data {
        my ($self, $fh) = @_;
        while (my $line = <$fh>) {
            ...
        }
        return;
    }

As a special case, this policy also allows code to return the filehandle after
the C<open> instead of closing it.  Just like the close, however, that
C<return> has to be within the right number of lines.  From there, you're on
your own to figure out whether the code is promptly closing the filehandle.

=head1 CONFIGURATION

This policy allows C<close()> invocations to be up to C<N> lines after their
corresponding C<open()> calls, where C<N> defaults to 9.  You can override
this to set it to a different number with the C<lines> setting.  To do this,
put entries in a F<.perlcriticrc> file like this:

  [InputOutput::RequireBriefOpen]
  lines = 5

=head1 CAVEATS

=head2 C<IO::File-E<gt>new>

This policy only looks for explicit C<open> calls.  It does not detect calls
to C<CORE::open> or C<IO::File-E<gt>new> or the like.

=head2 Is it the right lexical?

We don't currently check for redeclared filehandles.  So the following code
is false negative, for example, because the outer scoped filehandle is not closed:

    open my $fh, '<', $file1 or croak;
    if (open my $fh, '<', $file2) {
        print <$fh>;
        close $fh;
    }

This is a contrived example, but it isn't uncommon for people to use C<$fh>
for the name of the filehandle every time.  Perhaps it's time to think of
better variable names...

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
