##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/branches/Perl-Critic-With-Param-Validation/lib/Perl/Critic/PolicyListing.pm $
#     $Date: 2006-12-13 21:35:21 -0800 (Wed, 13 Dec 2006) $
#   $Author: thaljef $
# $Revision: 1089 $
##############################################################################

package Perl::Critic::ProfilePrototype;

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::Critic::Config qw{};
use Perl::Critic::Policy qw{};
use Perl::Critic::Utils qw{ :characters };
use overload ( q{""} => 'to_string' );

our $VERSION = '1.088';

#-----------------------------------------------------------------------------

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;

    my $policies = $args{-policies} || [];
    $self->{_policies} = [ sort _by_type @{ $policies } ];

    my $comment_out_parameters = $args{'-comment-out-parameters'};
    if (not defined $comment_out_parameters) {
        $comment_out_parameters = 1;
    }
    $self->{_comment_out_parameters} = $comment_out_parameters;

    my $configuration = $args{'-config'};
    if (not $configuration) {
        $configuration = Perl::Critic::Config->new(-profile => $EMPTY);
    }
    $self->{_configuration} = $configuration;


    return $self;
}

#-----------------------------------------------------------------------------

sub _get_policies {
    my ($self) = @_;

    return $self->{_policies};
}

sub _comment_out_parameters {
    my ($self) = @_;

    return $self->{_comment_out_parameters};
}

sub _configuration {
    my ($self) = @_;

    return $self->{_configuration};
}

#-----------------------------------------------------------------------------

sub _line_prefix {
    my ($self) = @_;

    return $self->_comment_out_parameters() ? q{# } : $EMPTY;
}

#-----------------------------------------------------------------------------

sub to_string {
    my ($self) = @_;

    my $prefix = $self->_line_prefix();
    my $configuration = $self->_configuration();

    my $prototype = "# Globals\n";

    $prototype .= $prefix;
    $prototype .= q{severity = };
    $prototype .= $configuration->severity();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{force = };
    $prototype .= $configuration->force();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{only = };
    $prototype .= $configuration->only();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{profile-strictness = };
    $prototype .= $configuration->profile_strictness();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{color = };
    $prototype .= $configuration->color();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{top = };
    $prototype .= $configuration->top();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{verbose = };
    $prototype .= $configuration->verbose();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{include = };
    $prototype .= join $SPACE, $configuration->include();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{exclude = };
    $prototype .= join $SPACE, $configuration->exclude();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{single-policy = };
    $prototype .= join $SPACE, $configuration->single_policy();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{theme = };
    $prototype .= $configuration->theme()->rule();
    $prototype .= "\n";

    Perl::Critic::Policy::set_format( $self->_proto_format() );

    return $prototype . "\n" . join q{}, map { "$_" } @{ $self->_get_policies() };
}

#-----------------------------------------------------------------------------

# About "%{\\n%\\x7b# \\x7df\n${prefix}%n = %D\\n}O" below:
#
# The %0 format for a policy specifies how to format parameters.
# For a parameter %f specifies the full description.
#
# The problem is that both of these need to take options, but String::Format
# doesn't allow nesting of {}.  So, to get the option to the %f, the braces
# are hex encoded.  I.e., assuming that comment_out_parameters is in effect,
# the parameter sees:
#
#    \n%{# }f\n# %n = %D\n

sub _proto_format {
    my ($self) = @_;

    my $prefix = $self->_line_prefix();

    return <<"END_OF_FORMAT";
# %a
[%p]
${prefix}set_themes                         = %t
${prefix}add_themes                         =
${prefix}severity                           = %s
${prefix}maximum_violations_per_document    = %v
%{\\n%\\x7b# \\x7df\\n${prefix}%n = %D\\n}O%{${prefix}Cannot programmatically discover what parameters this policy takes.\\n}U

END_OF_FORMAT

}

#-----------------------------------------------------------------------------

sub _by_type { return ref $a cmp ref $b }

1;

__END__

=pod

=head1 NAME

Perl::Critic::ProfilePrototype - Generate an initial Perl::Critic profile.

=head1 DESCRIPTION

This is a helper class that generates a prototype of a L<Perl::Critic> profile
(e.g. a F<.perlcriticrc> file. There are no user-serviceable parts here.

=head1 CONSTRUCTOR

=over 8

=item C<< new( -policies => \@POLICY_OBJECTS ) >>

Returns a reference to a new C<Perl::Critic::ProfilePrototype> object.

=back

=head1 METHODS

=over 8

=item to_string()

Returns a string representation of this C<ProfilePrototype>.  See
L<"OVERLOADS"> for more information.

=back

=head1 OVERLOADS

When a L<Perl::Critic::ProfilePrototype> is evaluated in string context, it
produces a multi-line summary of the policy name, default themes, and default
severity for each L<Perl::Critic::Policy> object that was given to the
constructor of this C<ProfilePrototype>.  If the Policy supports an additional
parameters, they will also be listed (but commented-out).  The format is
suitable for use as a F<.perlcriticrc> file.

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
