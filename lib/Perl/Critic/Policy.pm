package Perl::Critic::Policy;

use strict;
use warnings;

our $VERSION = '0.13';
$VERSION = eval $VERSION;    ## no critic

#----------------------------------------------------------------------------

sub new { return bless {}, shift }
sub violates { _abstract_method() }

sub _abstract_method {
    my $method_name = ( caller 1 )[3];
    my ( $file, $line ) = ( caller 2 )[ 1, 2 ];
    die "Can't call abstract method '$method_name' at $file line $line.\n";
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy - Base class for all Policy modules

=head1 DESCRIPTION

Perl::Critic::Policy is the abstract base class for all Policy
objects.  Your job is to implement and override its methods in a
subclass.  To work with the L<Perl::Critic> engine, your
implementation must behave as described below.

=head1 IMPORTANT CHANGES

As new Policy modules were added to Perl::Critic, the overall
performance started to deteriorate rapidily.  Since each module would
traverse the document (several times for some modules), a lot of time
was spent iterating over the same document nodes.  So starting in
version 0.11, I have switched to a stream-based approach where the
document is traversed once and every Policy module is tested at each
node.  The result is roughly a 300% improvement, and the Perl::Critic
engine will scale better as more Policies are added.

Unfortunately, Policy modules prior to version 0.11 won't be
compatible.  Converting them to the stream-based model is fairly easy,
and it actually results in somewhat cleaner code.  Look at the
ControlStrucutres::* modules for some good examples.

=head1 METHODS

=over 8

=item new(key1 => value1, key2 => value2...)

Returns a reference to a new subclass of Perl::Critic::Policy. If
your Policy requires any special arguments, they should be passed
in here as key-value paris.  Users of L<perlcritic> can specify
these in their config file.  Unless you override the C<new> method,
the default method simply returns a reference to an empty hash that
has been blessed into your subclass.

=item violates( $element, $document )

Given a L<PPI::Element> and a L<PPI::Document>, returns one or more
L<Perl::Critic::Violation> object if the C<$element> violates this
policy.  If there are no violations, then it returns an empty list.

L<Perl::Critic> will call C<violates()> on every C<$element> in the
C<$document>.  Some Policies may need to look at the entire
C<$document> and probably only need to be executed once.  In that
case, you should write C<violates()> so that it short-circuts if the
Policy has already been executed.  See
L<Perl::Critic::Policy::Modules::ProhibitUnpackagedCode> for an
example of such a Policy.

C<violates()> is an abstract method and it will croak if you attempt
to invoke it directly.  Your subclass B<must> override this method.

=back

=head1 DOCUMENTATION

When your Policy module first C<use>s L<Perl::Critic::Violation>, it
will try and extrace the DESCRIPTION section of your Policy module's
POD.  This information is displayed by Perl::Critic if the verbosity
level is set accordingly.  Therefore, please include a DESCRIPTION
section in the POD for any Policy modules that you author.  Thanks.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
