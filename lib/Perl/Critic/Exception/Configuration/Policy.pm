##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Exception::Configuration::Policy;

use strict;
use warnings;

use Perl::Critic::Utils qw{ &policy_short_name };

our $VERSION = 1.053;

#-----------------------------------------------------------------------------

use Exception::Class (
    'Perl::Critic::Exception::Configuration::Policy' => {
        isa         => 'Perl::Critic::Exception::Configuration',
        description => 'A problem with the configuration of a policy.',
        fields      => [ qw{ policy } ],
    },
);

#-----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my %options = @_;

    my $policy = $options{policy};
    if ($policy) {
        $options{policy} = policy_short_name($policy);
    }

    return $class->SUPER::new(%options);
}

#-----------------------------------------------------------------------------

sub full_message {
    my ( $self ) = @_;

    my $source = $self->source();
    if ($source) {
        $source = qq{ found in "$source"};
    }
    else {
        $source = q{};
    }

    my $policy = $self->policy();
    my $option_name = $self->option_name();
    my $option_value = $self->option_value();

    return
            qq{The value for the $policy "$option_name" option }
        .   qq{("$option_value")$source }
        .   $self->message_suffix();
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Critic::Exception::Configuration::Policy - A problem with configuration of a policy

=head1 DESCRIPTION

A representation of a problem found with the configuration of a
L<Perl::Critic::Policy>, whether from a F<.perlcriticrc>, another
profile file, or command line.


=head1 CLASS METHODS

=over

=item C<< throw( policy => $policy, option_name => $option_name, option_value => $option_value, source => $source, message_suffix => $message_suffix ) >>

See L<Exception::Class/"throw">.


=item C<< new( policy => $policy, option_name => $option_name, option_value => $option_value, source => $source, message_suffix => $message_suffix ) >>

See L<Exception::Class/"new">.


=back


=head1 METHODS

=over

=item C<policy()>

The short name of the policy that had configuration problems.


=item C<full_message()>

Provide a standard message for policy configuration problems.  See
L<Exception::Class/"full_message">.


=back


=head1 AUTHOR

Elliot Shank <perl@galumph.com>

=head1 COPYRIGHT

Copyright (c) 2007 Elliot Shank.  All rights reserved.

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
