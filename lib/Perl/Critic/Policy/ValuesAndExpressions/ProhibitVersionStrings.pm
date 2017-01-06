package Perl::Critic::Policy::ValuesAndExpressions::ProhibitVersionStrings;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Version string used};
Readonly::Scalar my $EXPL => q{Use a real number instead};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                        }
sub default_severity     { return $SEVERITY_MEDIUM          }
sub default_themes       { return qw(core pbp maintenance)  }
sub applies_to           { return 'PPI::Statement::Include' }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, undef) = @_;

    my $version;

    if ( my $module = $elem->module() ) {
        return if $module eq 'lib';

        $version = $elem->module_version();
    } else {
        $version = $elem->schild(1);
    }

    return if not defined $version;
    return if not $version->isa('PPI::Token::Number::Version');

    return $self->violation($DESC, $EXPL, $elem);
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitVersionStrings - Don't use strings like C<v1.4> or C<1.4.5> when including other modules.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Whenever you C<use> or C<require> a module, you can specify a minimum
version requirement.  To ensure compatibility with older Perls, this
version number should be expressed as a floating-point number.  Do not
use v-strings or three-part numbers.  The Perl convention for
expressing version numbers as floats is: version + (patch level /
1000).

    use Foo v1.2    qw(foo bar);  # not ok
    use Foo 1.2.03  qw(foo bar);  # not ok
    use Foo 1.00203 qw(foo bar);  # ok


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


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
