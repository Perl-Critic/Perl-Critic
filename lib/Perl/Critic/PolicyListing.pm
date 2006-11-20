###############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/Perl-Critic/bin/$
#     $Date$
#   $Author$
# $Revision$
#        ex: set ts=8 sts=4 sw=4 expandtab :
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

END_OF_FORMAT

}

#-----------------------------------------------------------------------------

sub _by_type { return ref $a cmp ref $b }

1;

__END__

=pod

=head1 NAME

Perl::Critic::PolicyListing - Display information about Policies

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=over 8

=item C<< new( -policies => \@POLICY_OBJECTS ) >>

=back

=head1 METHODS

=over 8

=item C<< short_listing() >>

=item C<< long_listing() >>

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
# ex: set ts=8 sts=4 sw=4 expandtab :
