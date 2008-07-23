##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/Perl-Critic/lib/Perl/Critic/Policy/ValuesAndExpressions/RequireInterpolationOfMetachars.pm $
#     $Date: 2008-07-07 09:09:13 -0700 (Mon, 07 Jul 2008) $
#   $Author: clonezone $
# $Revision: 2537 $
##############################################################################

package Perl::Critic::Policy::ValuesAndExpressions::RequireConstantOnLeftSideOfEquality;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

#-----------------------------------------------------------------------------

our $VERSION = '1.090';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Constant value on right side of equality};
Readonly::Scalar my $EXPL => q{Putting the constant on the left exposes typos};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                    }
sub default_severity     { return $SEVERITY_LOW         }
sub default_themes       { return qw(core cosmetic)     }
sub applies_to           { return qw(PPI::Token::Operator) }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    return if !( $elem eq q<==> || $elem eq q<eq>);

    my $right_sib = $elem->snext_sibling() || return;
    my $left_sib = $elem->sprevious_sibling() || return;

    if (!_is_constant_like($left_sib) && _is_constant_like($right_sib)) {
        return $self->violation($DESC, $EXPL, $right_sib);
    }

    return; # ok!
}

#-----------------------------------------------------------------------------

sub _is_constant_like {
    my $elem = shift;
    return 1 if $elem->isa('PPI::Token::Number');
    return 1 if $elem->isa('PPI::Token::Quote');
    return 0;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::RequireConstantOnLeftSideOfEquality - Putting the constant value on the left side of an equality exposes typos.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

This policy warns you if you put a constant value (i.e. a literal number or
some string) on the right side of a C<==> operator when there is a variable or
some other lvalue on the left side.  In a nutshell:

  if($foo == 42){}    # not ok
  if(42 == $foo){}    # ok

  if($foo eq 'bar'){} # not ok
  if('bar' eq $foo){} # ok

The rationale is that sometimes you might mistype C<=> instead of C<==>, and
if you're in the habit of putting the constant value on the left side of the
equality, then Perl will give you a compile-time warning.  Perhaps this is
best explained with an example:

  if ($foo == 42){}  # This is what I want it to do.
  if ($foo = 42){}   # But suppose this is what I actually type.
  if (42 = $foo){}   # If I had (mis)typed it like this, then Perl gives a warning.
  if (42 == $foo){}  # So this is what I should have attempted to type.

So this Policy doesn't actually tell you if you've mistyped C<=> instead of
C<==>.  Rather, it encourages you to write your expressions in a certain way
so that Perl can warn you when you mistyped it.

The C<eq> operator is not prone to the same type of typo as the C<==>
operator, but this Policy still treats it the same way.  Therefore, the rule
is consistently applied to all equality operators, which helps you to get into
the habit of writing compliant expressions faster.


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2005-2008 Jeffrey Ryan Thalhammer.  All rights reserved.

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
