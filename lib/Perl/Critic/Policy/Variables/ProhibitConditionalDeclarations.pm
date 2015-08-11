package Perl::Critic::Policy::Variables::ProhibitConditionalDeclarations;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :data_conversion };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Variable declared in conditional statement};
Readonly::Scalar my $EXPL => q{Declare variables outside of the condition};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                         }
sub default_severity     { return $SEVERITY_HIGHEST          }
sub default_themes       { return qw( core bugs )            }
sub applies_to           { return 'PPI::Statement::Variable' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    return if $elem->type() eq 'local';

    if ( $elem->find(\&_is_conditional) ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }
    return;    #ok!
}

my @conditionals = qw( if while foreach for until unless );
my %conditionals = hashify( @conditionals );

sub _is_conditional {
    my (undef, $elem) = @_;

    return if !$conditionals{$elem};
    return if ! $elem->isa('PPI::Token::Word');
    return if is_hash_key($elem);
    return if is_method_call($elem);

    return 1;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Variables::ProhibitConditionalDeclarations - Do not write C< my $foo = $bar if $baz; >.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Declaring a variable with a postfix conditional is really confusing.
If the conditional is false, its not clear if the variable will be
false, undefined, undeclared, or what.  It's much more straightforward
to make variable declarations separately.

    my $foo = $baz if $bar;          #not ok
    my $foo = $baz unless $bar;      #not ok
    our $foo = $baz for @list;       #not ok
    local $foo = $baz foreach @list; #not ok


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 AUTHOR

Jeffrey R. Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2006-2011 Chris Dolan.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
