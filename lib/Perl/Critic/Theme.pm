package Perl::Critic::Theme;

use 5.006001;
use strict;
use warnings;
use English qw(-no_match_vars);
use Readonly;

use Exporter 'import';

use List::MoreUtils qw(any);

use Perl::Critic::Utils qw{ :characters :data_conversion };
use Perl::Critic::Exception::Fatal::Internal qw{ &throw_internal };
use Perl::Critic::Exception::Configuration::Option::Global::ParameterValue
    qw{ &throw_global_value };

#-----------------------------------------------------------------------------

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Array our @EXPORT_OK => qw{
    $RULE_INVALID_CHARACTER_REGEX
    cook_rule
};

#-----------------------------------------------------------------------------

Readonly::Scalar our $RULE_INVALID_CHARACTER_REGEX =>
    qr/ ( [^()\s\w\d+\-*&|!] ) /xms;

#-----------------------------------------------------------------------------

Readonly::Scalar my $CONFIG_KEY => 'theme';

#-----------------------------------------------------------------------------

sub new {

    my ( $class, %args ) = @_;
    my $self = bless {}, $class;
    $self->_init( %args );
    return $self;
}

#-----------------------------------------------------------------------------

sub _init {

    my ($self, %args) = @_;
    my $rule = $args{-rule} || $EMPTY;

    if ( $rule =~ m/$RULE_INVALID_CHARACTER_REGEX/xms ) {
        throw_global_value
            option_name     => $CONFIG_KEY,
            option_value    => $rule,
            message_suffix => qq{contains an invalid character: "$1".};
    }

    $self->{_rule} = cook_rule( $rule );

    return $self;
}

#-----------------------------------------------------------------------------

sub rule {
    my $self = shift;
    return $self->{_rule};
}

#-----------------------------------------------------------------------------

sub policy_is_thematic {

    my ($self, %args) = @_;
    my $policy = $args{-policy}
        || throw_internal 'The -policy argument is required';
    ref $policy
        || throw_internal 'The -policy must be an object';

    my $rule = $self->{_rule} or return 1;
    my %themes = hashify( $policy->get_themes() );

    # This bit of magic turns the rule into a perl expression that can be
    # eval-ed for truth.  Each theme name in the rule is translated to 1 or 0
    # if the $policy belongs in that theme.  For example:
    #
    # 'bugs && (pbp || core)'  ...could become... '1 && (0 || 1)'

    my $as_code = $rule; #Making a copy, so $rule is preserved
    $as_code =~ s/ ( [\w\d]+ ) /exists $themes{$1} || 0/gexms;
    my $is_thematic = eval $as_code;  ## no critic (ProhibitStringyEval)

    if ($EVAL_ERROR) {
        throw_global_value
            option_name     => $CONFIG_KEY,
            option_value    => $rule,
            message_suffix  => q{contains a syntax error.};
    }

    return $is_thematic;
}

#-----------------------------------------------------------------------------

sub cook_rule {
    my ($raw_rule) = @_;
    return if not defined $raw_rule;

    #Translate logical operators
    $raw_rule =~ s{\b not \b}{!}ixmsg;     # "not" -> "!"
    $raw_rule =~ s{\b and \b}{&&}ixmsg;    # "and" -> "&&"
    $raw_rule =~ s{\b or  \b}{||}ixmsg;    # "or"  -> "||"

    #Translate algebra operators (for backward compatibility)
    $raw_rule =~ s{\A [-] }{!}ixmsg;     # "-" -> "!"     e.g. difference
    $raw_rule =~ s{   [-] }{&& !}ixmsg;  # "-" -> "&& !"  e.g. difference
    $raw_rule =~ s{   [*] }{&&}ixmsg;    # "*" -> "&&"    e.g. intersection
    $raw_rule =~ s{   [+] }{||}ixmsg;    # "+" -> "||"    e.g. union

    my $cooked_rule = lc $raw_rule;  #Is now cooked!
    return $cooked_rule;
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Theme - Construct thematic sets of policies.


=head1 DESCRIPTION

This is a helper class for evaluating theme expressions into sets of
Policy objects.  There are no user-serviceable parts here.


=head1 INTERFACE SUPPORT

This is considered to be a non-public class.  Its interface is subject
to change without notice.


=head1 METHODS

=over

=item C<< new( -rule => $rule_expression ) >>

Returns a reference to a new Perl::Critic::Theme object.  C<-rule> is
a string expression that evaluates to true or false for each Policy..
See L<"THEME RULES"> for more information.


=item C<< policy_is_thematic( -policy => $policy ) >>

Given a reference to a L<Perl::Critic::Policy|Perl::Critic::Policy>
object, this method returns evaluates the rule against the themes that
are associated with the Policy.  Returns 1 if the Policy satisfies the
rule, 0 otherwise.


=item C< rule() >

Returns the rule expression that was used to construct this Theme.
The rule may have been translated into a normalized expression.  See
L<"THEME RULES"> for more information.

=back


=head2 THEME RULES

A theme rule is a simple boolean expression, where the operands are
the names of any of the themes associated with the
Perl::Critic::Polices.

Theme names can be combined with logical operators to form arbitrarily
complex expressions.  Precedence is the same as normal mathematics,
but you can use parentheses to enforce precedence as well.  Supported
operators are:

   Operator    Altertative    Example
   ----------------------------------------------------------------
   &&          and            'pbp && core'
   ||          or             'pbp || (bugs && security)'
   !           not            'pbp && ! (portability || complexity)

See L<Perl::Critic/"CONFIGURATION"> for more information about
customizing the themes for each Policy.


=head1 SUBROUTINES

=over

=item C<cook_rule( $rule )>

Standardize a rule into a almost executable Perl code.  The "almost"
comes from the fact that theme names are left as is.


=back


=head1 CONSTANTS

=over

=item C<$RULE_INVALID_CHARACTER_REGEX>

A regular expression that will return the first character in the
matched expression that is not valid in a rule.


=back


=head1 AUTHOR

Jeffrey Ryan Thalhammer  <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2006-2011 Imaginative Software Systems

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

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
