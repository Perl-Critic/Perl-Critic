##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################
package Perl::Critic::Policy::Modules::ProhibitEvilModules;

use 5.006001;
use strict;
use warnings;
use English qw(-no_match_vars);
use Readonly;

use List::MoreUtils qw(any);

use Perl::Critic::Exception::Configuration::Option::Policy::ParameterValue
    qw{ throw_policy_value };
use Perl::Critic::Utils qw{
    :booleans :characters :severities :data_conversion
};

use base 'Perl::Critic::Policy';

our $VERSION = '1.093_01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL => q{Find an alternative module};
Readonly::Scalar my $DESC => q{Prohibited module used};

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'modules',
            description     => 'The names of or patterns for modules to forbid.',
            default_string  => $EMPTY,
            behavior        => 'string list',
        },
    );
}

sub default_severity  { return $SEVERITY_HIGHEST         }
sub default_themes    { return qw( core bugs )           }
sub applies_to        { return 'PPI::Statement::Include' }

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    my ($self, $config) = @_;

    $self->{_evil_modules}    = {};  #Hash
    $self->{_evil_modules_rx} = [];  #Array

    #Set config, if defined
    if ( defined $self->{_modules} ) {
        my @modules = sort keys %{ $self->{_modules} };
        foreach my $module ( @modules ) {
            if ( $module =~ m{ \A [/] (.+) [/] \z }xms ) {

                # These are module name patterns (e.g. /Acme/)
                my $re = $1; # Untainting
                my $pattern = eval { qr/$re/ };  ## no critic (RegularExpressions::.*)

                if ( $EVAL_ERROR ) {
                    throw_policy_value
                        policy         => $self->get_short_name(),
                        option_name    => 'modules',
                        option_value   => ( join q{", "}, @modules ),
                        message_suffix =>
                            qq{contains an invalid regular expression: "$module"};
                }

                push @{ $self->{_evil_modules_rx} }, $pattern;
            }
            else {
                # These are literal module names (e.g. Acme::Foo)
                $self->{_evil_modules}->{$module} = 1;
            }
        }
    }

    return $TRUE;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    my $module = $elem->module();
    return if !$module;

    if ( exists $self->{_evil_modules}->{ $module } ||
         any { $module =~ $_ } @{ $self->{_evil_modules_rx} } ) {

        return $self->violation( $DESC, $EXPL, $elem );
    }
    return;    #ok!
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Modules::ProhibitEvilModules - Ban modules that aren't blessed by your shop.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Use this policy if you wish to prohibit the use of specific modules.
These may be modules that you feel are deprecated, buggy, unsupported,
insecure, or just don't like.


=head1 CONFIGURATION

The set of prohibited modules is configurable via the C<modules>
option.  The value of C<modules> should be a string of
space-delimited, fully qualified module names and/or regular
expressions.  An example of prohibiting two specific modules in a
F<.perlcriticrc> file:

    [Modules::ProhibitEvilModules]
    modules = Getopt::Std Autoload

Regular expressions are identified by values beginning and ending with
slashes.  Any module with a name that matches C<m/pattern/> will be
forbidden.  For example:

    [Modules::ProhibitEvilModules]
    modules = /Acme::/

would cause all modules that match C<m/Acme::/> to be forbidden.  You
can add any of the C<imxs> switches to the end of a pattern, but be
aware that patterns cannot contain whitespace because the
configuration file parser uses it to delimit the module names and
patterns.

By default, there are no prohibited modules (although I can think of a
few that should be).


=head1 NOTES

Note that this policy doesn't apply to pragmas.  Future versions may
allow you to specify an alternative for each prohibited module, which
can be suggested by L<Perl::Critic|Perl::Critic>.


=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2005-2008 Jeffrey Ryan Thalhammer.  All rights reserved.

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
