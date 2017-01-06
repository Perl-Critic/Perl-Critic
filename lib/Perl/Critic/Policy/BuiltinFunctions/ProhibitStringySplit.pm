package Perl::Critic::Policy::BuiltinFunctions::ProhibitStringySplit;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :characters :severities :classification :ppi };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{String delimiter used with "split"};
Readonly::Scalar my $EXPL => q{Express it as a regex instead};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                    }
sub default_severity     { return $SEVERITY_LOW         }
sub default_themes       { return qw(core pbp cosmetic certrule ) }
sub applies_to           { return 'PPI::Token::Word'    }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem->content() ne 'split';
    return if ! is_function_call($elem);

    my @args = parse_arg_list($elem);
    my $pattern = @args ? $args[0]->[0] : return;

    if ( $pattern->isa('PPI::Token::Quote') && $pattern->string() ne $SPACE ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }

    return;  #ok
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::BuiltinFunctions::ProhibitStringySplit - Write C<split /-/, $string> instead of C<split '-', $string>.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

The C<split> function always interprets the PATTERN argument as a
regular expression, even if you specify it as a string.  This causes
much confusion if the string contains regex metacharacters.  So for
clarity, always express the PATTERN argument as a regex.

    $string = 'Fred|Barney';
    @names = split '|', $string; #not ok, is ('F', 'r', 'e', 'd', '|', 'B', 'a' ...)
    @names = split m/[|]/, $string; #ok, is ('Fred', Barney')

When the PATTERN is a single space the C<split> function has special
behavior, so Perl::Critic forgives that usage.  See C<"perldoc -f
split"> for more information.


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 SEE ALSO

L<Perl::Critic::Policy::ControlStrucutres::RequireBlockGrep|Perl::Critic::Policy::ControlStrucutres::RequireBlockGrep>

L<Perl::Critic::Policy::ControlStrucutres::RequireBlockMap|Perl::Critic::Policy::ControlStrucutres::RequireBlockMap>


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2005-2011 Imaginative Software Systems.  All rights reserved.

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
