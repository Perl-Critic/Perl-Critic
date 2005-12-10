#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
########################################################################

package Perl::Critic::Policy::Subroutines::ProhibitExcessComplexity;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.13_01';
$VERSION = eval $VERSION;    ## no critic

#---------------------------------------------------------------------------

my $expl = q{Consider refactoring};

my %logic_ops = (
   '&&'  =>  1, '||'  => 1,
   '||=' =>  1, '&&=' => 1,
   'or'  =>  1, 'and' => 1,
   'xor' =>  1, '?'   => 1,
   '<<=' =>  1, '>>=' => 1,
);

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_MEDIUM }
sub applies_to { return 'PPI::Statement::Sub' }

#---------------------------------------------------------------------------

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;
    $self->{_max_maccabe} = $args{max_maccabe} || 7;
    return $self;
}

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    #Count up all the conditional statements
    my $if_nodes = $elem->find('PPI::Statement::Conditional') || [];
    my $count = @{ $if_nodes };

    #Count up the conditional (logical) operators
    my $op_nodes = $elem->find('PPI::Token::Operator') || [];
    $count += grep { exists $logic_ops{$_} }  @{ $op_nodes};

    if ( $count > $self->{_max_maccabe} ) {

        my $desc = qq{Subroutine with high complexity score ($count)};
        return Perl::Critic::Violation->new( $desc, $expl,
                                             $elem->location(),
                                             $self->get_severity(), );
    }
    return; #ok!
}

1;

__END__

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::ProhibitExcessComplexity

=head1 DESCRIPTION

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
