##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/CodeLayout/ProhibitHardTabs.pm $
#     $Date: 2009-01-02 19:51:58 -0800 (Fri, 02 Jan 2009) $
#   $Author: clonezone $
# $Revision: 2955 $
##############################################################################

package Perl::Critic::Policy::CodeLayout::ProhibitExcessiveLineLength;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :booleans :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.094001';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Lines should not exceed a maxium length};
Readonly::Scalar my $EXPL => [ 18, 19 ];

#-----------------------------------------------------------------------------

Readonly::Scalar my $LINE_END                => qr/\n$/xms;
Readonly::Scalar my $DEFAULT_MAX_LINE_LENGTH => 78;
Readonly::Scalar my $SEVERITY_FOR_CODE       => $SEVERITY_LOWEST;
Readonly::Scalar my $SEVERITY_FOR_POD        => $SEVERITY_LOW;

  #-----------------------------------------------------------------------------

  sub supported_parameters {
    return ( {
            name            => 'max_line_length',
            description     => 'Maximum length of a line of code or POD.',
            default_string  => $DEFAULT_MAX_LINE_LENGTH,
            behavior        => 'integer',
            minimum_integer => 1,
        },
    );
}

sub default_severity { return $SEVERITY_LOW }
sub default_themes   { return qw( core cosmetic pbp ) }

sub applies_to {
    return map { "PPI::Token::$_" } qw( Comment Pod Whitespace );
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    # Only look at elements that have line endings
    return if $elem !~ $LINE_END;

    # Leave room for the new line
    my $max_line_length = $self->{_max_line_length} + 1;

    if (   $elem->isa('PPI::Token::Comment')
        or $elem->isa('PPI::Token::Pod') )
    {

        # For Comments and Pod, PPI returns the statement and does not parse
        # the tokens (include whitespace) within. We check each line of
        # Comment and Pod.
        for my $line ( split /\n/xms, $elem ) {
            return $self->violation( $DESC, $EXPL, $elem, $SEVERITY_FOR_CODE )
              if length($line) >= $max_line_length;
        }

    } else {

        # For Code, PPI parses the tokens and will give us the new line as
        # ::Whitespace. We can just check the location.
        return $self->violation( $DESC, $EXPL, $elem, $SEVERITY_FOR_POD ) 
          if $elem->location->[2] > $max_line_length;
    }

    # No violations
    return;
}

1;

__END__

#-----------------------------------------------------------------------------

=head1 NAME

Perl::Critic::Policy::CodeLayout::ProhibitExcessiveLineLength - Lines should be limited to 78 columns


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

While most people code on monitors that can support much more than
a 78 character line, line length should be limited to support 
printed documents, legacy VGA displays, email, etc. 

This Policy catches any lines that are greater than C<max_line_length>
(which defaults to 78) in code or pod.  The contents of the C<__DATA__>
section are not examined.


=head1 CONFIGURATION

It is recommended that lines should be limited to 78 columns, but most
most monitors, editors, etc. can support 80 columns. If you would like
to change the maxium length of a line permitted by this policy you can
add this to your F<.perlcriticrc> file:

    [CodeLayout::ProhibitExcessiveLineLength]
    max_line_length = 80



=head1 AUTHOR

Mark Grimes <mgrimes@cpan.org>


=head1 LICENSE and COPYRIGHT

Copyright (c) 2009 Mark Grimes.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
