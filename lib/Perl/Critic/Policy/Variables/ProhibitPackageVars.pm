package Perl::Critic::Policy::Variables::ProhibitPackageVars;

use 5.006001;
use strict;
use warnings;

use Readonly;
use Carp qw( carp );

use List::MoreUtils qw(all);

use Perl::Critic::Utils qw{
    :booleans :characters :severities :data_conversion
};
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Package variable declared or used};
Readonly::Scalar my $EXPL => [ 73, 75 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'packages',
            description     => 'The base set of packages to allow variables for.',
            default_string  => 'Data::Dumper File::Find FindBin Log::Log4perl',
            behavior        => 'string list',
        },
        {
            name            => 'add_packages',
            description     => 'The set of packages to allow variables for, in addition to those given in "packages".',
            default_string  => $EMPTY,
            behavior        => 'string list',
        },
    );
}

sub default_severity { return $SEVERITY_MEDIUM            }
sub default_themes   { return qw(core pbp maintenance)    }
sub applies_to       { return qw(PPI::Token::Symbol
                                 PPI::Statement::Variable
                                 PPI::Statement::Include) }

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    my ($self, $config) = @_;

    $self->{_all_packages} = {
        hashify keys %{ $self->{_packages} }, keys %{ $self->{_add_packages} }
    };

    return $TRUE;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    if ( $self->_is_package_var($elem) ||
         _is_our_var($elem)            ||
         _is_vars_pragma($elem) )
       {

        return $self->violation( $DESC, $EXPL, $elem );
    }

    return;  # ok
}

#-----------------------------------------------------------------------------

sub _is_package_var {
    my $self = shift;
    my $elem = shift;
    return if !$elem->isa('PPI::Token::Symbol');
    my ($package, $name) = $elem =~ m{ \A [@\$%] (.*) :: (\w+) \z }xms;
    return if not defined $package;
    return if _all_upcase( $name );
    return if $self->{_all_packages}->{$package};
    return 1;
}

#-----------------------------------------------------------------------------

sub _is_our_var {
    my $elem = shift;
    return if not $elem->isa('PPI::Statement::Variable');
    return if $elem->type() ne 'our';
    return if _all_upcase( $elem->variables() );
    return 1;
}

#-----------------------------------------------------------------------------

sub _is_vars_pragma {
    my $elem = shift;
    return if !$elem->isa('PPI::Statement::Include');
    return if $elem->pragma() ne 'vars';

    # Older Perls don't support the C<our> keyword, so we try to let
    # people use the C<vars> pragma instead, but only if all the
    # variable names are uppercase.  Since there are lots of ways to
    # pass arguments to pragmas (e.g. "$foo" or qw($foo) ) we just use
    # a regex to match things that look like variables names.

    my @varnames = $elem =~ m{ [@\$%&] (\w+) }gxms;

    return if !@varnames;   # no valid variables specified
    return if _all_upcase( @varnames );
    return 1;
}

sub _all_upcase {  ##no critic(ArgUnpacking)
    return all { $_ eq uc $_ } @_; ## no critic ( BuiltinFunctions::ProhibitUselessTopic )
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Variables::ProhibitPackageVars - Eliminate globals declared with C<our> or C<use vars>.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Conway suggests avoiding package variables completely, because they
expose your internals to other packages.  Never use a package variable
when a lexical variable will suffice.  If your package needs to keep
some dynamic state, consider using an object or closures to keep the
state private.

This policy assumes that you're using C<strict vars> so that naked
variable declarations are not package variables by default.  Thus, it
complains you declare a variable with C<our> or C<use vars>, or if you
make reference to variable with a fully-qualified package name.

    $Some::Package::foo = 1;    # not ok
    our $foo            = 1;    # not ok
    use vars '$foo';            # not ok
    $foo = 1;                   # not allowed by 'strict'
    local $foo = 1;             # bad taste, but technically ok.
    use vars '$FOO';            # ok, because it's ALL CAPS
    my $foo = 1;                # ok

In practice though, its not really practical to prohibit all package
variables.  Common variables like C<$VERSION> and C<@EXPORT> need to
be global, as do any variables that you want to Export.  To work
around this, the Policy overlooks any variables that are in ALL_CAPS.
This forces you to put all your exported variables in ALL_CAPS too,
which seems to be the usual practice anyway.


=head1 CONFIGURATION

There is room for exceptions.  Some modules, like the core File::Find
module, use package variables as their only interface, and others like
Data::Dumper use package variables as their most common interface.
These module can be specified from your F<.perlcriticrc> file, and the
policy will ignore them.

    [Variables::ProhibitPackageVars]
    packages = Data::Dumper File::Find FindBin Log::Log4perl

This is the default setting.  Using C<packages =>  will override these
defaults.

You can also add packages to the defaults like so:

    [Variables::ProhibitPackageVars]
    add_packages = My::Package

You can add package C<main> to the list of packages, but that will
only OK variables explicitly in the C<main> package.


=head1 SEE ALSO

L<Perl::Critic::Policy::Variables::ProhibitPunctuationVars|Perl::Critic::Policy::Variables::ProhibitPunctuationVars>

L<Perl::Critic::Policy::Variables::ProhibitLocalVars|Perl::Critic::Policy::Variables::ProhibitLocalVars>


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
