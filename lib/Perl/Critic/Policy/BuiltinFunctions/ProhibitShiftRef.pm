package Perl::Critic::Policy::BuiltinFunctions::ProhibitShiftRef;

use 5.006001;
use strict;
use warnings;
use Readonly;
use version 0.77 ();

use Perl::Critic::Utils qw{ :severities :classification :language };
use base 'Perl::Critic::Policy';

our $VERSION = '1.140';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{\shift used};
Readonly::Scalar my $EXPL => [165];

Readonly::Scalar my $MINIMUM_PERL_VERSION => version->new(5.008008);

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_MEDIUM }
sub default_themes       { return qw( core bugs tests ) }
sub applies_to           { return 'PPI::Token::Word' }

#-----------------------------------------------------------------------------

sub prepare_to_scan_document {
    my ( $self, $document ) = @_;

    # The earliest version tested was 5.8.8
    my $version = $document->highest_explicit_perl_version();
    return !$version || $version >= $MINIMUM_PERL_VERSION;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem->content() ne 'shift';

    my $prev = $elem->sprevious_sibling();
    if ( !$prev ) {

        # If there is no previous token, we are probably nested in a block.
        # Grab the statement and see if it's in a block.  For simplicity, we
        # assume the block only contains a 'shift' statement, which may not be
        # reliable.
        if ( my $stmt = $elem->statement ) {

            my $block = $stmt->parent();
            if ( $block && $block->isa('PPI::Structure::Block') ) {
                $prev = $block->sprevious_sibling();
            }
        }
    }

    if ( $prev && $prev->isa('PPI::Token::Cast') && $prev->content() eq q{\\} ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }

    return;
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=encoding utf8

=head1 NAME

Perl::Critic::Policy::BuiltinFunctions::ProhibitShiftRef - Prohibit C<\shift> in code


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Prohibit the use of C<\shift>, as it is associated with bugs in Perl and its
modules.

=head2 Background

Often, C<\shift> is used to create references that act much like an alias.  By
creating an "alias" that is named, the code becomes more readable.  For example,

    sub routine {
        my $longstring = \shift;
        print $$longstring;
    }

is more readable than

    sub routine {
        print $_[0];    # longstring
    }

Unfortunately, this added readability brings with it new and exciting issues,
detailed in the next section.

=head2 Problems with C<\shift>

By avoiding C<\shift>, several issues in Perl can be averted, including:

=over

=item Memory leak since Perl 5.22

Issue #126676 was introduced in Perl 5.21.4 and is triggered when C<\shift> is
used.  The bug has not been resolved as of Perl 5.28.

In short, the bug causes the ref counter for the aliased variable to be
incremented when running the subroutine, but it is not subsequently decremented
after the subroutine returns.  In addition to leaking memory, this issue can
also delay the cleanup of objects until Global Destruction, which can cause
further issues.

For more information, see L<https://rt.perl.org/Public/Bug/Display.html?id=126676>.

=item Devel::Cover crashes

A separate, longstanding issue in Devel::Cover (since at least 1.21), causes
test code to segfault occasionally.  This prevents the coverage data from being
written out, resulting in bad metrics.

The bug itself isn't actually caused by C<\shift>, instead it shows up in code
like the following:

    sub myopen {
        open ${ \$_[0] }, ">test";
    }

However, this code would rarely be seen in production.  It would more likely
manifest with C<\shift>, as it does below:

    sub myopen {
        my $fh = \shift;
        open $$fh, ">test";
    }

So while C<\shift> isn't the cause, it's often associated with the problem.

For more information, see L<https://github.com/pjcj/Devel--Cover/issues/125>.

=back

=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 SEE ALSO

L<https://rt.perl.org/Public/Bug/Display.html?id=126676>

L<https://github.com/pjcj/Devel--Cover/issues/125>


=head1 AUTHOR

=for stopwords Lindee

Chris Lindee <chris.lindee@cpanel.net>


=head1 COPYRIGHT

=for stopwords cPanel

Copyright (c) 2018 cPanel, L.L.C.

All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
