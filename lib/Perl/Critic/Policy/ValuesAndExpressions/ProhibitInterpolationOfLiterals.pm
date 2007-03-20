##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::ValuesAndExpressions::ProhibitInterpolationOfLiterals;

use strict;
use warnings;
use List::MoreUtils qw(any);
use Perl::Critic::Utils qw{ :severities :data_conversion };
use base 'Perl::Critic::Policy';

our $VERSION = 1.05;

#-----------------------------------------------------------------------------

my $desc = q{Useless interpolation of literal string};
my $expl = [51];

#-----------------------------------------------------------------------------

sub supported_parameters  { return qw( allow )             }
sub default_severity   { return $SEVERITY_LOWEST        }
sub default_themes     { return qw( core pbp cosmetic ) }
sub applies_to         { return qw(PPI::Token::Quote::Double
                                   PPI::Token::Quote::Interpolate) }

#-----------------------------------------------------------------------------

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;
    $self->{_allow} = [];

    #Set configuration, if defined
    if ( defined $args{allow} ) {
        my @allow = words_from_string( $args{allow} );
        #Try to be forgiving with the configuration...
        for (@allow) {
            m{ \A qq }mx || ($_ = 'qq' . $_)
        }  #Add 'qq'
        for (@allow) {
            (length $_ <= 3) || chop
        }    #Chop closing char
        $self->{_allow} = \@allow;
    }

    return $self;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    # Skip if this string needs interpolation
    return if _has_interpolation($elem);

    #Overlook allowed quote styles
    return if any { $elem =~ m{ \A \Q$_\E }mx } @{ $self->{_allow} };

    # Must be a violation
    return $self->violation( $desc, $expl, $elem );
}

#-----------------------------------------------------------------------------

sub _has_interpolation {
    my $elem = shift;
    return $elem =~ m{ (?<!\\) [\$\@] \S+ }mx      #Contains unescaped $. or @.
        || $elem =~ m{ \\[tnrfbae0xcNLuLUEQ] }mx;   #Containts escaped metachars
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitInterpolationOfLiterals

=head1 DESCRIPTION

Don't use double-quotes or C<qq//> if your string doesn't require
interpolation.  This saves the interpreter a bit of work and it lets
the reader know that you really did intend the string to be literal.

  print "foobar";     #not ok
  print 'foobar';     #ok
  print qq/foobar/;   #not ok
  print q/foobar/;    #ok

  print "$foobar";    #ok
  print "foobar\n";   #ok
  print qq/$foobar/;  #ok
  print qq/foobar\n/; #ok

  print qq{$foobar};  #preferred
  print qq{foobar\n}; #preferred

=head1 CONFIGURATION

The types of quoting styles to exempt from this policy can be
configured via the C<allow> option.  This must be a
whitespace-delimited combination of some or all of the following
styles: C<qq{}>, C<qq()>, C<qq[]>, and C<qq//>.

This is useful because some folks have configured their editor to
apply special syntax highlighting within certain styles of quotes.
For example, you can tweak C<vim> to use SQL highlighting for
everything that appears within C<qq{}> or C<qq[]> quotes.  But if
those strings are literal, Perl::Critic will complain.  To prevent
this, put the following in your F<.perlcriticrc> file:

  [ValuesAndExpressions::ProhibitInterpolationOfLiterals]
  allow = qq{} qq[]

=head1 SEE ALSO

L<Perl::Critic::Policy::ValuesAndExpressions::RequireInterpolationOfMetachars>

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
