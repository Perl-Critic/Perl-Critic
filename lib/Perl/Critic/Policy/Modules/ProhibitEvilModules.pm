#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################
package Perl::Critic::Policy::Modules::ProhibitEvilModules;

use strict;
use warnings;
use Carp qw(cluck);
use English qw(-no_match_vars);
use List::MoreUtils qw(any);
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = '0.18_01';
$VERSION = eval $VERSION;    ## no critic

my $expl = q{Find an alternative module};
my $desc = q{Prohibited module used};

#----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGHEST }
sub applies_to { return 'PPI::Statement::Include' }

#----------------------------------------------------------------------------

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;

    $self->{_evil_modules}    = {};  #Hash
    $self->{_evil_modules_rx} = [];  #Array

    #Set config, if defined
    if ( defined $args{modules} ) {
        for my $module ( split m{ \s+ }mx, $args{modules} ) {
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

#----------------------------------------------------------------------------

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

#----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Modules::ProhibitEvilModules

=head1 DESCRIPTION

Use this policy if you wish to prohibit the use of specific modules.
These may be modules that you feel are deprecated, buggy, unsupported,
insecure, or just don't like.

=head1 CONSTRUCTOR

This policy accepts an additional key-value pair in the C<new> method.
The key should be 'modules' and the value is a string of
space-delimited fully qualified module names.  These can be configured
in the F<.perlcriticrc> file like this:

 [Modules::ProhibitEvilModules]
 modules = Getopt::Std  Autoload

If any module name in your configuration is braced with slashes, it
is interpreted as a regular expression.  So any module that matches
C<m/$module_name/> will be forbidden.  For example:

  [Modules::ProhibitEvilModules]
  modules = /Acme::/

would cause all modules that match C<m/Acme::/> to be forbidden.  You
can add any of the C<imxs> switches to the end of the pattern, but
beware that your pattern should not contain spaces, lest the parser
get confused.

By default, there are no prohibited modules (although I can think
of a few that should be).

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
