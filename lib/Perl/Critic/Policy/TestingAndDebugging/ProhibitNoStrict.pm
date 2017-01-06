package Perl::Critic::Policy::TestingAndDebugging::ProhibitNoStrict;

use 5.006001;
use strict;
use warnings;
use Readonly;

use List::MoreUtils qw(all);

use Perl::Critic::Utils qw{ :characters :severities :data_conversion };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Stricture disabled};
Readonly::Scalar my $EXPL => [ 429 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'allow',
            description     => 'Allow vars, subs, and/or refs.',
            default_string  => $EMPTY,
            parser          => \&_parse_allow,
        },
    );
}

sub default_severity { return $SEVERITY_HIGHEST         }
sub default_themes   { return qw( core pbp bugs certrec )       }
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
    return if $elem->pragma() ne 'strict';

    #Arguments to 'no strict' are usually a list of literals or a qw()
    #list.  Rather than trying to parse the various PPI elements, I
    #just use a regex to split the statement into words.  This is
    #kinda lame, but it does the trick for now.

    # TODO consider: a possible alternate implementation:
    #   my $re = join q{|}, keys %{$self->{allow}};
    #   return if $re && $stmnt =~ m/\b(?:$re)\b/mx;
    # May need to detaint for that to work...  Not sure.

    my $stmnt = $elem->statement();
    return if !$stmnt;
    my @words = $stmnt =~ m/ ([[:lower:]]+) /gxms;
    @words = grep { $_ ne 'qw' && $_ ne 'no' && $_ ne 'strict' } @words;
    return if @words && all { exists $self->{_allow}->{$_} } @words;

    #If we get here, then it must be a violation
    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::TestingAndDebugging::ProhibitNoStrict - Prohibit various flavors of C<no strict>.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

There are good reasons for disabling certain kinds of strictures, But
if you were wise enough to C<use strict> in the first place, then it
doesn't make sense to disable it completely.  By default, any C<no
strict> statement will violate this policy.  However, you can
configure this Policy to allow certain types of strictures to be
disabled (See L</CONFIGURATION>).  A bare C<no strict> statement will
always raise a violation.


=head1 CONFIGURATION

The permitted strictures can be configured via the C<allow> option.
The value is a list of whitespace-delimited stricture types that you
want to permit.  These can be C<vars>, C<subs> and/or C<refs>.  An
example of this customization:

    [TestingAndDebugging::ProhibitNoStrict]
    allow = vars subs refs


=head1 SEE ALSO

L<Perl::Critic::Policy::TestingAndDebugging::RequireUseStrict|Perl::Critic::Policy::TestingAndDebugging::RequireUseStrict>


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2005-2011 Imaginative Software Systems.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module

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
