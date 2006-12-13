##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
#        ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
##############################################################################

package Perl::Critic::PolicyListing;

use strict;
use warnings;
use Carp qw(carp confess);
use English qw(-no_match_vars);

our $VERSION = 0.22;

#-----------------------------------------------------------------------------

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    my $policies = $args{-policies} || [];
    $self->{_policies} = [ sort _by_type @{ $policies } ];
    return $self;
}

#-----------------------------------------------------------------------------

sub short_listing {
    my $self = shift;
    local $Perl::Critic::Policy::FORMAT =  _short_format();
    return map { "$_" } @{ $self->{_policies} };
}


#-----------------------------------------------------------------------------

sub long_listing {
    my $self = shift;
    local $Perl::Critic::Policy::FORMAT =  _long_format();
    return map { "$_" } @{ $self->{_policies} };
}

#-----------------------------------------------------------------------------

sub _short_format {
    return "%s %p [%t]\n";
}

#-----------------------------------------------------------------------------

sub _long_format {
    return <<'END_OF_FORMAT';
[%P]
set_themes = %t
severity   = %s
%{#%s = \n}O

END_OF_FORMAT

}

#-----------------------------------------------------------------------------

sub _by_type { return ref $a cmp ref $b }

1;

__END__

=pod

=head1 NAME

Perl::Critic::PolicyListing - Display information about Policies

=head1 DESCRIPTION

This is a helper class that formats a set of Policy objects for
pretty-printing.  There are no user-serviceable parts here.

=head1 CONSTRUCTOR

=over 8

=item C<< new( -policies => \@POLICY_OBJECTS ) >>

Returns a reference to a new C<Perl::Critic::PolicyListing> object.

=back

=head1 METHODS

=over 8

=item C<< short_listing() >>

Returns a list of strings, where each string is a one-line summary of the
default severity, policy name, and default themes for each Policy that was
given to the constructor of this PolicyListing.

=item C<< long_listing() >>

Returns a list of strings, where each string is a multi-line summary of the
policy name, default themes, and default severity for each Policy that was
given to the constructor of this PolicyListing.  The format is suitable for
use in the F<.perlcriticrc> file.

=back

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

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
