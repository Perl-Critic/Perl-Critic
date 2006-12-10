##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################
package Perl::Critic::Policy::Modules::ProhibitEvilModules;

use strict;
use warnings;
use Carp qw(cluck);
use English qw(-no_match_vars);
use List::MoreUtils qw(any);
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.22;

my $expl = q{Find an alternative module};
my $desc = q{Prohibited module used};

#-----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGHEST         }
sub default_themes   { return qw(core bugs)                }
sub applies_to       { return 'PPI::Statement::Include' }

#-----------------------------------------------------------------------------

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;

    $self->{_evil_modules}    = {};  #Hash
    $self->{_evil_modules_rx} = [];  #Array

    #Set config, if defined
    if ( defined $args{modules} ) {
        for my $module ( words_from_string( $args{modules} ) ) {
            if ( $module =~ m{ \A [/] (.+) [/] \z }mx ) {
                # These are module name patterns (e.g. /Acme/)
                my $re = $1; # Untainting
                my $pattern = eval { qr/$re/ };
                if ( $EVAL_ERROR ) {
                    cluck qq{Regexp syntax error in "$module"};
                }
                else {
                    push @{ $self->{_evil_modules_rx} }, $pattern;
                }
            }
            else {
                # These are literal module names (e.g. Acme::Foo)
                $self->{_evil_modules}->{$module} = 1;
            }
        }
    }
    return $self;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    my $module = $elem->module();
    return if !$module;

    if ( exists $self->{_evil_modules}->{ $module } ||
         any { $module =~ $_ } @{ $self->{_evil_modules_rx} } ) {

        return $self->violation( $desc, $expl, $elem );
    }
    return;    #ok!
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Modules::ProhibitEvilModules

=head1 DESCRIPTION

Use this policy if you wish to prohibit the use of specific modules.
These may be modules that you feel are deprecated, buggy, unsupported,
insecure, or just don't like.

=head1 CONFIGURATION

The set of prohibited modules is configurable via the C<modules> option.  The
value of C<modules> should be a string of space-delimited, fully qualified
module names and/or regular expressions.  An example of prohibiting two
specific modules in a F<.perlcriticrc> file:

  [Modules::ProhibitEvilModules]
  modules = Getopt::Std Autoload

Regular expressions are identified by values beginning and ending with slashes.
Any module with a name that matches C<m/pattern/> will be forbidden.  For
example:

  [Modules::ProhibitEvilModules]
  modules = /Acme::/

would cause all modules that match C<m/Acme::/> to be forbidden.  You can add
any of the C<imxs> switches to the end of a pattern, but be aware that patterns
cannot contain whitespace because the configuration file parser uses it to
delimit the module names and patterns.

By default, there are no prohibited modules (although I can think of a few that
should be).

=head1 NOTES

Note that this policy doesn't apply to pragmas.  Future versions may
allow you to specify an alternative for each prohibited module, which
can be suggested by L<Perl::Critic>.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

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
