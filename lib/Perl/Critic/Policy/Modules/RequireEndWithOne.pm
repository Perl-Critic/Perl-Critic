package Perl::Critic::Policy::Modules::RequireEndWithOne;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.13';
$VERSION = eval $VERSION;    ## no critic

my $expl = q{Must end with a recognizable true value};
my $desc = q{Module does not end with '1;'};

#----------------------------------------------------------------------------

sub applies_to {
    return 'PPI::Document';
}

sub violates {
    my ( $self, $elem, $doc ) = @_;

    return if is_script($doc);

    # Last statement should be just "1;"
    my @significant = $doc->schildren();
    @significant = grep {!$_->isa('PPI::Statement::End') && !$_->isa('PPI::Statement::Data')} @significant;
    my $match = $significant[-1];
    if ($match && (ref $match) eq 'PPI::Statement' && $match eq '1;')
    {
       return;
    }

    return Perl::Critic::Violation->new( $desc, $expl, $match->location() );
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::Modules::RequireEndWithOne

=head1 DESCRIPTION

All files included via C<use> or C<require> must end with a true value
to indicate to the caller that the include was successful.  The
standard practice is to conclude your .pm files with C<1;>, but some
authors like to get clever and return some other true value like
C<return "Club sandwich";>.  We cannot tolerate such frivolity!  OK, we
can, but we don't recommend it since it confuses the newcomers.

=head1 AUTHOR

Chris Dolan C<cdolan@cpan.org>

Some portions cribbed from
L<Perl::Critic::Policy::Modules::RequireExplicitPackage>.

=head1 COPYRIGHT

Copyright (c) 2005 Chris Dolan and Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
