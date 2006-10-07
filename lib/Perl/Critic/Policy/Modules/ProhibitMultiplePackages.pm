#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::Modules::ProhibitMultiplePackages;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.20;

#----------------------------------------------------------------------------

my $desc   = q{Multiple "package" declarations};
my $expl   = q{Limit to one per file};

#----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGH  }
sub default_themes    { return qw( risky )     }
sub applies_to       { return 'PPI::Document' }

#----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;
    my $nodes_ref = $doc->find('PPI::Statement::Package');
    return if !$nodes_ref;
    my @matches = @{$nodes_ref} > 1 ? @{$nodes_ref}[ 1 .. $#{$nodes_ref} ] :();

    return map {$self->violation($desc, $expl, $_)} @matches;
}

1;

__END__

#----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Modules::ProhibitMultiplePackages

=head1 DESCRIPTION

Conway doesn't specifically mention this, but I find it annoying when
there are multiple packages in the same file.  When searching for
methods or keywords in your editor, it makes it hard to find the right
chunk of code, especially if each package is a subclass of the same
base.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
