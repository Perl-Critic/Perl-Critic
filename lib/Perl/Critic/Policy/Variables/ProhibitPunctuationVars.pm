##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::Variables::ProhibitPunctuationVars;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils
    qw{ :characters :severities :data_conversion :booleans };
use base 'Perl::Critic::Policy';

our $VERSION = '1.096';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Magic punctuation variable used};
Readonly::Scalar my $EXPL => [79];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {   name           => 'allow',
            description    => 'The additional variables to allow.',
            default_string => $EMPTY,
            behavior       => 'string list',
            list_always_present_values =>
                [qw( $_ @_ $1 $2 $3 $4 $5 $6 $7 $8 $9 _ )],
        },
    );
}

sub default_severity { return $SEVERITY_LOW }
sub default_themes   { return qw(core pbp cosmetic) }

sub applies_to {
    return qw( PPI::Token::Magic
        PPI::Token::Quote::Double
        PPI::Token::Quote::Interpolate
        PPI::Token::QuoteLike::Command
        PPI::Token::QuoteLike::Backtick
        PPI::Token::QuoteLike::Regexp
        PPI::Token::QuoteLike::Readline
        PPI::Token::HereDoc
    );
}

#-----------------------------------------------------------------------------

# package state
my $_magic_regexp;

# private functions
my $_violates_magic;
my $_violates_string;
my $_violates_heredoc;
my $_strings_helper;

#-----------------------------------------------------------------------------

sub initialize_if_enabled {

    # my $config = shift; # policy $config not needed at present

    my %_magic_vars;

    # Magic variables taken from perlvar.
    # Several things added separately to avoid warnings.
    # adapted from ADAMK's PPI::Token::Magic.pm
    foreach (
        qw{
        $1 $2 $3 $4 $5 $6 $7 $8 $9
        $_ $& $` $' $+ @+ %+ $* $. $/ $|
        $\\ $" $; $% $= $- @- %- $)
        $~ $^ $: $? $! %! $@ $$ $< $>
        $( $0 $[ $] @_ @*

        $^L $^A $^E $^C $^D $^F $^H
        $^I $^M $^N $^O $^P $^R $^S
        $^T $^V $^W $^X %^H

        $::|
        }, '$}', '$,', '$#', '$#+', '$#-'
        )
    {
        $_magic_vars{$_} = $_;
        $_magic_vars{$_}
            =~ s{ ( [[:punct:]] ) }{\\$1}gox;   # add \ before all punctuation
    }

    delete @_magic_vars{ @{ supported_parameters()
                ->{list_always_present_values} } };

    $_magic_regexp = join q(|), values %_magic_vars;

    return $TRUE;
}

sub violates {
    my ( $self, $elem, undef ) = @_;

    if ( $elem->isa('PPI::Token::Magic') ) {
        return $_violates_magic->(@_);
    }
    elsif ( $elem->isa('PPI::Token::HereDoc') ) {
        return $_violates_heredoc->(@_);
    }
    else {

        #the remaining applies_to() classes are all interpolated strings
        return $_violates_string->(@_);
    }

    die 'Impossible! fall-through error in method violates()';
}

#-----------------------------------------------------------------------------

$_violates_magic = sub {
    my ( $self, $elem, undef ) = @_;

    if ( !exists $self->{_allow}->{$elem} ) {

        return $self->violation( $DESC, $EXPL, $elem );
    }

    return;
};

$_violates_string = sub {
    my ( $self, $elem, undef ) = @_;

    my %matches = $_strings_helper->( $elem->content(), $self->{_allow} );

    if (%matches) {
        my $DESC = qq{$DESC in interpolated string};

        return $self->violation( $DESC, $EXPL, $elem );
    }

    return;

};

$_violates_heredoc = sub {
    my ( $self, $elem, undef ) = @_;

    if ( $elem->{_mode} eq 'interpolate' or $elem->{_mode} eq 'command' ) {

        my $heredoc_string = join qq{\n}, $elem->heredoc();
        my %matches = $_strings_helper->( $heredoc_string, $self->{_allow} );

        if (%matches) {
            my $DESC = qq{$DESC in interpolated here-document};

            return $self->violation( $DESC, $EXPL, $elem );
        }
    }

    return;
};

$_strings_helper = sub {
    my ( $target_string, $allow_ref, undef ) = @_;

    my @raw_matches = (
        $target_string =~ m/
            (?: \A | [^\\] )   # beginning-of-string or any non-backslash 
            (?: \\\\ )*        # zero or more double-backslashes
            ( $_magic_regexp ) # any magic punctuation variable
        /goxs
    );

    my %matches;
    @matches{@raw_matches} = 1;
    delete @matches{ keys %{$allow_ref} };

    return %matches
        if (%matches);

    return;    #no matches
};

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Variables::ProhibitPunctuationVars - Write C<$EVAL_ERROR> instead of C<$@>.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Perl's vocabulary of punctuation variables such as C<$!>, C<$.>, and
C<$^> are perhaps the leading cause of its reputation as inscrutable
line noise.  The simple alternative is to use the L<English|English>
module to give them clear names.

  $| = undef;                      #not ok

  use English qw(-no_match_vars);
  local $OUTPUT_AUTOFLUSH = undef;        #ok


=head1 CONFIGURATION

The scratch variables C<$_> and C<@_> are very common and are pretty
well understood, so they are exempt from this policy.  The same goes
for the less-frequently-used default filehandle C<_> used by stat().
All the regexp capture variables (C<$1>, C<$2>, ...) are exempt too.

You can add more exceptions to your configuration.  In your
perlcriticrc file, add a block like this:

  [Variables::ProhibitPunctuationVars]
  allow = $@ $!

The C<allow> property should be a whitespace-delimited list of
punctuation variables.


=head1 BUGS

Punctuation variables that confuse PPI's document parsing may not be
detected correctly or at all, and may prevent detection of subsequent
ones.


=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>
Edgar Whipple <perlmonk at misterwhipple dot com>


=head1 COPYRIGHT

Copyright (c) 2005-2009 Jeffrey Ryan Thalhammer.  All rights reserved.
Additions for interpolated strings (c) 2009 Edgar Whipple. All rights reserved.

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
