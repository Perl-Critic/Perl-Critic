package Perl::Critic::Exception::Configuration::Option::Policy;

use 5.006001;
use strict;
use warnings;

use Perl::Critic::Utils qw{ &policy_short_name };

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

use Exception::Class (
    'Perl::Critic::Exception::Configuration::Option::Policy' => {
        isa         => 'Perl::Critic::Exception::Configuration::Option',
        description => 'A problem with the configuration of a policy.',
        fields      => [ qw{ policy } ],
    },
);

#-----------------------------------------------------------------------------

sub new {
    my ($class, %options) = @_;

    my $policy = $options{policy};
    if ($policy) {
        $options{policy} = policy_short_name($policy);
    }

    return $class->SUPER::new(%options);
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Critic::Exception::Configuration::Option::Policy - A problem with configuration of a policy.

=head1 DESCRIPTION

A representation of a problem found with the configuration of a
L<Perl::Critic::Policy|Perl::Critic::Policy>, whether from a
F<.perlcriticrc>, another profile file, or command line.

This is an abstract class.  It should never be instantiated.


=head1 INTERFACE SUPPORT

This is considered to be a public class.  Any changes to its interface
will go through a deprecation cycle.


=head1 METHODS

=over

=item C<policy()>

The short name of the policy that had configuration problems.


=back


=head1 AUTHOR

Elliot Shank <perl@galumph.com>

=head1 COPYRIGHT

Copyright (c) 2007-2011 Elliot Shank.

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
