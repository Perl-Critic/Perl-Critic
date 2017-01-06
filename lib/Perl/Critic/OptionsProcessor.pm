package Perl::Critic::OptionsProcessor;

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::Critic::Exception::AggregateConfiguration;
use Perl::Critic::Exception::Configuration::Option::Global::ExtraParameter;
use Perl::Critic::Utils qw<
    :booleans :characters :severities :data_conversion $DEFAULT_VERBOSITY
>;
use Perl::Critic::Utils::Constants qw<
    $PROFILE_STRICTNESS_DEFAULT
    :color_severity
    >;
use Perl::Critic::Utils::DataConversion qw< dor >;

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    $self->_init( %args );
    return $self;
}

#-----------------------------------------------------------------------------

sub _init {
    my ( $self, %args ) = @_;

    # Multi-value defaults
    my $exclude = dor(delete $args{exclude}, $EMPTY);
    $self->{_exclude}    = [ words_from_string( $exclude ) ];

    my $include = dor(delete $args{include}, $EMPTY);
    $self->{_include}    = [ words_from_string( $include ) ];

    my $program_extensions = dor(delete $args{'program-extensions'}, $EMPTY);
    $self->{_program_extensions} = [ words_from_string( $program_extensions) ];

    # Single-value defaults
    $self->{_force}           = dor(delete $args{force},              $FALSE);
    $self->{_only}            = dor(delete $args{only},               $FALSE);
    $self->{_profile_strictness} =
        dor(delete $args{'profile-strictness'}, $PROFILE_STRICTNESS_DEFAULT);
    $self->{_single_policy}   = dor(delete $args{'single-policy'},    $EMPTY);
    $self->{_severity}        = dor(delete $args{severity},           $SEVERITY_HIGHEST);
    $self->{_theme}           = dor(delete $args{theme},              $EMPTY);
    $self->{_top}             = dor(delete $args{top},                $FALSE);
    $self->{_verbose}         = dor(delete $args{verbose},            $DEFAULT_VERBOSITY);
    $self->{_criticism_fatal} = dor(delete $args{'criticism-fatal'},  $FALSE);
    $self->{_pager}           = dor(delete $args{pager},              $EMPTY);
    $self->{_allow_unsafe}    = dor(delete $args{'allow-unsafe'},     $FALSE);

    $self->{_color_severity_highest} = dor(
        delete $args{'color-severity-highest'},
        delete $args{'colour-severity-highest'},
        delete $args{'color-severity-5'},
        delete $args{'colour-severity-5'},
        $PROFILE_COLOR_SEVERITY_HIGHEST_DEFAULT,
    );
    $self->{_color_severity_high} = dor(
        delete $args{'color-severity-high'},
        delete $args{'colour-severity-high'},
        delete $args{'color-severity-4'},
        delete $args{'colour-severity-4'},
        $PROFILE_COLOR_SEVERITY_HIGH_DEFAULT,
    );
    $self->{_color_severity_medium} = dor(
        delete $args{'color-severity-medium'},
        delete $args{'colour-severity-medium'},
        delete $args{'color-severity-3'},
        delete $args{'colour-severity-3'},
        $PROFILE_COLOR_SEVERITY_MEDIUM_DEFAULT,
    );
    $self->{_color_severity_low} = dor(
        delete $args{'color-severity-low'},
        delete $args{'colour-severity-low'},
        delete $args{'color-severity-2'},
        delete $args{'colour-severity-2'},
        $PROFILE_COLOR_SEVERITY_LOW_DEFAULT,
    );
    $self->{_color_severity_lowest} = dor(
        delete $args{'color-severity-lowest'},
        delete $args{'colour-severity-lowest'},
        delete $args{'color-severity-1'},
        delete $args{'colour-severity-1'},
        $PROFILE_COLOR_SEVERITY_LOWEST_DEFAULT,
    );

    # If we're using a pager or not outputing to a tty don't use colors.
    # Can't use IO::Interactive here because we /don't/ want to check STDIN.
    my $default_color = ($self->pager() or not -t *STDOUT) ? $FALSE : $TRUE; ## no critic (ProhibitInteractiveTest)
    $self->{_color} = dor(delete $args{color}, delete $args{colour}, $default_color);

    # If there's anything left, complain.
    _check_for_extra_options(%args);

    return $self;
}

#-----------------------------------------------------------------------------

sub _check_for_extra_options {
    my %args = @_;

    if ( my @remaining = sort keys %args ){
        my $errors = Perl::Critic::Exception::AggregateConfiguration->new();

        foreach my $option_name (@remaining) {
            $errors->add_exception(
                Perl::Critic::Exception::Configuration::Option::Global::ExtraParameter->new(
                    option_name     => $option_name,
                )
            )
        }

        $errors->rethrow();
    }

    return;
}

#-----------------------------------------------------------------------------
# Public ACCESSOR methods

sub severity {
    my ($self) = @_;
    return $self->{_severity};
}

#-----------------------------------------------------------------------------

sub theme {
    my ($self) = @_;
    return $self->{_theme};
}

#-----------------------------------------------------------------------------

sub exclude {
    my ($self) = @_;
    return $self->{_exclude};
}

#-----------------------------------------------------------------------------

sub include {
    my ($self) = @_;
    return $self->{_include};
}

#-----------------------------------------------------------------------------

sub only {
    my ($self) = @_;
    return $self->{_only};
}

#-----------------------------------------------------------------------------

sub profile_strictness {
    my ($self) = @_;
    return $self->{_profile_strictness};
}

#-----------------------------------------------------------------------------

sub single_policy {
    my ($self) = @_;
    return $self->{_single_policy};
}

#-----------------------------------------------------------------------------

sub verbose {
    my ($self) = @_;
    return $self->{_verbose};
}

#-----------------------------------------------------------------------------

sub color {
    my ($self) = @_;
    return $self->{_color};
}

#-----------------------------------------------------------------------------

sub pager {
    my ($self) = @_;
    return $self->{_pager};
}

#-----------------------------------------------------------------------------

sub allow_unsafe {
    my ($self) = @_;
    return $self->{_allow_unsafe};
}

#-----------------------------------------------------------------------------

sub criticism_fatal {
    my ($self) = @_;
    return $self->{_criticism_fatal};
}

#-----------------------------------------------------------------------------

sub force {
    my ($self) = @_;
    return $self->{_force};
}

#-----------------------------------------------------------------------------

sub top {
    my ($self) = @_;
    return $self->{_top};
}

#-----------------------------------------------------------------------------

sub color_severity_highest {
    my ($self) = @_;
    return $self->{_color_severity_highest};
}

#-----------------------------------------------------------------------------

sub color_severity_high {
    my ($self) = @_;
    return $self->{_color_severity_high};
}

#-----------------------------------------------------------------------------

sub color_severity_medium {
    my ($self) = @_;
    return $self->{_color_severity_medium};
}

#-----------------------------------------------------------------------------

sub color_severity_low {
    my ($self) = @_;
    return $self->{_color_severity_low};
}

#-----------------------------------------------------------------------------

sub color_severity_lowest {
    my ($self) = @_;
    return $self->{_color_severity_lowest};
}

#-----------------------------------------------------------------------------

sub program_extensions {
    my ($self) = @_;
    return $self->{_program_extensions};
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::OptionsProcessor - The global configuration default values, combined with command-line values.


=head1 DESCRIPTION

This is a helper class that encapsulates the default parameters for
constructing a L<Perl::Critic::Config|Perl::Critic::Config> object.
There are no user-serviceable parts here.


=head1 INTERFACE SUPPORT

This is considered to be a non-public class.  Its interface is subject
to change without notice.


=head1 CONSTRUCTOR

=over

=item C< new( %DEFAULT_PARAMS ) >

Returns a reference to a new C<Perl::Critic::OptionsProcessor> object.
You can override the coded defaults by passing in name-value pairs
that correspond to the methods listed below.

This is usually only invoked by
L<Perl::Critic::UserProfile|Perl::Critic::UserProfile>, which passes
in the global values from a F<.perlcriticrc> file.  This object
contains no information for individual Policies.

=back

=head1 METHODS

=over

=item C< exclude() >

Returns a reference to a list of the default exclusion patterns.  If
onto by
L<Perl::Critic::PolicyParameter|Perl::Critic::PolicyParameter>.  there
are no default exclusion patterns, then the list will be empty.


=item C< force() >

Returns the default value of the C<force> flag (Either 1 or 0).


=item C< include() >

Returns a reference to a list of the default inclusion patterns.  If
there are no default exclusion patterns, then the list will be empty.


=item C< only() >

Returns the default value of the C<only> flag (Either 1 or 0).


=item C< profile_strictness() >

Returns the default value of C<profile_strictness> as an unvalidated
string.


=item C< single_policy() >

Returns the default C<single-policy> pattern.  (As a string.)


=item C< severity() >

Returns the default C<severity> setting. (1..5).


=item C< theme() >

Returns the default C<theme> setting. (As a string).


=item C< top() >

Returns the default C<top> setting. (Either 0 or a positive integer).


=item C< verbose() >

Returns the default C<verbose> setting. (Either a number or format
string).


=item C< color() >

Returns the default C<color> setting. (Either 1 or 0).


=item C< pager() >

Returns the default C<pager> setting. (Either empty string or the pager
command string).


=item C< allow_unsafe() >

Returns the default C<allow-unsafe> setting. (Either 1 or 0).


=item C< criticism_fatal() >

Returns the default C<criticism-fatal> setting (Either 1 or 0).

=item C< color_severity_highest() >

Returns the color to be used for coloring highest severity violations.

=item C< color_severity_high() >

Returns the color to be used for coloring high severity violations.

=item C< color_severity_medium() >

Returns the color to be used for coloring medium severity violations.

=item C< color_severity_low() >

Returns the color to be used for coloring low severity violations.

=item C< color_severity_lowest() >

Returns the color to be used for coloring lowest severity violations.

=item C< program_extensions() >

Returns a reference to the array of file name extensions to be interpreted as
representing Perl programs.

=back


=head1 SEE ALSO

L<Perl::Critic::Config|Perl::Critic::Config>,
L<Perl::Critic::UserProfile|Perl::Critic::UserProfile>


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
