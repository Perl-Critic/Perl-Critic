#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy;

use strict;
use warnings;
use Carp qw(confess);
use Perl::Critic::Utils;
use Perl::Critic::Violation;

our $VERSION = 0.20;

#----------------------------------------------------------------------------

sub new {
    my $class = shift;
    return bless {}, $class;
}

#----------------------------------------------------------------------------

sub applies_to {
    return qw(PPI::Element);
}

#----------------------------------------------------------------------------

sub set_severity {
    my ($self, $severity) = @_;
    $self->{_severity} = $severity;
    return $self;
}

#----------------------------------------------------------------------------

sub get_severity {
    my ($self) = @_;
    return $self->{_severity} || $self->default_severity();
}

#----------------------------------------------------------------------------

sub default_severity {
    return $SEVERITY_LOWEST;
}

#----------------------------------------------------------------------------

sub set_themes {
    my ($self, @themes) = @_;
    $self->{_themes} = [ sort @themes ];
    return $self;
}

#----------------------------------------------------------------------------

sub get_themes {
    my ($self) = @_;
    return @{ $self->{_themes} } if defined $self->{_themes};
    return $self->default_themes();
}

#----------------------------------------------------------------------------

sub add_themes {
    my ($self, @additional_themes) = @_;
    #By hashifying the themes, we squish duplicates
    my %merged = hashify( $self->get_themes(), @additional_themes);
    $self->{_themes} = [ sort keys %merged];
    return $self;
}

#----------------------------------------------------------------------------

sub default_themes {
    return ();
}

#----------------------------------------------------------------------------

sub violates {
    return confess q{Can't call abstract method};
}

#----------------------------------------------------------------------------

sub violation {
    my ( $self, $desc, $expl, $elem ) = @_;
    # Use goto instead of an explicit call because P::C::V::new() uses caller()
    my $sev = $self->get_severity();
    @_ = ('Perl::Critic::Violation', $desc, $expl, $elem, $sev );
    goto &Perl::Critic::Violation::new;
}


1;

__END__

#----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy - Base class for all Policy modules

=head1 DESCRIPTION

Perl::Critic::Policy is the abstract base class for all Policy
objects.  If you're developing your own Policies, your job is to
implement and override its methods in a subclass.  To work with the
L<Perl::Critic> engine, your implementation must behave as described
below.  For a detailed explanation on how to make new Policy modules,
please see the L<Perl::Critic::DEVELOPER> document included in this
distribution.

=head1 METHODS

=over 8

=item C<new(key1 => value1, key2 => value2 ... )>

Returns a reference to a new subclass of Perl::Critic::Policy. If
your Policy requires any special arguments, they should be passed
in here as key-value pairs.  Users of L<perlcritic> can specify
these in their config file.  Unless you override the C<new> method,
the default method simply returns a reference to an empty hash that
has been blessed into your subclass.

=item C<violates( $element, $document )>

Given a L<PPI::Element> and a L<PPI::Document>, returns one or more
L<Perl::Critic::Violation> objects if the C<$element> violates this
Policy.  If there are no violations, then it returns an empty list.
If the Policy encounters an exception, then it should C<croak> with an
error message and let the caller decide how to handle it.

C<violates()> is an abstract method and it will abort if you attempt
to invoke it directly.  It is the heart of all Policy modules, and
your subclass B<must> override this method.

=item C<violation( $description, $explanation, $element )>

Returns a reference to a new C<Perl::Critic::Violation> object. The
arguments are a description of the violation (as string), an
explanation for the policy (as string) or a series of page numbers in
PBP (as an ARRAY ref), a reference to the L<PPI> element that caused
the violation.

These are the same as the constructor to L<Perl::Critic::Violation>,
but without the severity.  The Policy itself knows the severity.

=item C<applies_to()>

Returns a list of the names of PPI classes that this Policy cares
about.  By default, the result is C<PPI::Element>.  Overriding this
method in Policy subclasses should lead to significant performance
increases.

=item C<default_severity()>

Returns the default severity for violating this Policy.  See the
C<$SEVERITY> constants in L<Perl::Critic::Utils> for an enumeration of
possible severity values.  By default, this method returns
C<$SEVERITY_LOWEST>.  Authors of Perl::Critic::Policy subclasses
should override this method to return a value that they feel is
appropriate for their Policy.  In general, Polices that are widely
accepted or tend to prevent bugs should have a higher severity than
those that are more subjective or cosmetic in nature.

=item C<get_severity()>

Returns the severity of violating this Policy.  If the severity has
not been explicitly defined by calling C<set_severity>, then the
C<default_severity> is returned.  See the C<$SEVERITY> constants in
L<Perl::Critic::Utils> for an enumeration of possible severity values.

=item C<set_severity( $N )>

Sets the severity for violating this Policy.  Clients of
Perl::Critic::Policy objects can call this method to assign a
different severity to the Policy if they don't agree with the
C<default_severity>.  See the C<$SEVERITY> constants in
L<Perl::Critic::Utils> for an enumeration of possible values.

=item C<default_themes()>

Returns a sorted list of the default themes associated with this
Policy.  The default method returns an empty list.  Policy authors
should override this method to return a list of themes that are
appropriate for their policy.

=item C<get_themes()>

Returns a sorted list of the themes associated with this Policy.  If
you haven't added themes or set the themes explicilty, this method
just returns the default themes.

=item C<set_themes( @THEME_LIST )>

Sets the themes associated with this Policy.  Any existing themes are
overwritten.  Duplicate themes will be removed.

=item C<add_themes( @THEME_LIST )>

Appends additional themes to this Policy.  Any existing themes are
preserved.  Duplicate themes will be removed.

=back

=head1 DOCUMENTATION

When your Policy module first C<use>s L<Perl::Critic::Violation>, it
will try and extract the DESCRIPTION section of your Policy module's
POD.  This information is displayed by Perl::Critic if the verbosity
level is set accordingly.  Therefore, please include a DESCRIPTION
section in the POD for any Policy modules that you author.  Thanks.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
