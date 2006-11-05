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


    my %exclude_vars = hashify( @{ $self->{_exclude_vars} } );
    my %var_lookup = ();


    for my $var_stmt ( @{ $declares_aref } ) {
        next if $var_stmt->type() ne 'my';

        # Find the ancestor of the variable declaraion.  For variables
        # decared inside a conditional, we have to go up two levels.

        foreach my $var_name ( $var_stmt->variables() ) {
          next if exists $exclude_vars{$var_name};
          $var_lookup{$var_name} ||= [];
          push @{ $var_lookup{$var_name} }, $var_stmt;
        }
    }

    my $symbols_ref = $doc->find('PPI::Token::Symbol') || [];

  SYMBOL:
    for my $symbol ( @{ $symbols_ref } ) {
        next SYMBOL if _is_in_declaration( $symbol );

        my $symbol_name = $symbol->symbol();
        next SYMBOL if not exists $var_lookup{$symbol_name};

        my $symbol_parent = $symbol->parent();

      PARENT:
        while ( defined $symbol_parent ) {
            for my $idx ( 0 .. $#{$var_lookup{$symbol_name}} ) {
                my $declare_parent = $var_lookup{$symbol_name}->[$idx]->parent();
                if ($declare_parent->isa('PPI::Structure::Condition')) {
                    $declare_parent = $declare_parent->parent();
                }

                if ( $symbol_parent eq $declare_parent ) {
                    splice @{ $var_lookup{$symbol_name} }, $idx, 1;
                    last PARENT;
                }
            }
            $symbol_parent = $symbol_parent->parent();
        }
    }


    my @violations = ();
    foreach my $declare_aref (values %var_lookup) {
       foreach my $elem (@{ $declare_aref }) {
           push @violations, $self->violation( $desc, $expl, $elem );
       }
    }

    return @violations;
}

#---------------------------------------------------------------------------

sub _is_in_declaration {
    my ( $elem ) = @_;

    my $symbol = $elem->symbol();
    my $stmnt  = $elem->statement();
    return 1 if $stmnt->isa('PPI::Statement::Variable')
        && grep { $_ eq $symbol } $stmnt->variables();

    my $parent = $stmnt->parent();
    my $grand_parent = $parent->parent();
    return 1 if $stmnt->isa('PPI::Statement::Expression')
        && $parent->isa('PPI::Structure::List')
            && $grand_parent->isa('PPI::Statement::Variable')
                && grep { $_ eq $symbol } $grand_parent->variables();

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
