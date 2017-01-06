package Perl::Critic::ThemeListing;

use 5.006001;
use strict;
use warnings;

use English qw<-no_match_vars>;

use Perl::Critic::Utils qw< hashify >;

use overload ( q<""> => 'to_string' );

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    $self->{_policies} = $args{-policies} || [];

    return $self;
}

#-----------------------------------------------------------------------------

sub to_string {
    my ($self) = @_;

    my %themes;
    foreach my $policy ( @{ $self->{_policies} } ) {
        my @themes = $policy->get_themes();
        @themes{ @themes } = @themes;
    }

    return join ("\n", sort keys %themes) . "\n";
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Perl::Critic::ThemeListing - List the themes of the installed Policies.


=head1 DESCRIPTION

This is a helper class that gathers the themes of the installed
Policies.  There are no user-serviceable parts here.


=head1 INTERFACE SUPPORT

This is considered to be a non-public class.  Its interface is subject
to change without notice.


=head1 CONSTRUCTOR

=over

=item C<< new( -policies => \@POLICY_OBJECTS ) >>

Returns a reference to a new C<Perl::Critic::ThemeListing> object.


=back


=head1 METHODS

=over


=item to_string()

Returns a string representation of this C<ThemeListing>.  See
L<"OVERLOADS"> for more information.


=back


=head1 OVERLOADS


When a L<Perl::Critic::ThemeListing|Perl::Critic::ThemeListing> is
evaluated in string context, it produces a one-line summary of the
default severity, policy name, and default themes for each
L<Perl::Critic::Policy|Perl::Critic::Policy> object that was given to
the constructor of this C<ThemeListing>.


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
