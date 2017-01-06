package Perl::Critic::Policy::Documentation::RequirePackageMatchesPodName;

use 5.006001;

use strict;
use warnings;

use Readonly;
use English qw{ -no_match_vars };
use Perl::Critic::Utils qw{ :severities :classification };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $PKG_RX => qr{ [[:alpha:]](?:[\w:\']*\w)? }xms;
Readonly::Scalar my $DESC =>
    q{Pod NAME on line %d does not match the package declaration};
Readonly::Scalar my $EXPL => q{};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                      }
sub default_severity     { return $SEVERITY_LOWEST        }
sub default_themes       { return qw( core cosmetic )     }
sub applies_to           { return 'PPI::Document'         }

#-----------------------------------------------------------------------------

sub prepare_to_scan_document {
    my ( $self, $document ) = @_;

    # idea: force NAME to match the file name in programs?
    return $document->is_module(); # mismatch is normal in program entry points
}

sub violates {
    my ( $self, $elem, $doc ) = @_;

    # No POD means no violation
    my $pods_ref = $doc->find('PPI::Token::Pod');
    return if !$pods_ref;

    for my $pod (@{$pods_ref}) {
        my $content = $pod->content;

        next if $content !~ m{^=head1 [ \t]+ NAME [ \t]*$ \s*}cgxms;

        my $line_number = $pod->line_number() + (
            substr( $content, 0, $LAST_MATCH_START[0] + 1 ) =~ tr/\n/\n/ );

        my ($pod_pkg) = $content =~ m{\G (\S+) }cgxms;

        if (!$pod_pkg) {
            return $self->violation( sprintf( $DESC, $line_number ),
                q{Empty name declaration}, $pod );
        }

        # idea: worry about POD escapes?
        $pod_pkg =~ s{\A [CL]<(.*)>\z}{$1}gxms; # unwrap
        $pod_pkg =~ s{\'}{::}gxms;              # perl4 -> perl5

        foreach my $stmt ( @{ $doc->find('PPI::Statement::Package') || [] } ) {
            my $pkg = $stmt->namespace();
            $pkg =~ s{\'}{::}gxms;
            return if $pkg eq $pod_pkg;
        }

        return $self->violation( sprintf( $DESC, $line_number ),
            $EXPL, $pod );
    }

    return;  # no NAME section found
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Documentation::RequirePackageMatchesPodName - The C<=head1 NAME> section should match the package.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic> distribution.


=head1 DESCRIPTION


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2008-2011 Chris Dolan

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
