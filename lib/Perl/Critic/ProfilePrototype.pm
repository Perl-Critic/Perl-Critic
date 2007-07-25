##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/branches/Perl-Critic-With-Param-Validation/lib/Perl/Critic/PolicyListing.pm $
#     $Date: 2006-12-13 21:35:21 -0800 (Wed, 13 Dec 2006) $
#   $Author: thaljef $
# $Revision: 1089 $
#        ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
##############################################################################

package Perl::Critic::ProfilePrototype;

use strict;
use warnings;
use Carp qw(carp confess);
use English qw(-no_match_vars);
use Perl::Critic::Policy qw();
use overload ( q{""} => 'to_string' );

our $VERSION = 1.061;

#-----------------------------------------------------------------------------

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    my $policies = $args{-policies} || [];
    $self->{_policies} = [ sort _by_type @{ $policies } ];
    return $self;
}

#-----------------------------------------------------------------------------

sub to_string {
    my $self = shift;
    my $format = _proto_format();
    Perl::Critic::Policy::set_format( $format );
    return join q{}, map { "$_" } @{ $self->{_policies} };
}

#-----------------------------------------------------------------------------

sub _proto_format {
    return <<'END_OF_FORMAT';
[%p]
# set_themes = %t
# severity   = %s
%{# %s = \n}O

END_OF_FORMAT

}

#-----------------------------------------------------------------------------

sub _by_type { return ref $a cmp ref $b }

1;

__END__

=pod

=head1 NAME

Perl::Critic::ProfilePrototype - Generate a Perl::Critic profile

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

Copyright (c) 2005-2007 Jeffrey Ryan Thalhammer.  All rights reserved.

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
