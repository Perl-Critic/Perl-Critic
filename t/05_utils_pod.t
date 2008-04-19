#!perl

##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

use strict;
use warnings;

use Carp qw< confess >;

use IO::String;

use Test::More tests => 13;

#-----------------------------------------------------------------------------

BEGIN {
    use_ok('Perl::Critic::Utils::POD', qw< :all >)
        or confess 'No point in continuing.';
}


can_ok('main', 'get_pod_section_from_file');
can_ok('main', 'get_pod_section_from_filehandle');
can_ok('main', 'trim_pod_section');


{
    my $code = q<my $x = 3;>;
    my $code_handle = IO::String->new($code);

    my $pod = get_pod_section_from_filehandle( $code_handle, 'SYNOPSIS' );

    is(
        $pod,
        undef,
        qq<get_pod_section_from_filehandle($code, 'SYNOPSIS')>,
    );
}


{
    my $code = <<'END_CODE';
=pod
END_CODE
    my $code_handle = IO::String->new($code);

    my $pod = get_pod_section_from_filehandle( $code_handle, 'SYNOPSIS' );

    is(
        $pod,
        undef,
        q<get_pod_section_from_filehandle('=pod', 'SYNOPSIS')>,
    );
}


{
    my $code = <<'END_CODE';
=pod

=head1 FOO

Some plain text.

=cut
END_CODE
    my $code_handle = IO::String->new($code);

    my $pod = get_pod_section_from_filehandle( $code_handle, 'FOO' );

    my $expected = <<'END_EXPECTED';
=head1 FOO

Some plain text.

END_EXPECTED
    is(
        $pod,
        $expected,
        q<get_pod_section_from_filehandle('=head1 FOO Some plain text.', 'FOO')>,
    );
}


{
    my $code = <<'END_CODE';
=pod

=head1 FOO

Some C<escaped> text.

=cut
END_CODE
    my $code_handle = IO::String->new($code);

    my $pod = get_pod_section_from_filehandle( $code_handle, 'FOO' );

    my $expected = <<'END_EXPECTED';
=head1 FOO

Some C<escaped> text.

END_EXPECTED
    is(
        $pod,
        $expected,
        q/get_pod_section_from_filehandle('=head1 FOO Some C<escaped> text.', 'FOO')/,
    );
}


{
    my $code = <<'END_CODE';
=pod

=head1 FOO

Some plain text.

=head1 BAR

=cut
END_CODE
    my $code_handle = IO::String->new($code);

    my $pod = get_pod_section_from_filehandle( $code_handle, 'FOO' );

    my $expected = <<'END_EXPECTED';
=head1 FOO

Some plain text.

END_EXPECTED
    is(
        $pod,
        $expected,
        q<get_pod_section_from_filehandle('=head1 FOO ... =head1 BAR', 'FOO')>,
    );
}


{
    my $code = <<'END_CODE';
=pod

=head1 FOO

Some plain text.

=head2 BAR

=cut
END_CODE
    my $code_handle = IO::String->new($code);

    my $pod = get_pod_section_from_filehandle( $code_handle, 'FOO' );

    my $expected = <<'END_EXPECTED';
=head1 FOO

Some plain text.

=head2 BAR

END_EXPECTED
    is(
        $pod,
        $expected,
        q<get_pod_section_from_filehandle('=head1 FOO ... =head2 BAR', 'FOO')>,
    );
}

{
    my $code = <<'END_CODE';
=pod

=head2 FOO

Some plain text.

=cut
END_CODE
    my $code_handle = IO::String->new($code);

    my $pod = get_pod_section_from_filehandle( $code_handle, 'FOO' );

    is(
        $pod,
        undef,
        q<get_pod_section_from_filehandle('=head2 FOO Some plain text.', 'FOO')>,
    );
}

#-----------------------------------------------------------------------------

{
    my $original = <<'END_POD';
=head1 LYRICS

We like talking dirty. We smoke and we drink. We're KMFDM and all other bands
stink.

END_POD

    my $trimmed = trim_pod_section( $original );

    my $expected =
        q<We like talking dirty. We smoke and we drink. >
        . qq<We're KMFDM and all other bands\n>
        . q<stink.>;

    is(
        $trimmed,
        $expected,
        'trim_pod_section() with section header',
    );
}


{
    my $original = <<'END_VOCAL_SAMPLE';

You see, I believe in the noble, aristocratic art of doin' absolutely nothin'.
And I hope someday to be in a position where I can do even less.

END_VOCAL_SAMPLE

    my $trimmed = trim_pod_section( $original );

    my $expected =
        q<You see, I believe in the noble, aristocratic art of doin' >
        . qq<absolutely nothin'.\n>
        . q<And I hope someday to be in a position where I can do even >
        . q<less.>;

    is(
        $trimmed,
        $expected,
        'trim_pod_section() without section header',
    );
}

#-----------------------------------------------------------------------------

# ensure we run true if this test is loaded by
# t/05_utils_pod.t_without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
