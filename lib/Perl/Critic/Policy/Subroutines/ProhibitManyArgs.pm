package Perl::Critic::Policy::Subroutines::ProhibitManyArgs;

use 5.006001;
use strict;
use warnings;
use Readonly;

use File::Spec;
use English qw(-no_match_vars);
use Carp;

use Perl::Critic::Utils qw{ :booleans :severities split_nodes_on_comma };
use base 'Perl::Critic::Policy';

our $VERSION = '1.140';

#-----------------------------------------------------------------------------

Readonly::Scalar my $AT     => q{@};
Readonly::Scalar my $AT_ARG => q{@_};     ## no critic (InterpolationOfMetachars)
Readonly::Scalar my $CLASS  => q{$class}; ## no critic (InterpolationOfMetachars)
Readonly::Scalar my $SELF   => q{$self};  ## no critic (InterpolationOfMetachars)

Readonly::Scalar my $DESC => q{Too many arguments};
Readonly::Scalar my $EXPL => [182];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'max_arguments',
            description     =>
                'The maximum number of arguments to allow a subroutine to have.',
            default_string  => '5',
            behavior        => 'integer',
            integer_minimum => 1,
        },
        {
            name            => 'skip_object',
            description     => q[Don't count $self or $class first argument], ## no critic (InterpolationOfMetachars)
            default_string  => '0',
            behavior        => 'boolean',
        },
    );
}

sub default_severity     { return $SEVERITY_MEDIUM           }
sub default_themes       { return qw( core pbp maintenance ) }
sub applies_to           { return 'PPI::Statement::Sub'      }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    # forward declaration?
    return if !$elem->block;

    my $num_args;
    if ($elem->prototype) {
        my $prototype = $elem->prototype();
        $prototype =~ s/ \\ [[] .*? []] /*/smxg;    # Allow for grouping
        $num_args = $prototype =~ tr/$@%&*_+/$@%&*_+/;    # RT 56627
    } else {
        $num_args = _count_args($self->{_skip_object}, $elem->block->schildren);
    }

    if ($self->{_max_arguments} < $num_args) {
       return $self->violation( $DESC, $EXPL, $elem );
    }
    return;  # OK
}

sub _count_args {
    my ($skip_object, @statements) = @_;

    # look for these patterns:
    #    " ... = @_;"    => then examine previous variable list
    #    " ... = shift;" => counts as one arg, then look for more

    return 0 if !@statements;  # no statements

    my $statement = shift @statements;
    my @elements = $statement->schildren();
    my $operand = pop @elements;
    while ($operand && $operand->isa('PPI::Token::Structure') && q{;} eq $operand->content()) {
       $operand = pop @elements;
    }
    return 0 if !$operand;

    #print "pulled off last, remaining: '@elements'\n";
    my $operator = pop @elements;
    return 0 if !$operator;
    return 0 if !$operator->isa('PPI::Token::Operator');
    return 0 if q{=} ne $operator->content();

    if ($operand->isa('PPI::Token::Magic') && $AT_ARG eq $operand->content()) {
        return _count_list_elements($skip_object, @elements);
    } elsif ($operand->isa('PPI::Token::Word') && 'shift' eq $operand->content()) {
        my $count_first = $skip_object ? !_is_object_arg(pop @elements) : 1;
        return $count_first + _count_args(0, @statements);  # only check for object on first argument
    }

    return 0;
}

sub _count_list_elements {
   my ($skip_object, @elements) = @_;

   my $list = pop @elements;
   return 0 if !$list;
   return 0 if !$list->isa('PPI::Structure::List');
   my @inner = $list->schildren;
   if (1 == @inner && $inner[0]->isa('PPI::Statement::Expression')) {
      @inner = $inner[0]->schildren;
   }
   my @args = split_nodes_on_comma(@inner);
   return scalar @args if !$skip_object || !@args;;

   # Check if first argument is $self/$class
   my $first_ref = $args[0];
   return scalar @args if scalar @{ $first_ref } != 1;  # more complex than simple scalar
   return scalar @args - !!_is_object_arg($first_ref->[0]);
}

sub _is_object_arg {
    my ($symbol) = @_;
    return 0 if !$symbol;
    return 0 if !$symbol->isa('PPI::Token::Symbol');
    return $SELF eq $symbol->content() || $CLASS eq $symbol->content();
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords refactored

=head1 NAME

Perl::Critic::Policy::Subroutines::ProhibitManyArgs - Too many arguments.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Subroutines that expect large numbers of arguments are hard to use
because programmers routinely have to look at documentation to
remember the order of those arguments.  Many arguments is often a sign
that a subroutine should be refactored or that an object should be
passed to the routine.


=head1 CONFIGURATION

By default, this policy allows up to 5 arguments without warning.  To
change this threshold, put entries in a F<.perlcriticrc> file like
this:

  [Subroutines::ProhibitManyArgs]
  max_arguments = 6

To ignore C<$self> or C<$class> in your argument count, as long as they're
the first argument, use:

  [Subroutines::ProhibitManyArgs]
  skip_object = 1


=head1 CAVEATS

PPI doesn't currently detect anonymous subroutines, so we don't check
those.  This should just work when PPI gains that feature.

We don't check for C<@ARG>, the alias for C<@_> from English.pm.
That's deprecated anyway.


=head1 CREDITS

Initial development of this policy was supported by a grant from the
Perl Foundation.


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2007-2019 Chris Dolan.  Many rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
