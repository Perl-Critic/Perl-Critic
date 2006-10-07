#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::Modules::RequireEndWithOne;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.20;

#----------------------------------------------------------------------------

my $expl = q{Must end with a recognizable true value};
my $desc = q{Module does not end with "1;"};

#----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGH  }
sub default_themes    { return qw( risky pbp ) }
sub applies_to       { return 'PPI::Document' }

#----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;
    return if is_script($doc);   #Must be a library or module.

    # Last statement should be just "1;"
    my @significant = grep { _is_code($_) } $doc->schildren();
    my $match = $significant[-1];
    return if !$match;
    return if ((ref $match) eq 'PPI::Statement' &&
               $match =~  m{\A 1 \s* ; \z}mx );

    # Must be a violation...
    return $self->violation( $desc, $expl, $match );
}

sub _is_code {
    my $elem = shift;
    return ! (    $elem->isa('PPI::Statement::End')
               || $elem->isa('PPI::Statement::Data'));
}

1;

__END__

#----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Modules::RequireEndWithOne

=head1 DESCRIPTION

All files included via C<use> or C<require> must end with a true value
to indicate to the caller that the include was successful.  The
standard practice is to conclude your .pm files with C<1;>, but some
authors like to get clever and return some other true value like
C<return "Club sandwich";>.  We cannot tolerate such frivolity!  OK, we
can, but we don't recommend it since it confuses the newcomers.

=head1 AUTHOR

Chris Dolan C<cdolan@cpan.org>

Some portions cribbed from
L<Perl::Critic::Policy::Modules::RequireExplicitPackage>.

=head1 COPYRIGHT

Copyright (c) 2005-2006 Chris Dolan and Jeffrey Ryan Thalhammer.  All
rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
