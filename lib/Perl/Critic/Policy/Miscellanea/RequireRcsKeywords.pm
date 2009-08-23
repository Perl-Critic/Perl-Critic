##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::Miscellanea::RequireRcsKeywords;

use 5.006001;
use strict;
use warnings;
use Readonly;

use List::MoreUtils qw(none);

use Perl::Critic::Utils qw{
    :booleans :characters :severities :data_conversion
};

use base 'Perl::Critic::Policy';

our $VERSION = '1.104';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL => [ 441 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'keywords',
            description     => 'The keywords to require in all files.',
            default_string  => $EMPTY,
            behavior        => 'string list',
        },
    );
}

sub default_severity  { return $SEVERITY_LOW         }
sub default_themes    { return qw(core pbp cosmetic) }
sub applies_to        { return 'PPI::Document'       }

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    my ($self, $config) = @_;

    # Any of these lists
    $self->{_keyword_sets} = [

        # Minimal svk/svn
        [qw(Id)],

        # Expansive svk/svn
        [qw(Revision HeadURL Date)],

        # cvs?
        [qw(Revision Source Date)],
    ];

    # Set configuration, if defined.
    my @keywords = keys %{ $self->{_keywords} };
    if ( @keywords ) {
        $self->{_keyword_sets} = [ [ @keywords ] ];
    }

    return $TRUE;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;
    my @viols = ();

    my $nodes = $self->_find_wanted_nodes($doc);
    for my $keywordset_ref ( @{ $self->{_keyword_sets} } ) {
        if ( not $nodes ) {
            my $desc = 'RCS keywords '
                . join( ', ', map {"\$$_\$"} @{$keywordset_ref} )
                . ' not found';
            push @viols, $self->violation( $desc, $EXPL, $doc );
        }
        else {
            my @missing_keywords =
                grep
                    {
                        my $keyword_rx = qr< \$ $_ .* \$ >xms;
                        ! ! none { m/$keyword_rx/xms } @{$nodes}
                    }
                    @{$keywordset_ref};

            if (@missing_keywords) {
                # Provisionally flag a violation. See below.
                my $desc =
                    'RCS keywords '
                        . join( ', ', map {"\$$_\$"} @missing_keywords )
                        . ' not found';
                push @viols, $self->violation( $desc, $EXPL, $doc );
            }
            else {
                # Hey! I'm ignoring @viols for other keyword sets
                # because this one is complete.
                return;
            }
        }
    }

    return @viols;
}

#-----------------------------------------------------------------------------

sub _find_wanted_nodes {
    my ( $self, $doc ) = @_;
    my @wanted_types = qw(Pod Comment Quote::Single Quote::Literal End);
    my @found =  map { @{ $doc->find("PPI::Token::$_") || [] } } @wanted_types;
    push @found, grep { $_->content() =~ m/ \A qw\$ [^\$]* \$ \z /smx } @{
        $doc->find('PPI::Token::QuoteLike::Words') || [] };
    return @found ? \@found : $EMPTY;  # Behave like PPI::Node::find()
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords RCS

=head1 NAME

Perl::Critic::Policy::Miscellanea::RequireRcsKeywords - Put source-control keywords in every file.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Every code file, no matter how small, should be kept in a
source-control repository.  Adding the magical RCS keywords to your
file helps the reader know where the file comes from, in case he or
she needs to modify it.  This Policy scans your file for comments that
look like this:

    # $Revision$
    # $Source: /myproject/lib/foo.pm $

A common practice is to use the C<Revision> keyword to automatically
define the C<$VERSION> variable like this:

    our ($VERSION) = '$Revision$' =~ m{ \$Revision: \s+ (\S+) }x;


=head1 CONFIGURATION

By default, this policy only requires the C<Revision>, C<Source>, and
C<Date> keywords.  To specify alternate keywords, specify a value for
C<keywords> of a whitespace delimited series of keywords (without the
dollar-signs).  This would look something like the following in a
F<.perlcriticrc> file:

    [Miscellanea::RequireRcsKeywords]
    keywords = Revision Source Date Author Id

See the documentation on RCS for a list of supported keywords.  Many
source control systems are descended from RCS, so the keywords
supported by CVS and Subversion are probably the same.


=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2005-2009 Jeffrey Ryan Thalhammer.  All rights reserved.

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
