package Perl::Critic::Policy::Modules::RequireNoMatchVarsWithUseEnglish;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw< :characters :severities >;
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL =>
    q{"use English" without the '-no_match_vars' argument degrades performance.'};
Readonly::Scalar my $DESC => q{"use English" without '-no_match_vars' argument};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                        }
sub default_severity     { return $SEVERITY_LOW             }
sub default_themes       { return qw( core performance )    }
sub applies_to           { return 'PPI::Statement::Include' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    # "require"ing English is kind of useless.
    return if $elem->type() ne 'use';
    return if $elem->module() ne 'English';

    my @elements = $elem->schildren();
    shift @elements; # dump "use"
    shift @elements; # dump "English"

    if (not @elements) {
        return $self->violation($DESC, $EXPL, $elem);
    }

    _skip_version_number( \@elements );

    @elements = _descend_into_parenthesized_list_if_present(@elements);

    if (not @elements) {
        return $self->violation($DESC, $EXPL, $elem);
    }

    my $current_element = $elements[0];

    while ( $current_element ) {
        if ( $current_element->isa('PPI::Token::Quote') ) {
            return if $current_element->string() eq '-no_match_vars';
        }
        elsif ( $current_element->isa('PPI::Token::QuoteLike::Words') ) {
            return if $current_element->content() =~ m/-no_match_vars \b/xms;
        }
        elsif (
                not $current_element->isa('PPI::Token::Operator')
            or  $current_element->content() ne $COMMA
            and $current_element->content() ne $FATCOMMA
        ) {
            return $self->violation($DESC, $EXPL, $elem);
        }

        shift @elements;
        $current_element = $elements[0];
    }

    return $self->violation($DESC, $EXPL, $elem);
}


sub _skip_version_number {
    my ($elements_ref) = @_;

    my $current_element = $elements_ref->[0];

    if ( $current_element->isa('PPI::Token::Number') ) {
        shift @{$elements_ref};
    }
    elsif (
            @{$elements_ref} >= 2
        and $current_element->isa('PPI::Token::Word')
        and $current_element->content() =~ m/\A v \d+ \z/xms
        and $elements_ref->[1]->isa('PPI::Token::Number')
    ) {
        # The above messy conditional necessary due to PPI not handling
        # v-strings.
        shift @{$elements_ref};
        shift @{$elements_ref};
    }

    return;
}

sub _descend_into_parenthesized_list_if_present {
    my @elements = @_;

    return if not @elements;

    my $current_element = $elements[0];

    if ( $current_element->isa('PPI::Structure::List') ) {
        my @grand_children = $current_element->schildren();
        if (not @grand_children) {
            return;
        }

        my $grand_child = $grand_children[0];

        if ( $grand_child->isa('PPI::Statement::Expression') ) {
            my @great_grand_children = $grand_child->schildren();

            if (not @great_grand_children) {
                return;
            }

            return @great_grand_children;
        }
        else {
            return @grand_children;
        }
    }

    return @elements;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Modules::RequireNoMatchVarsWithUseEnglish - C<use English> must be passed a C<-no_match_vars> argument.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Due to unfortunate history, if you use the L<English|English> module
but don't pass in a C<-no_match_vars> argument, all regular
expressions in the entire program, not merely the module in question,
suffer a significant performance penalty, even if you only import a
subset of the variables.

    use English;                              # not ok
    use English '-no_match_vars';             # ok
    use English qw< $ERRNO -no_match_vars >;  # ok
    use English qw($OS_ERROR);                # not ok

In the last example above, while the match variables aren't loaded
into your namespace, they are still created in the C<English>
namespace and you still pay the cost.


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 AUTHOR

Elliot Shank C<< <perl@galumph.com> >>


=head1 COPYRIGHT

Copyright (c) 2008-2011 Elliot Shank.

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
