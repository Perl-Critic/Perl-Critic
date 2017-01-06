package Perl::Critic::Policy::BuiltinFunctions::ProhibitUselessTopic;

use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :ppi };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

## no critic ( ValuesAndExpressions::RequireInterpolationOfMetachars )
## The numerous $_ variables make false positives.
Readonly::Scalar my $DESC                => q{Useless use of $_};
Readonly::Scalar my $EXPL_FILETEST       => q{$_ should be omitted when using a filetest operator};
Readonly::Scalar my $EXPL_FUNCTION       => q{$_ should be omitted when calling "%s"};
Readonly::Scalar my $EXPL_FUNCTION_SPLIT => q{$_ should be omitted when calling "split" with two arguments};

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_LOW }
sub default_themes       { return qw( core ) }
sub applies_to           { return 'PPI::Token::Operator', 'PPI::Token::Word' }

my @filetest_operators = qw( -r -w -x -o -R -W -X -O -e -z -s -f -d -l -p -S -b -c -u -g -k -T -B -M -A -C );
my %filetest_operators = map { ($_ => 1) } @filetest_operators;

my @topical_funcs = qw(
    abs alarm
    chomp chop chr chroot cos
    defined
    eval exp
    fc
    glob
    hex
    int
    lc lcfirst length log lstat
    mkdir
    oct ord
    pos print
    quotemeta
    readlink readpipe ref require reverse rmdir
    say sin split sqrt stat study
    uc ucfirst unlink unpack
);
my %topical_funcs = map { ($_ => 1) } @topical_funcs;

sub violates {
    my ( $self, $elem, undef ) = @_;

    my $content = $elem->content;

    # Are we looking at a filetest?
    if ( $filetest_operators{ $content } ) {
        # Is there a $_ following it?
        my $op_node = $elem->snext_sibling;
        if ( $op_node && $op_node->isa('PPI::Token::Magic') ) {
            my $op = $op_node->content;
            if ( $op eq '$_' ) {
                return $self->violation( $DESC, $EXPL_FILETEST, $elem );
            }
        }
        return;
    }

    if ( $topical_funcs{ $content } && is_perl_builtin( $elem ) ) {
        my $is_split = $content eq 'split';

        my @args = parse_arg_list( $elem );

        my $nth_arg_for_topic;
        if ( $is_split ) {
            return if @args != 2; # Ignore split( /\t/ ) or split( /\t/, $_, 3 )
            $nth_arg_for_topic = 2;
        }
        else {
            $nth_arg_for_topic = 1;
        }

        if ( @args == $nth_arg_for_topic ) {
            my $topic_arg = $args[ $nth_arg_for_topic - 1 ];
            my @tokens = @{$topic_arg};
            if ( (@tokens == 1) && ($tokens[0]->content eq '$_') ) {
                my $msg = $is_split ? $EXPL_FUNCTION_SPLIT : (sprintf $EXPL_FUNCTION, $content);
                return $self->violation( $DESC, $msg, $elem );
            }
        }
        return;
    }

    return;
}


1;

__END__

=pod

=for stopwords filetest

=head1 NAME

Perl::Critic::Policy::BuiltinFunctions::ProhibitUselessTopic - Don't pass $_ to built-in functions that assume it, or to most filetest operators.

=head1 AFFILIATION

This Policy is part of the L<Perl::Critic|Perl::Critic> distribution.

=head1 DESCRIPTION

There are a number of places where C<$_>, or "the topic" variable,
is unnecessary.

=head2 Topic unnecessary for certain Perl built-in functions

Many Perl built-in functions will operate on C<$_> if no argument
is passed.  For example, the C<length> function will operate on
C<$_> by default.  This snippet:

    for ( @list ) {
        if ( length( $_ ) == 4 ) { ...

is more idiomatically written as:

    for ( @list ) {
        if ( length == 4 ) { ...

In the case of the C<split> function, the second argument is the
one that defaults to C<$_>.  This snippet:

    for ( @list ) {
        my @args = split /\t/, $_;

is better written as:

    for ( @list ) {
        my @args = split /\t/;

There is one built-in that this policy does B<not> check for:
C<reverse> called with C<$_>.

The C<reverse> function only operates on C<$_> if called in scalar
context.  Therefore:

    for ( @list ) {
        my $backwards = reverse $_;

is better written as:

    for ( @list ) {
        my $backwards = reverse;

However, the distinction for scalar vs. list context on C<reverse>
is not yet working.  See L<KNOWN BUGS|KNOWN BUGS> below.

=head2 Topic unnecessary for most filetest operators

Another place that C<$_> is unnecessary is with a filetest operator.

    # These are identical.
    my $size = -s $_;
    my $size = -s;

    # These are identical.
    if ( -r $_ ) { ...
    if ( -r ) { ...

The exception is after the C<-t> filetest operator, which instead of
defaulting to C<$_> defaults to C<STDIN>.

    # These are NOT identical.
    if ( -t $_ ) { ...
    if ( -t ) { ...  # Checks STDIN, not $_

=head1 KNOWN BUGS

This policy flags a false positive on C<reverse> called in list
context, since C<reverse> in list context does I<not> assume C<$_>.

    my $s = reverse( $_ ); # $_ is useless.
    my @a = reverse( $_ ); # $_ is not useless here.

=head1 CONFIGURATION

This Policy is not configurable except for the standard options.

=head1 AUTHOR

Andy Lester <andy@petdance.com>

=head1 COPYRIGHT

Copyright (c) 2013 Andy Lester <andy@petdance.com>

This library is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
