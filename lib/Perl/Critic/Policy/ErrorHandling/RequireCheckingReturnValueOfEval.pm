##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::ErrorHandling::RequireCheckingReturnValueOfEval;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw< :booleans :severities hashify >;
use base 'Perl::Critic::Policy';

our $VERSION = '1.087';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => 'Return value of eval not tested.';
Readonly::Scalar my $EXPL =>
    q<You can't depend upon the value of $@/$EVAL_ERROR to tell whether an eval failed.>;

Readonly::Hash my %BOOLEAN_OPERATORS => hashify qw< || && // or and >;
Readonly::Hash my %POSTFIX_OPERATORS =>
    hashify qw< for foreach if unless while until >;

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                 }
sub default_severity     { return $SEVERITY_MEDIUM   }
sub default_themes       { return qw( core bugs )    }
sub applies_to           { return 'PPI::Token::Word' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

warn "\n", $elem->statement(), q< statement on >, __LINE__, "\n";
    return if $elem->content() ne 'eval';

    my $evaluated = $elem->snext_sibling() or return; # Nothing to eval!

warn 'line: ', __LINE__, "\n";
    return if _is_in_condition_or_for_loop($elem);
warn 'line: ', __LINE__, "\n";
    return if _is_in_postfix_expression($elem);
warn 'line: ', __LINE__, "\n";

    my $following = $evaluated->snext_sibling();
    if (
            $following
        and $following->isa('PPI::Token::Operator')
        and $BOOLEAN_OPERATORS{ $following->content() }
    ) {
        return;
    }

warn 'line: ', __LINE__, "\n";
    return $self->violation($DESC, $EXPL, $elem);
}

#-----------------------------------------------------------------------------

sub _is_in_condition_or_for_loop {
    my ($elem) = @_;

    my $parent = $elem->parent();
    while ($parent) {
        return $TRUE if $parent->isa('PPI::Structure::Condition');
        return $TRUE if $parent->isa('PPI::Structure::ForLoop');
        $parent = $parent->parent();
    }

    return;
}

#-----------------------------------------------------------------------------

sub _is_in_postfix_expression {
    my ($elem) = @_;

    my $previous = $elem->sprevious_sibling();
    while ($previous) {
warn $previous;
        if (
                $previous->isa('PPI::Token::Word')
            and $POSTFIX_OPERATORS{ $previous->content() }
        ) {
            return $TRUE
        }
        $previous = $previous->sprevious_sibling();
    }

    return;
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ErrorHandling::RequireCheckingReturnValueOfEval - You can't depend upon the value of C<$@>/C<$EVAL_ERROR> to tell whether an C<eval> failed.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic> distribution.


=head1 DESCRIPTION

TODO


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 AUTHOR

Elliot Shank C<< <perl@galumph.com> >>

=head1 COPYRIGHT

Copyright (c) 2008 Elliot Shank.  All rights reserved.

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
