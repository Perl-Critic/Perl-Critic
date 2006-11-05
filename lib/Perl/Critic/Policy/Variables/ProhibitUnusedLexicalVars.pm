##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
##############################################################################

package Perl::Critic::Policy::Variables::ProhibitUnusedLexicalVars;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.21;

#---------------------------------------------------------------------------

my $desc = q{Unused lexical variable};
my $expl = q{Consider removing it, or using "undef"};

sub default_severity { return $SEVERITY_LOW;   }
sub default_themes   { return qw(readability)  }
sub applies_to       { return 'PPI::Document'  }

#---------------------------------------------------------------------------

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;
    $self->{_exclude_vars} = [ default_exclude_vars() ];

    # set config, if defined
    if ( defined $args{exclude_vars} ) {
        my @excludes = split m{ \s+ }mx, $args{exclude_vars};
        $self->{exclude_vars} = [ map { lc $_ } @excludes ];
    }

    return $self;
}

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my $declares_aref = $doc->find('PPI::Statement::Variable');
    return if not $declares_aref;


    my %exclude_vars = map { $_ => 1 } @{ $self->{_exclude_vars} };
    my %var_lookup = ();
    my @violations = ();


    for my $var_stmt ( @{ $declares_aref } ) {
        next if $var_stmt->type() ne 'my';

        foreach my $var_name ( $var_stmt->variables() ) {
          next if exists $exclude_vars{$var_name};
          $var_lookup{$var_name} ||= [];
          push @{ $var_lookup{$var_name} }, $var_stmt;
        }
    }

    my $vars_aref = $doc->find('PPI::Token::Symbol') || [];

  VARIABLE:
    for my $variable ( @{ $vars_aref } ) {
        next VARIABLE if $self->_is_declaration( $variable );

        my $symbol = $variable->symbol();
        next VARIABLE if not exists $var_lookup{$symbol};

        my $parent = $variable->parent();

      PARENT:
        while ( defined $parent ) {
            for my $idx ( 0 .. $#{$var_lookup{$symbol}} ) {
                my $declare = $var_lookup{$symbol}->[$idx]->parent();
                if ( $declare eq $parent ) {
                    splice @{ $var_lookup{$symbol} }, $idx, 1;
                    last PARENT;
                }
            }
            $parent = $parent->parent();
        }
    }


    foreach my $declare_aref (values %var_lookup) {
       foreach my $elem (@{ $declare_aref }) {
           push @violations, $self->violation( $desc, $expl, $elem );
       }
    }

    return @violations;
}

#---------------------------------------------------------------------------

sub _is_declaration {
    my ( $self, $elem ) = @_;

    my $symbol = $elem->symbol();
    my $stmnt  = $elem->statement();
    return 1 if $stmnt->isa('PPI::Statement::Variable')
        && grep { $_ eq $symbol } $stmnt->variables();

    my $parent = $stmnt->parent();
    return 1 if $stmnt->isa('PPI::Statement::Expression')
        && $parent->isa('PPI::Structure::List')
        && $parent->parent()->isa('PPI::Statement::Variable');

    return 0;
}

#---------------------------------------------------------------------------

sub default_exclude_vars { return qw( $self ); }

1;

__END__

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Variables::ProhibitUnusedLexicalVars

=head1 DESCRIPTION

This policy requires all lexically declared variables to be used at
least once within their declared scope.  Perl has built in warnings
for unused variables declared via C<local> and C<our>, and this module
extends the same treatment to variables declared via C<my>.

  # not ok - $arg2 is never used

  sub foo {
    my ( $arg1, $arg2 ) = @_;
    print "$arg1\n";
  }

  # ok - all variables are used

  sub foo {
    my ( $arg1, $arg2 ) = @_;
    print "$arg1\n";
    bar($arg2);
  }

=head1 DEFAULTS

By default, the C<$self> variable is exempt from this policy.

=head1 CONSTRUCTOR

This policy accepts an additional C<'exclude_vars'> option in the
C<new> method.  This can be configured in the F<.perlcriticrc> file
like this:

 [Variables::ProhibitUnusedLexicalVars]
 exclude_vars = $foo | @bar | %baz

=head1 SUBROUTINES

=over 8

=item default_exclude_vars()

Returns a list of the default lexical variables that are excluded from
this policy.

=back

=head1 AUTHOR

Peter Guzis <pguzis@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006 Peter Guzis.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module

=cut
