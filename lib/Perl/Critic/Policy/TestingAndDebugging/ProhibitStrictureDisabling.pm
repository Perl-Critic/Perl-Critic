#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
########################################################################

package Perl::Critic::Policy::TestingAndDebugging::ProhibitStrictureDisabling;

use strict;
use warnings;
use List::MoreUtils qw(any);
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.13_01';
$VERSION = eval $VERSION;    ## no critic

#---------------------------------------------------------------------------

my $desc = q{Stricture disabled};
my $expl = [ 429 ];

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGHEST }
sub applies_to { return 'PPI::Statement::Include' }

#---------------------------------------------------------------------------

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    $self->{_allow} = [];

    if( defined $args{allow} ) {
        $self->{_allow} = [ split m{\s+}mx, $args{allow} ];
    }

    return $self;
}

#---------------------------------------------------------------------------

sub violates {

    my ( $self, $elem, $doc ) = @_;
    return if $elem->type() ne 'no' || $elem->pragma() ne 'strict';

    my $nodes_ref = $elem->find( \&_wanted );
    if ( $nodes_ref && @{ $self->{_allow} } ) {
        for my $node ( @{ $nodes_ref } ) {
            return if any { $node =~ m{\b $_ \b}imx }  @{ $self->{_allow} };
        }
    }

    #If we get here, then it must be a violation
    return Perl::Critic::Violation->new( $desc,
                                         $expl,
                                         $elem->location(),
                                         $self->get_severity(), );
}

#---------------------------------------------------------------------------

sub _wanted {
    my ($doc, $elem) = @_;
    return    $elem->isa('PPI::Token::Quote')
           || $elem->isa('PPI::Token::QuoteLike');
}

1;

__END__

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::TestingAndDebugging::ProhibitStrictureDisabling

=head1 DESCRIPTION

=head1 SEE ALSO

L<Perl::Critic::Policy::TestingAndDebugging::RequirePackageStricture>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module

=cut
