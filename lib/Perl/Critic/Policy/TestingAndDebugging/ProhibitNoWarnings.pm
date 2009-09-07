##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::TestingAndDebugging::ProhibitNoWarnings;

use 5.006001;
use strict;
use warnings;
use Readonly;

use List::MoreUtils qw(all);

use Perl::Critic::Utils qw{ :characters :severities :data_conversion };
use base 'Perl::Critic::Policy';

our $VERSION = '1.105';

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
sub default_themes   { return qw( core bugs pbp )       }
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

    # Arguments to 'no warnings' are usually a list of literals or a
    # qw() list.  Rather than trying to parse the various PPI elements,
    # I just use a regex to split the statement into words.  This is
    # kinda lame, but it does the trick for now.

    # TODO consider: a possible alternate implementation:
    #   my $re = join q{|}, keys %{$self->{allow}};
    #   return if $re && $statement =~ m/\b(?:$re)\b/mx;
    # May need to detaint for that to work...  Not sure.

    my $statement = $elem->statement();
    return if not $statement;
    my @words = $statement =~ m/ ( [[:lower:]]+ ) /gxms;
    @words = grep { $_ ne 'qw' && $_ ne 'no' && $_ ne 'warnings' } @words;

    return if $self->{_allow_with_category_restriction} and @words;
    return if all { exists $self->{_allow}->{$_} } @words;

    #If we get here, then it must be a violation
    return $self->violation( $DESC, $EXPL, $elem );
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

Jeffrey Ryan Thalhammer <thaljef@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2005-2009 Jeffrey Ryan Thalhammer.  All rights reserved.

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
