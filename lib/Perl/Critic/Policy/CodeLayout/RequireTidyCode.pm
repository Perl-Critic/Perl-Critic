package Perl::Critic::Policy::CodeLayout::RequireTidyCode;

use strict;
use warnings;
use Perl::Tidy;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.13';
$VERSION = eval $VERSION;    ## no critic

my $desc = q{Code is not tidy};
my $expl = [33];

#----------------------------------------------------------------------------

sub new {
    my ( $class, %args ) = shift;
    my $self = bless {}, $class;
    $self->{_tested} = 0;
    return $self;
}

sub violates {
    my ( $self, $elem, $doc ) = @_;
    return if $self->{_tested};    #Only test this once!
    $self->{_tested} = 1;

    my $source  = "$doc";
    my $dest    = $EMPTY;
    my $logfile = $EMPTY;
    my $errfile = $EMPTY;
    my $stderr  = $EMPTY;

    Perl::Tidy::perltidy(
        source      => \$source,
        destination => \$dest,
        stderr      => \$stderr,
        logfile     => \$logfile,
        errorfile   => \$errfile
    );

    if ($stderr) {

        # Looks like perltidy had problems
        $desc = q{perltidy had errors!!};
    }

    if ( $source eq $dest ) {
        return Perl::Critic::Violation->new( $desc, $expl, [ 0, 0 ] );
    }

    return;    #ok!
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::CodeLayout::RequireTidyCode

=head1 DESCRIPTION

Conway does make specific recommendations for whitespace and
curly-braces in your code, but the most important thing is to adopt a
consistent layout, regardless of the specifics.  And the easiest way
to do that is to use L<Perl::Tidy>.  This policy will complain if
you're code hasn't been run through Perl::Tidy.

=head1 NOTES

Since L<Perl::Tidy> is not widely deployed, this is the only policy in
the L<Perl::Critic> distribution that is not enabled by default.  To
enable it, put this line in your F<.perlcriticrc> file:

 [CodeLayout::RequireTidyCode]

=head1 SEE ALSO

L<Perl::Tidy>


=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
