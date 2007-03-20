##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::Miscellanea::RequireRcsKeywords;

use strict;
use warnings;
use Perl::Critic::Utils qw{ :characters :severities :data_conversion };
use List::MoreUtils qw(none);
use base 'Perl::Critic::Policy';

our $VERSION = 1.05;

#-----------------------------------------------------------------------------

my $expl = [ 441 ];

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

sub new {
    my ( $class, %config ) = @_;
    my $self = bless {}, $class;

    $self->_finish_standard_initialization(\%config);

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
        ## no critic ProhibitEmptyQuotes
        $self->{_keyword_sets} = [ [ @keywords ] ];
    }

    return $self;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;
    my @viols = ();

    my $nodes = $doc->find( \&_wanted );
    for my $keywordset_ref ( @{ $self->{_keyword_sets} } ) {
        if ( not $nodes ) {
            my $desc = 'RCS keywords '
                . join( ', ', map {"\$$_\$"} @{$keywordset_ref} )
                . ' not found';
            push @viols, $self->violation( $desc, $expl, $doc );
        }
        else {
            my @missing_keywords = grep {
                my $keyword_rx = qr/\$$_.*\$/;
                !!none {
                    /$keyword_rx/    ## no critic
                    }
                    @{$nodes}
            } @{$keywordset_ref};

            if (@missing_keywords) {

                # Provisionally flag a violation. See below.
                my $desc = 'RCS keywords '
                    . join( ', ', map {"\$$_\$"} @missing_keywords )
                    . ' not found';
                push @viols, $self->violation( $desc, $expl, $doc );
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

sub _wanted {
    my ( undef, $elem ) = @_;
    return  $elem->isa('PPI::Token::Pod')
        || $elem->isa('PPI::Token::Comment')
        || $elem->isa('PPI::Token::Quote::Single')
        || $elem->isa('PPI::Token::Quote::Literal');
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords RCS

=head1 NAME

Perl::Critic::Policy::Miscellanea::RequireRcsKeywords

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

By default, this policy only requires the C<Revision>, C<Source>, and C<Date>
keywords.  To specify alternate keywords, specify a value for C<keywords> of a
whitespace delimited series of keywords (without the dollar-signs).  This would
look something like the following in a F<.perlcriticrc> file:

  [Miscellanea::RequireRcsKeywords]
  keywords = Revision Source Date Author Id

See the documentation on RCS for a list of supported keywords.  Many
source control systems are descended from RCS, so the keywords
supported by CVS and Subversion are probably the same.

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
