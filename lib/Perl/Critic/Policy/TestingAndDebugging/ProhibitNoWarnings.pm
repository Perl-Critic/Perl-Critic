package Perl::Critic::Policy::TestingAndDebugging::ProhibitNoWarnings;

use 5.006001;
use strict;
use warnings;
use Readonly;

use List::MoreUtils qw(all);

use Perl::Critic::Exception::Fatal::Internal qw{ throw_internal };
use Perl::Critic::Utils qw{ :characters :severities :data_conversion };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Warnings disabled};
Readonly::Scalar my $EXPL => [ 431 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'allow',
            description     => 'Permitted warning categories.',
            default_string  => $EMPTY,
            parser          => \&_parse_allow,
        },
        {
            name           => 'allow_with_category_restriction',
            description    =>
                'Allow "no warnings" if it restricts the kinds of warnings that are turned off.',
            default_string => '0',
            behavior       => 'boolean',
        },
    );
}

sub default_severity { return $SEVERITY_HIGH            }
sub default_themes   { return qw( core bugs pbp certrec )       }
sub applies_to       { return 'PPI::Statement::Include' }

#-----------------------------------------------------------------------------

sub _parse_allow {
    my ($self, $parameter, $config_string) = @_;

    $self->{_allow} = {};

    if( defined $config_string ) {
        my $allowed = lc $config_string; #String of words
        my %allowed = hashify( $allowed =~ m/ (\w+) /gxms );

        $self->{_allow} = \%allowed;
    }

    return;
}

#-----------------------------------------------------------------------------

sub violates {

    my ( $self, $elem, undef ) = @_;

    return if $elem->type()   ne 'no';
    return if $elem->pragma() ne 'warnings';

    my @words = _extract_potential_categories( $elem );
    @words >= 2
        and 'no' eq $words[0]
        and 'warnings' eq $words[1]
        or throw_internal
            q<'no warnings' word list did not begin with qw{ no warnings }>;
    splice @words, 0, 2;

    return if $self->{_allow_with_category_restriction} and @words;
    return if @words && all { exists $self->{_allow}->{$_} } @words;

    #If we get here, then it must be a violation
    return $self->violation( $DESC, $EXPL, $elem );
}

#-----------------------------------------------------------------------------

# Traverse the element, accumulating and ultimately returning things
# that might be warnings categories. These are:
# * Words (because of the 'foo' in 'no warnings foo => "bar"');
# * Quotes (because of 'no warnings "foo"');
# * qw{} strings (obviously);
# * Nodes (because of 'no warnings ( "foo", "bar" )').
# We don't lop off the 'no' and 'warnings' because we recurse.
# RT #74647.

{

    Readonly::Array my @HANDLER => (
        [ 'PPI::Token::Word' => sub { return $_[0]->content() } ],
        [ 'PPI::Token::QuoteLike::Words'  =>
            sub { return $_[0]->literal() }, ],
        [ 'PPI::Token::Quote' => sub { return $_[0]->string() } ],
        [ 'PPI::Node' => sub { _extract_potential_categories( $_[0] ) } ],
    );

    sub _extract_potential_categories {
        my ( $elem ) = @_;

        my @words;
        foreach my $child ( $elem->schildren() ) {
            foreach my $hdlr ( @HANDLER ) {
                $child->isa( $hdlr->[0] )
                    or next;
                push @words, $hdlr->[1]->( $child );
                last;
            }
        }

        return @words;
    }

}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords perllexwarn

=head1 NAME

Perl::Critic::Policy::TestingAndDebugging::ProhibitNoWarnings - Prohibit various flavors of C<no warnings>.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

There are good reasons for disabling certain kinds of warnings.  But
if you were wise enough to C<use warnings> in the first place, then it
doesn't make sense to disable them completely.  By default, any
C<no warnings> statement will violate this policy.  However, you can
configure this Policy to allow certain types of warnings to be
disabled (See L<"CONFIGURATION">).  A bare C<no warnings>
statement will always raise a violation.


=head1 CONFIGURATION

The permitted warning types can be configured via the C<allow> option.
The value is a list of whitespace-delimited warning types that you
want to be able to disable.  See L<perllexwarn|perllexwarn> for a list
of possible warning types.  An example of this customization:

    [TestingAndDebugging::ProhibitNoWarnings]
    allow = uninitialized once

If a true value is specified for the
C<allow_with_category_restriction> option, then any C<no warnings>
that restricts the set of warnings that are turned off will pass.

    [TestingAndDebugging::ProhibitNoWarnings]
    allow_with_category_restriction = 1

=head1 SEE ALSO

L<Perl::Critic::Policy::TestingAndDebugging::RequireUseWarnings|Perl::Critic::Policy::TestingAndDebugging::RequireUseWarnings>


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2005-2011 Imaginative Software Systems.  All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  The full text of this license can be found in
the LICENSE file included with this module

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
