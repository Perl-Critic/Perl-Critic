package Perl::Critic::Policy::RegularExpressions::ProhibitUselessTopic;

use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :ppi };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

## no critic ( ValuesAndExpressions::RequireInterpolationOfMetachars )
## The numerous $_ variables make false positives.
Readonly::Scalar my $DESC => q{Useless use of $_};
Readonly::Scalar my $EXPL => q{$_ should be omitted when matching a regular expression};

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_LOW }
sub default_themes       { return qw( core ) }
sub applies_to           { return 'PPI::Token::Magic' }

sub violates {
    my ( $self, $elem, undef ) = @_;

    my $content = $elem->content;
    if ( $content eq q{$_} ) {
        # Is there an op following the $_ ?
        my $op_node = $elem->snext_sibling;
        if ( $op_node && $op_node->isa('PPI::Token::Operator') ) {
            # If the op is a regex match, then we have an unnecessary $_ .
            my $op = $op_node->content;
            if ( $op eq q{=~} || $op eq q{!~} ) {
                my $target_node = $op_node->snext_sibling;
                if ( $target_node && ($target_node->isa('PPI::Token::Regexp') || $target_node->isa('PPI::Token::QuoteLike::Regexp')) ) {
                    return $self->violation( $DESC, $EXPL, $elem );
                }
            }
        }
    }

    return;
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::RegularExpressions::ProhibitUselessTopic - Don't use $_ to match against regexes.

=head1 AFFILIATION

This Policy is part of the L<Perl::Critic|Perl::Critic> distribution.

=head1 DESCRIPTION

It is not necessary to specify the topic variable C<$_> when matching
against a regular expression.

Match or substitution operations are performed against variables, such as:

    $x =~ /foo/;
    $x =~ s/foo/bar/;
    $x =~ tr/a-mn-z/n-za-m/;

If a variable is not specified, the match is against C<$_>.

    # These are identical.
    /foo/;
    $_ =~ /foo/;

    # These are identical.
    s/foo/bar/;
    $_ =~ s/foo/bar/;

    # These are identical.
    tr/a-mn-z/n-za-m/;
    $_ =~ tr/a-mn-z/n-za-m/;

This applies to negative matching as well.

    # These are identical
    if ( $_ !~ /DEBUG/ ) { ...
    if ( !/DEBUG ) { ...

Including the C<$_ =~> or C<$_ !~> is unnecessary, adds complexity,
and is not idiomatic Perl.

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
