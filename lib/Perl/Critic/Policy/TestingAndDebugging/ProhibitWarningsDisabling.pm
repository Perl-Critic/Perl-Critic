#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
########################################################################

package Perl::Critic::Policy::TestingAndDebugging::ProhibitWarningsDisabling;

use strict;
use warnings;
use List::MoreUtils qw(all);
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.13_01';
$VERSION = eval $VERSION;    ## no critic

#---------------------------------------------------------------------------

my $desc = q{Warnings disabled};
my $expl = [ 431 ];

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGH }
sub applies_to { return 'PPI::Statement::Include' }

#---------------------------------------------------------------------------

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    $self->{_allow} = {};

    if( defined $args{allow} ) {
        for my $allowed ( split m{\W+}mx, lc $args{allow} ) {
            $self->{_allow}->{$allowed} = 1;
        }
    }

    return $self;
}

#---------------------------------------------------------------------------

sub violates {

    my ( $self, $elem, $doc ) = @_;
    return if $elem->type() ne 'no' || $elem->pragma() ne 'warnings';

    #Arguments to 'no warnings' are usually a list of literals or a
    #qw() list.  Rather than trying to parse the various PPI elements,
    #I just use a regext to split the statement into words.  This is
    #kinda lame, but it does the trick for now.

    my $stmnt = $elem->statement() || return;
    my @words = split m{ [^a-z]+ }mx, $stmnt;
    @words = grep { $_ !~ m{ qw|no|warnings }mx } @words;
    return if all { exists $self->{_allow}->{$_} } @words;

    #If we get here, then it must be a violation
    return Perl::Critic::Violation->new( $desc,
                                         $expl,
                                         $elem->location(),
                                         $self->get_severity(), );
}

1;

__END__

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::TestingAndDebugging::ProhibitWarningsDisabling

=head1 DESCRIPTION

=head1 SEE ALSO

L<Perl::Critic::Policy::TestingAndDebugging::RequirePackageWarnings>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module

=cut
