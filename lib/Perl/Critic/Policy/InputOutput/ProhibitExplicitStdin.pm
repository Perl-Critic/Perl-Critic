package Perl::Critic::Policy::InputOutput::ProhibitExplicitStdin;

use 5.006001;
use strict;
use warnings;
use Readonly;
use List::MoreUtils qw(any);

use Perl::Critic::Utils qw{ :severities :classification &parse_arg_list };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Use "<>" or "<ARGV>" or a prompting module instead of "<STDIN>"};
Readonly::Scalar my $EXPL => [216,220,221];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                                }
sub default_severity     { return $SEVERITY_HIGH                    }
sub default_themes       { return qw( core pbp maintenance )        }
sub applies_to           { return 'PPI::Token::QuoteLike::Readline' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem ne '<STDIN>';
    return $self->violation( $DESC, $EXPL, $elem );
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::InputOutput::ProhibitExplicitStdin - Use "<>" or "<ARGV>" or a prompting module instead of "<STDIN>".

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Perl has a useful magic filehandle called C<*ARGV> that checks the
command line and if there are any arguments, opens and reads those as
files.  If there are no arguments, C<*ARGV> behaves like C<*STDIN>
instead.  This behavior is almost always what you want if you want to
create a program that reads from C<STDIN>.  This is often written in
one of the following two equivalent forms:

  while (<ARGV>) {
    # ... do something with each input line ...
  }
  # or, equivalently:
  while (<>) {
    # ... do something with each input line ...
  }

If you want to prompt for user input, try special purpose modules like
L<IO::Prompt|IO::Prompt>.


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 CAVEATS

Due to a bug in the current version of PPI (v1.119_03) and earlier,
the readline operator is often misinterpreted as less-than and
greater-than operators after a comma.  Therefore, this policy misses
important cases like

  my $content = join '', <STDIN>;

because it interprets that line as the nonsensical statement:

  my $content = join '', < STDIN >;

When that PPI bug is fixed, this policy should start catching those
violations automatically.

=head1 CREDITS

Initial development of this policy was supported by a grant from the
Perl Foundation.

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2007-2011 Chris Dolan.  Many rights reserved.

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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
