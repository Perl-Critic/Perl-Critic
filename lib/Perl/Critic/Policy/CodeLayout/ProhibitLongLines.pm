##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::CodeLayout::ProhibitLongLines;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :booleans :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.094001';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC_HARD => q{Line exceeds the hard maximum length};
Readonly::Scalar my $DESC_SOFT => q{Too many lines exceed the soft max length};
Readonly::Scalar my $EXPL      => [ 18, 19 ];

#-----------------------------------------------------------------------------

Readonly::Scalar my $LINE_END    => qr/\n$/xmso;
Readonly::Scalar my $ONE_HUNDRED => 100;

Readonly::Scalar my $DEFAULT_CODE_MAX              => 78;
Readonly::Scalar my $DETAULT_CODE_HARD_MAX         => 120;
Readonly::Scalar my $DEFAULT_PCT_LONG_CODE_ALLOWED => 3;

Readonly::Scalar my $DEFAULT_POD_MAX              => 70;
Readonly::Scalar my $DETAULT_POD_HARD_MAX         => 105;
Readonly::Scalar my $DEFAULT_PCT_LONG_POD_ALLOWED => 3;

Readonly::Scalar my $SEVERITY_FOR_CODE => $SEVERITY_LOWEST;
Readonly::Scalar my $SEVERITY_FOR_POD  => $SEVERITY_LOW;

#-----------------------------------------------------------------------------

sub supported_parameters {
    return ( {
            name            => 'max_code_line_length',
            description     => 'Maximum length of a line of code.',
            default_string  => $DEFAULT_CODE_MAX,
            behavior        => 'integer',
            minimum_integer => 1,
        },
        {
            name            => 'hard_max_code_line_length',
            description     => 'Absolute maximum permitted line of code.',
            default_string  => $DETAULT_CODE_HARD_MAX,
            behavior        => 'integer',
            minimum_integer => 1,
        },
        {
            name        => 'percent_long_code_lines_allowed',
            description => 'Percentage of long lines of code allowed (0-99).',
            default_string  => $DEFAULT_PCT_LONG_CODE_ALLOWED,
            behavior        => 'integer',
            minimum_integer => 0,
        },
        {
            name            => 'max_pod_line_length',
            description     => 'Maximum length of a line of pod.',
            default_string  => $DEFAULT_POD_MAX,
            behavior        => 'integer',
            minimum_integer => 1,
        },
        {
            name            => 'hard_max_pod_line_length',
            description     => 'Absolute maximum permitted line of pod.',
            default_string  => $DETAULT_POD_HARD_MAX,
            behavior        => 'integer',
            minimum_integer => 1,
        },
        {
            name           => 'percent_long_pod_lines_allowed',
            description    => 'Percentage of long lines of pod allowed (0-99).',
            default_string => $DEFAULT_PCT_LONG_POD_ALLOWED,
            behavior       => 'integer',
            minimum_integer => 0,
        },
    );
}

sub default_severity { return $SEVERITY_LOW }
sub default_themes   { return qw( core cosmetic pbp ) }
sub applies_to       { return 'PPI::Document' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $doc ) = @_;

    return ( $self->_pod_violates($doc), $self->_code_violates($doc) );
}

sub _pod_violates {
    my ( $self, $doc ) = @_;

    # Leave room for the new line
    my $soft_max_line_length = $self->{_max_pod_line_length} + 1;
    my $hard_max_line_length = $self->{_hard_max_pod_line_length} + 1;
    my $pct_long_lines_allowed =
      $self->{_percent_long_pod_lines_allowed} / $ONE_HUNDRED;

    my @hard_violations = ();
    my @soft_violations = ();
    my $lines           = 0;

    if ( my $pod = $doc->find('PPI::Token::Pod') ) {

        for my $elem ( @{$pod} ) {

            # For Pod PPI returns all the lines and does not parse the
            # tokens (include whitespace) within. We check each line of Pod.

            for my $line ( split /\n/xms, $elem ) {
                $lines++;

                if ( length($line) >= $hard_max_line_length ) {

                    # TODO: this flags all the pod (possibly multiple times
                    # not the line of pod

                    push @hard_violations,
                      $self->violation( $DESC_HARD, $EXPL, $elem,
                        $SEVERITY_FOR_CODE );

                } elsif ( length($line) >= $soft_max_line_length ) {
                    push @soft_violations,
                      $self->violation( $DESC_SOFT, $EXPL, $elem,
                        $SEVERITY_FOR_CODE );
                }
            }
        }

        return @hard_violations if @hard_violations;
        return @soft_violations
          if scalar @soft_violations / $lines > $pct_long_lines_allowed;

    }

    # No violations
    return;
}

sub _code_violates {
    my ( $self, $doc ) = @_;

    # Leave room for the new line
    my $soft_max_line_length = $self->{_max_code_line_length} + 1;
    my $hard_max_line_length = $self->{_hard_max_code_line_length} + 1;
    my $pct_long_lines_allowed =
      $self->{_percent_long_code_lines_allowed} / $ONE_HUNDRED;

    my @hard_violations = ();
    my @soft_violations = ();
    my $lines           = 0;

    if ( my $comments = $doc->find('PPI::Token::Comment') ) {
        $lines += @{$comments};

        for my $elem ( @{$comments} ) {

            # For Comments PPI returns the text but does not parse the
            # tokens (include whitespace) within. We check each comment.
            my $line = $elem->content;
            chomp $line;

            # Skip version control keywords
            next if $line =~ /^\s*\#\s*\$\w+:.*\$$/xmso;

            if ( length($line) >= $hard_max_line_length ) {
                push @hard_violations,
                  $self->violation( $DESC_HARD, $EXPL, $elem,
                    $SEVERITY_FOR_CODE );
            } elsif ( length($line) >= $soft_max_line_length ) {
                push @soft_violations,
                  $self->violation( $DESC_SOFT, $EXPL, $elem,
                    $SEVERITY_FOR_CODE );
            }
        }
    }

    if ( my $code = $doc->find( \&_is_eol_for_code ) ) {
        $lines += @{$code};

        for my $elem ( @{$code} ) {

            # For Code, PPI parses the tokens and will give us the new line as
            # ::Whitespace. We can just check the location.
            if ( $elem->location->[2] > $hard_max_line_length ) {
                push @hard_violations,
                  $self->violation( $DESC_HARD, $EXPL, $elem,
                    $SEVERITY_FOR_POD );
            } elsif ( $elem->location->[2] > $soft_max_line_length ) {
                push @soft_violations,
                  $self->violation( $DESC_SOFT, $EXPL, $elem,
                    $SEVERITY_FOR_POD );
            }
        }
    }

    return @hard_violations if @hard_violations;
    return @soft_violations
      if $lines
          and scalar @soft_violations / $lines > $pct_long_lines_allowed;

    # No violations
    return;
}

sub _is_eol_for_code {
    my ( $doc, $elem ) = @_;

    return 1
      if $elem->isa('PPI::Token::Whitespace') && ( $elem =~ $LINE_END );
    return 0;
}
1;

__END__

#-----------------------------------------------------------------------------

=head1 NAME

Perl::Critic::Policy::CodeLayout::ProhibitLongLines - Lines should be limited to 78 columns

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.

=head1 DESCRIPTION

While most people code on monitors that can support much more than
a 78 character line, line lengths should be limited in order to
support printed documents, legacy VGA displays, email, etc. 

This policy allows some configurable flexibility in your code.
There are both soft and hard line limits. Violations are only 
reported if a line exceeds the hard limit or if the soft limit
is exceeded for more than some percentage of lines. Your code
and POD also have different maximums.

The contents of the C<__DATA__> section are not examined.

=head1 CONFIGURATION

Maximums line lengths for code and POD can be configured
separately.  If you would like to change the hard or soft 
maximum lengths, or the percentage of soft violations allowed,
by this policy add this to your F<.perlcriticrc> file:

    [CodeLayout::ProhibitLongLines]
        max_code_line_length = 78
        hard_max_code_line_length = 120
        percent_long_code_lines_allowed = 3
        max_pod_line_length = 70
        hard_max_pod_line_length = 105
        percent_long_pod_lines_allowed = 3


=head1 AUTHOR

Mark Grimes <mgrimes@cpan.org>

=for stopwords SIGNES

The hard vs. soft violation concept came from Ricardo SIGNES. Thanks.

=head1 COPYRIGHT

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
