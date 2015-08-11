package Perl::Critic::Policy::Modules::RequireEndWithOne;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL => q{Must end with a recognizable true value};
Readonly::Scalar my $DESC => q{Module does not end with "1;"};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                  }
sub default_severity     { return $SEVERITY_HIGH      }
sub default_themes       { return qw( core bugs pbp certrule ) }
sub applies_to           { return 'PPI::Document'     }

#-----------------------------------------------------------------------------

sub prepare_to_scan_document {
    my ( $self, $document ) = @_;

    return $document->is_module();   # Must be a library or module.
}

sub violates {
    my ( $self, $elem, $doc ) = @_;

    # Last statement should be just "1;"
    my @significant = grep { _is_code($_) } $doc->schildren();
    my $match = $significant[-1];
    return if !$match;
    return if ((ref $match) eq 'PPI::Statement' &&
               $match =~  m{\A 1 \s* ; \z}xms );

    # Must be a violation...
    return $self->violation( $DESC, $EXPL, $match );
}

sub _is_code {
    my $elem = shift;
    return ! (    $elem->isa('PPI::Statement::End')
               || $elem->isa('PPI::Statement::Data'));
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Modules::RequireEndWithOne - End each module with an explicitly C<1;> instead of some funky expression.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

All files included via C<use> or C<require> must end with a true value
to indicate to the caller that the include was successful.  The
standard practice is to conclude your .pm files with C<1;>, but some
authors like to get clever and return some other true value like
C<return "Club sandwich";>.  We cannot tolerate such frivolity!  OK,
we can, but we don't recommend it since it confuses the newcomers.


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 AUTHOR

Chris Dolan C<cdolan@cpan.org>

Some portions cribbed from
L<Perl::Critic::Policy::Modules::RequireExplicitPackage|Perl::Critic::Policy::Modules::RequireExplicitPackage>.


=head1 COPYRIGHT

Copyright (c) 2005-2011 Chris Dolan and Imaginative Software Systems.  All
rights reserved.

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
