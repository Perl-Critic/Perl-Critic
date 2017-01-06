package Perl::Critic::Policy::BuiltinFunctions::ProhibitSleepViaSelect;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :ppi };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{"select" used to emulate "sleep"};
Readonly::Scalar my $EXPL => [168];
Readonly::Scalar my $SELECT_ARGUMENT_COUNT => 4;

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                  }
sub default_severity     { return $SEVERITY_HIGHEST   }
sub default_themes       { return qw( core pbp bugs ) }
sub applies_to           { return 'PPI::Token::Word'  }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, undef) = @_;

    return if $elem->content() ne 'select';
    return if ! is_function_call($elem);

    my @arguments = parse_arg_list($elem);
    return if $SELECT_ARGUMENT_COUNT != @arguments;

    foreach my $argument ( @arguments[0..2] ) {
        return if $argument->[0] ne 'undef';
    }

    if ( $arguments[-1]->[0] ne 'undef' ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }

    return; #ok!
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords perlfunc

=head1 NAME

Perl::Critic::Policy::BuiltinFunctions::ProhibitSleepViaSelect - Use L<Time::HiRes|Time::HiRes> instead of something like C<select(undef, undef, undef, .05)>.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Conway discourages the use of C<select()> for performing non-integer
sleeps.  Although documented in L<perlfunc|perlfunc>, it's something
that generally requires the reader to read C<perldoc -f select> to
figure out what it should be doing.  Instead, Conway recommends that
you use the C<Time::HiRes> module when you want to sleep.

    select undef, undef, undef, 0.25;         # not ok

    use Time::HiRes;
    sleep( 0.25 );                            # ok


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 SEE ALSO

L<Time::HiRes|Time::HiRes>.


=head1 AUTHOR

Graham TerMarsch <graham@howlingfrog.com>


=head1 COPYRIGHT

Copyright (c) 2005-2011 Graham TerMarsch.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
