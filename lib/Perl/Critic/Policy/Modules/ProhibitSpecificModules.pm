package Perl::Critic::Policy::Modules::ProhibitSpecificModules;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.13';
$VERSION = eval $VERSION;    ## no critic

my $expl = q{Find an alternative module};
my $desc = q{Prohibited module used};

#----------------------------------------------------------------------------

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;

    #Set config, if defined
    if ( defined $args{modules} ) {
        for my $module ( split m{ \s+ }mx, $args{modules} ) {
            $self->{_evil_modules}->{$module} = 1;
        }
    }
    return $self;
}

sub violates {
    my ( $self, $elem, $doc ) = @_;
    $elem->isa('PPI::Statement::Include') || return;
    if ( exists $self->{_evil_modules}->{ $elem->module() } ) {
        return Perl::Critic::Violation->new( $desc, $expl, $elem->location() );
    }
    return;    #ok!
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::Modules::ProhibitSpecificModules

=head1 DESCRIPTION

Use this policy if you wish to prohibit the use of certain modules.
These may be modules that you feel are deprecated, buggy, unsupported,
insecure, or just don't like.

=head1 CONSTRUCTOR

This policy accepts an additional key-value pair in the C<new> method.
The key should be 'modules' and the value is a string of
space-delimited fully qualified module names.  These can be configured in the
F<.perlcriticrc> file like this:

 [Modules::ProhibitSpecificModules]
 modules = Getopt::Std  Autoload

By default, there aren't any prohibited modules (although I can think
of a few that should be).

=head1 NOTES

Note that this policy doesn't apply to pragmas.  Future versions may
allow you to specify an alternative for each prohibited module, which
can be suggested by L<Perl::Critic>.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
