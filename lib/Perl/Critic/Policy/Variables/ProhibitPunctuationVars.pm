package Perl::Critic::Policy::Variables::ProhibitPunctuationVars;

use 5.006001;
use strict;
use warnings;
use Readonly;
use English qw< -no_match_vars >;

use PPI::Token::Magic;

use Perl::Critic::Utils qw<
    :characters :severities :data_conversion :booleans
>;

use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q<Magic punctuation variable %s used>;
Readonly::Scalar my $EXPL => [79];

#-----------------------------------------------------------------------------

# There is no English.pm equivalent for $].
sub supported_parameters {
    return (
        {
            name           => 'allow',
            description    => 'The additional variables to allow.',
            default_string => $EMPTY,
            behavior       => 'string list',
            list_always_present_values =>
                [ qw< $_ @_ $1 $2 $3 $4 $5 $6 $7 $8 $9 _ $] > ],
        },
        {
            name               => 'string_mode',
            description        =>
                'Controls checking interpolated strings for punctuation variables.',
            default_string     => 'thorough',
            behavior           => 'enumeration',
            enumeration_values => [ qw< simple disable thorough > ],
            enumeration_allow_multiple_values => 0,
        },
    );
}

sub default_severity { return $SEVERITY_LOW }
sub default_themes   { return qw< core pbp cosmetic > }

sub applies_to {
    return qw<
        PPI::Token::Magic
        PPI::Token::Quote::Double
        PPI::Token::Quote::Interpolate
        PPI::Token::QuoteLike::Command
        PPI::Token::QuoteLike::Backtick
        PPI::Token::QuoteLike::Regexp
        PPI::Token::QuoteLike::Readline
        PPI::Token::HereDoc
    >;
}

#-----------------------------------------------------------------------------


# This list matches the initialization of %PPI::Token::Magic::magic.
## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Array my @MAGIC_VARIABLES =>
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
    },
    q<$}>,
    q<$,>,
    q<$#>,
    q<$#+>,
    q<$#->;
## use critic

# The main regular expression for detecting magic variables.
Readonly::Scalar my $MAGIC_REGEX => _create_magic_detector();

# The magic vars in this array will be ignored in interpolated strings
# in simple mode. See CONFIGURATION in the pod.
Readonly::Array my @IGNORE_FOR_INTERPOLATION =>
    ( q{$'}, q{$$}, q{$#}, q{$:}, );    ## no critic ( RequireInterpolationOfMetachars, ProhibitQuotedWordLists )

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    if ( $elem->isa('PPI::Token::Magic') ) {
        return _violates_magic( $self, $elem );
    }
    elsif ( $elem->isa('PPI::Token::HereDoc') ) {
        return _violates_heredoc( $self, $elem );
    }

    #the remaining applies_to() classes are all interpolated strings
    return _violates_string( $self, $elem );
}

#-----------------------------------------------------------------------------

# Helper functions for the three types of violations: code, quotes, heredoc

sub _violates_magic {
    my ( $self, $elem, undef ) = @_;

    if ( !exists $self->{_allow}->{$elem} ) {
        return $self->_make_violation( $DESC, $EXPL, $elem );
    }

    return;    # no violation
}

sub _violates_string {
    my ( $self, $elem, undef ) = @_;

    # RT #55604: Variables::ProhibitPunctuationVars gives false-positive on
    # qr// regexp's ending in '$'
    # We want to analyze the content of the string in the dictionary sense of
    # the word 'content'. We can not simply use the PPI content() method to
    # get this, because content() includes the delimiters.
    my $string;
    if ( $elem->can( 'string' ) ) {
        # If we have a string() method (currently only the PPI::Token::Quote
        # classes) use it to extract the content of the string.
        $string = $elem->string();
    } else {
        # Lacking string(), we fake it under the assumption that the content
        # of our element represents one of the 'normal' Perl strings, with a
        # single-character delimiter, possibly preceded by an operator like
        # 'qx' or 'qr'. If there is a leading operator, spaces may appear
        # after it.
        $string = $elem->content();
        $string =~ s/ \A \w* \s* . //smx;
        chop $string;
    }

    my %matches = _strings_helper( $self, $string );
    if (%matches) {
        my $DESC = qq<$DESC in interpolated string>;
        return $self->_make_violation( $DESC, $EXPL, $elem, \%matches );
    }

    return;    # no violation
}

sub _violates_heredoc {
    my ( $self, $elem, undef ) = @_;

    if ( $elem->{_mode} eq 'interpolate' or $elem->{_mode} eq 'command' ) {
        my $heredoc_string = join "\n", $elem->heredoc();
        my %matches = _strings_helper( $self, $heredoc_string );
        if (%matches) {
            my $DESC = qq<$DESC in interpolated here-document>;
            return $self->_make_violation( $DESC, $EXPL, $elem, \%matches );
        }
    }

    return;    # no violation
}

#-----------------------------------------------------------------------------

# Helper functions specific to interpolated strings

sub _strings_helper {
    my ( $self, $target_string, undef ) = @_;

    return if ( $self->{_string_mode} eq 'disable' );
    return _strings_thorough( $self, $target_string )
        if $self->{_string_mode} eq 'thorough';

    # we are in string_mode = simple

    my @raw_matches = map { _unbracket_variable_name( $_ ) }
        $target_string =~ m/$MAGIC_REGEX/goxms;
    return if not @raw_matches;

    my %matches = hashify(@raw_matches);

    delete @matches{ keys %{ $self->{_allow} } };
    delete @matches{@IGNORE_FOR_INTERPOLATION};

    return %matches;
}

sub _strings_thorough {
    my ( $self, $target_string, undef ) = @_;
    my %matches;

    MATCH:
    while ( my ($match) = $target_string =~ m/$MAGIC_REGEX/gcxms ) {
        my $nextchar = substr $target_string, $LAST_MATCH_END[0], 1;
        my $vname = _unbracket_variable_name( $match );
        my $c = $vname . $nextchar;

        # These tests closely parallel those in PPI::Token::Magic,
        # from which the regular expressions were taken.
        # A degree of simplicity is sacrificed to maintain the parallel.
        # $c is so named by analogy to that module.

        # possibly *not* a magic variable
        if ($c =~ m/ ^  \$  .*  [  \w  :  \$  {  ]  $ /xms) {
            ## no critic (RequireInterpolationOfMetachars)

            if (
                    $c =~ m/ ^(\$(?:\_[\w:]|::)) /xms
                or  $c =~ m/ ^\$\'[\w] /xms )
            {
                next MATCH
                    if $c !~ m/ ^\$\'\d$ /xms;
                    # It not $' followed by a digit.
                    # So it's magic var with something immediately after.
            }

            next MATCH
                if $c =~ m/ ^\$\$\w /xms; # It's a scalar dereference
            next MATCH
                if $c eq '$#$'
                    or $c eq '$#{';       # It's an index dereferencing cast
            next MATCH
                if $c =~ m/ ^(\$\#)\w /xms
            ;    # It's an array index thingy, e.g. $#array_name

            # PPI's checks for long escaped vars like $^WIDE_SYSTEM_CALLS
            # appear to be erroneous, and are omitted here.
            # if ( $c =~ m/^\$\^\w{2}$/xms ) {
            # }

            next MATCH if $c =~ m/ ^ \$ \# [{] /xms;    # It's a $#{...} cast
        }

        # The additional checking that PPI::Token::Magic does at this point
        # is not necessary here, in an interpolated string context.

        $matches{$vname} = 1;
    }

    delete @matches{ keys %{ $self->{_allow} } };

    return %matches;
}

# RT #72910: A magic variable may appear in bracketed form; e.g. "$$" as
# "${$}".  Generate the bracketed form from the unbracketed form, and
# return both.
sub _bracketed_form_of_variable_name {
    my ( $name ) = @_;
    length $name > 1
        or return ( $name );
    my $brktd = $name;
    substr $brktd, 1, 0, '{';
    $brktd .= '}';
    return( $name, $brktd );
}

# RT #72910: Since we loaded both bracketed and unbracketed forms of the
# punctuation variables into our detecting regex, we need to detect and
# strip the brackets if they are present to recover the canonical name.
sub _unbracket_variable_name {
    my ( $name ) = @_;
    $name =~ m/ \A ( . ) [{] ( .+ ) [}] \z /smx
        and return "$1$2";
    return $name;
}

#-----------------------------------------------------------------------------

sub _create_magic_detector {
    my ($config) = @_;

    # Set up the regexp alternation for matching magic variables.
    # We can't process $config->{_allow} here because of a quirk in the
    # way Perl::Critic handles testing.
    #
    # The sort is needed so that, e.g., $^ doesn't mask out $^M
    my $magic_alternation =
            '(?:'
        .   (
            join
                q<|>,
                map          { quotemeta }
                reverse sort { length $a <=> length $b }
                map          { _bracketed_form_of_variable_name( $_ ) }
                grep         { q<%> ne substr $_, 0, 1 }
                @MAGIC_VARIABLES
        )
        .   ')';

    return qr<
        (?: \A | [^\\] )       # beginning-of-string or any non-backslash
        (?: \\{2} )*           # zero or more double-backslashes
        ( $magic_alternation ) # any magic punctuation variable
    >xsm;
}

sub _make_violation {
    my ( $self, $desc, $expl, $elem, $vars ) = @_;

    my $vname = 'HASH' eq ref $vars ?
        join ', ', sort keys %{ $vars } :
        $elem->content();
    return $self->violation( sprintf( $desc, $vname ), $expl, $elem );
}

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
  local $OUTPUT_AUTOFLUSH = undef; #ok

=head1 CONFIGURATION

The scratch variables C<$_> and C<@_> are very common and are pretty
well understood, so they are exempt from this policy.  The same goes
for the less-frequently-used default filehandle C<_> used by stat().
All the regexp capture variables (C<$1>, C<$2>, ...) are exempt too.
C<$]> is exempt because there is no L<English|English> equivalent and
L<Module::CoreList|Module::CoreList> is based upon it.

You can add more exceptions to your configuration.  In your
perlcriticrc file, add a block like this:

  [Variables::ProhibitPunctuationVars]
  allow = $@ $!

The C<allow> property  should  be  a  whitespace-delimited  list  of
punctuation variables.

Other configuration options  control  the  parsing  of  interpolated
strings in the search for forbidden variables. They have  no  effect
on detecting punctuation variables outside of interpolated  strings.

  [Variables::ProhibitPunctuationVars]
  string_mode = thorough

The option C<string_mode>  controls  whether  and  how  interpolated
strings are searched for punctuation variables. Setting
C<string_mode = thorough>, the default,  checks  for  special  cases
that may look like punctuation variables  but  aren't,  for  example
C<$#foo>, an array index count; C<$$bar>, a scalar  dereference;  or
C<$::baz>, a global symbol.

Setting C<string_mode = disable> causes all interpolated strings  to
be ignored entirely.

Setting C<string_mode = simple> uses a simple regular expression  to
find matches. In this mode, the magic variables C<$$>, C<$'>,  C<$#>
and C<$:> are ignored within interpolated strings due  to  the  high
risk of false positives. Simple mode is  retained  from  an  earlier
draft of the interpolated- strings code. Its use is only recommended
as a workaround if bugs appear in thorough mode.

The  C<string_mode>  option  will  go  away  when  the  parsing   of
interpolated strings is implemented in PPI. See  L</CAVEATS>  below.


=head1 BUGS

Punctuation variables that confuse PPI's document parsing may not be
detected  correctly  or  at  all,  and  may  prevent  detection   of
subsequent ones. In particular, C<$"> is known to cause difficulties
in interpolated strings.


=head1 CAVEATS

ProhibitPunctuationVars  relies   exclusively   on   PPI   to   find
punctuation variables in code, but does all the parsing  itself  for
interpolated strings. When, at some  point,  this  functionality  is
transferred to PPI, ProhibitPunctuationVars  will  cease  doing  the
interpolating  and  the  C<string_mode>   option   will   go   away.


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2005-2011 Imaginative Software Systems.  All rights reserved.

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
