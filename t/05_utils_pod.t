#!perl

use 5.006001;
use strict;
use warnings;

use English qw< -no_match_vars >;
use Readonly;
use Carp qw< confess >;


use Perl::Critic::Utils::POD qw< :all >;


use Test::More tests => 61;

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXCEPTION_MESSAGE_REGEX =>
    qr<malformed [ ] name [ ] section>xmsi;


can_ok('main', 'get_pod_file_for_module');
can_ok('main', 'get_raw_pod_section_from_file');
can_ok('main', 'get_raw_pod_section_from_filehandle');
can_ok('main', 'get_raw_pod_section_from_string');
can_ok('main', 'get_raw_pod_section_for_module');
can_ok('main', 'get_pod_section_from_file');
can_ok('main', 'get_pod_section_from_filehandle');
can_ok('main', 'get_pod_section_from_string');
can_ok('main', 'get_pod_section_for_module');
can_ok('main', 'trim_raw_pod_section');
can_ok('main', 'trim_pod_section');
can_ok('main', 'get_raw_module_abstract_from_file');
can_ok('main', 'get_raw_module_abstract_from_filehandle');
can_ok('main', 'get_raw_module_abstract_from_string');
can_ok('main', 'get_raw_module_abstract_for_module');
can_ok('main', 'get_module_abstract_from_file');
can_ok('main', 'get_module_abstract_from_filehandle');
can_ok('main', 'get_module_abstract_from_string');
can_ok('main', 'get_module_abstract_for_module');


{
    my $code = q<my $x = 3;>;  ## no critic (RequireInterpolationOfMetachars)

    my $pod = get_raw_pod_section_from_string( $code, 'SYNOPSIS' );

    is(
        $pod,
        undef,
        qq<get_raw_pod_section_from_string($code, 'SYNOPSIS')>,
    );

    $pod = get_pod_section_from_string( $code, 'SYNOPSIS' );

    is(
        $pod,
        undef,
        qq<get_pod_section_from_string($code, 'SYNOPSIS')>,
    );
}


{
    my $code = <<'END_CODE';
=pod
END_CODE

    my $pod = get_raw_pod_section_from_string( $code, 'SYNOPSIS' );

    is(
        $pod,
        undef,
        q<get_raw_pod_section_from_string('=pod', 'SYNOPSIS')>,
    );

    $pod = get_pod_section_from_string( $code, 'SYNOPSIS' );

    is(
        $pod,
        undef,
        q<get_pod_section_from_string('=pod', 'SYNOPSIS')>,
    );
}


{
    my $code = <<'END_CODE';
=pod

=head1 FOO

Some plain text.

=cut
END_CODE

    my $pod = get_raw_pod_section_from_string( $code, 'FOO' );

    my $expected = <<'END_EXPECTED';
=head1 FOO

Some plain text.

END_EXPECTED
    is(
        $pod,
        $expected,
        q<get_raw_pod_section_from_string('=head1 FOO Some plain text.', 'FOO')>,
    );

    $pod = get_pod_section_from_string( $code, 'FOO' );

    $expected = <<'END_EXPECTED';
FOO
    Some plain text.

END_EXPECTED
    is(
        $pod,
        $expected,
        q<get_pod_section_from_string('=head1 FOO Some plain text.', 'FOO')>,
    );
}


{
    my $code = <<'END_CODE';
=pod

=head1 FOO

Some C<escaped> text.

=cut
END_CODE

    my $pod = get_raw_pod_section_from_string( $code, 'FOO' );

    my $expected = <<'END_EXPECTED';
=head1 FOO

Some C<escaped> text.

END_EXPECTED
    is(
        $pod,
        $expected,
        q/get_raw_pod_section_from_string('=head1 FOO Some C<escaped> text.', 'FOO')/,
    );

    $pod = get_pod_section_from_string( $code, 'FOO' );

    $expected = <<'END_EXPECTED';
FOO
    Some `escaped' text.

END_EXPECTED
    is(
        $pod,
        $expected,
        q/get_pod_section_from_string('=head1 FOO Some C<escaped> text.', 'FOO')/,
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

    my $pod = get_raw_pod_section_from_string( $code, 'FOO' );

    my $expected = <<'END_EXPECTED';
=head1 FOO

Some plain text.

END_EXPECTED
    is(
        $pod,
        $expected,
        q<get_raw_pod_section_from_string('=head1 FOO ... =head1 BAR', 'FOO')>,
    );

    $pod = get_pod_section_from_string( $code, 'FOO' );

    $expected = <<'END_EXPECTED';
FOO
    Some plain text.

END_EXPECTED
    is(
        $pod,
        $expected,
        q<get_pod_section_from_string('=head1 FOO ... =head1 BAR', 'FOO')>,
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

    my $pod = get_raw_pod_section_from_string( $code, 'FOO' );

    my $expected = <<'END_EXPECTED';
=head1 FOO

Some plain text.

=head2 BAR

END_EXPECTED
    is(
        $pod,
        $expected,
        q<get_raw_pod_section_from_string('=head1 FOO ... =head2 BAR', 'FOO')>,
    );

    $pod = get_pod_section_from_string( $code, 'FOO' );

    # Pod::Parser v1.36 changed what it did with trailing whitespace, so we
    # use a regex with an ending \s* so that we can deal with whatever version
    # of Pod::Parser the user has installed.  This until we can figure out
    # what to replace Pod::Select with.
    $expected = qr<
        \A
        FOO \n
        [ ]{4} Some [ ] plain [ ] text.\n
        \n
        [ ]{2} BAR\n
        \s*
        \z
    >xms;

    like(
        $pod,
        $expected,
        q<get_pod_section_from_string('=head1 FOO ... =head2 BAR', 'FOO')>,
    );
}

{
    my $code = <<'END_CODE';
=pod

=head2 FOO

Some plain text.

=cut
END_CODE

    my $pod = get_raw_pod_section_from_string( $code, 'FOO' );

    is(
        $pod,
        undef,
        q<get_raw_pod_section_from_string('=head2 FOO Some plain text.', 'FOO')>,
    );

    $pod = get_pod_section_from_string( $code, 'FOO' );

    is(
        $pod,
        undef,
        q<get_pod_section_from_string('=head2 FOO Some plain text.', 'FOO')>,
    );
}

#-----------------------------------------------------------------------------

{
    my $original = <<'END_POD';
=head1 LYRICS

We like talking dirty. We smoke and we drink. We're KMFDM and all other bands
stink.

END_POD

    my $trimmed = trim_raw_pod_section( $original );

    my $expected =
        q<We like talking dirty. We smoke and we drink. >
        . qq<We're KMFDM and all other bands\n>
        . q<stink.>;

    is(
        $trimmed,
        $expected,
        'trim_raw_pod_section() with section header',
    );

    $trimmed = trim_pod_section( $original );

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

    my $trimmed = trim_raw_pod_section( $original );

    my $expected =
        q<You see, I believe in the noble, aristocratic art of doin' >
        . qq<absolutely nothin'.\n>
        . q<And I hope someday to be in a position where I can do even >
        . q<less.>;

    is(
        $trimmed,
        $expected,
        'trim_raw_pod_section() without section header',
    );

    $trimmed = trim_pod_section( $original );

    is(
        $trimmed,
        $expected,
        'trim_pod_section() without section header',
    );
}


{
    my $original = <<'END_INDENTATION';

    Some indented text.

END_INDENTATION

    my $trimmed = trim_raw_pod_section( $original );

    my $expected = q<Some indented text.>;

    is(
        $trimmed,
        $expected,
        'trim_raw_pod_section() indented',
    );

    $trimmed = trim_pod_section( $original );

    $expected = q<    > . $expected;

    is(
        $trimmed,
        $expected,
        'trim_pod_section() indented',
    );
}

#-----------------------------------------------------------------------------

{
    my $source = <<'END_MODULE';

=head1 NAME

A::Stupendous::Module - An abstract.

END_MODULE

    my $expected = q<An abstract.>;

    my $result = get_raw_module_abstract_from_string( $source );

    is(
        $result,
        $expected,
        q<get_raw_module_abstract_from_string() with proper abstract>,
    );

    $result = get_module_abstract_from_string( $source );

    is(
        $result,
        $expected,
        q<get_module_abstract_from_string() with proper abstract>,
    );
}


{
    my $source = <<'END_MODULE';

=head1 NAME

A::Stupendous::Code::Module - An abstract involving C<$code>.

END_MODULE

    my $expected = q<An abstract involving C<$code>.>; ## no critic (RequireInterpolationOfMetachars)

    my $result = get_raw_module_abstract_from_string( $source );

    is(
        $result,
        $expected,
        q<get_raw_module_abstract_from_string() with proper abstract>,
    );

    $expected = q<An abstract involving `$code'.>; ## no critic (RequireInterpolationOfMetachars)

    $result = get_module_abstract_from_string( $source );

    is(
        $result,
        $expected,
        q<get_module_abstract_from_string() with proper abstract>,
    );
}


{
    my $source = <<'END_MODULE';

=head1 NOT NAME

There's nobody home.

END_MODULE

    my $result = get_raw_module_abstract_from_string( $source );

    is(
        $result,
        undef,
        q<get_raw_module_abstract_from_string() with no name section>,
    );

    $result = get_module_abstract_from_string( $source );

    is(
        $result,
        undef,
        q<get_module_abstract_from_string() with no name section>,
    );
}


{
    my $source = <<'END_MODULE';

=head1 NAME

=head1 DESCRIPTION

END_MODULE

    my $result = get_raw_module_abstract_from_string( $source );

    is(
        $result,
        undef,
        q<get_raw_module_abstract_from_string() without NAME section content>,
    );

    $result = get_module_abstract_from_string( $source );

    is(
        $result,
        undef,
        q<get_module_abstract_from_string() without NAME section content>,
    );
}


{
    my $source = <<'END_MODULE';

=head1 NAME

A::Not::So::Stupendous::Module

END_MODULE

    my $result = get_raw_module_abstract_from_string( $source );

    is(
        $result,
        undef,
        q<get_raw_module_abstract_from_string() with no abstract>,
    );

    $result = get_module_abstract_from_string( $source );

    is(
        $result,
        undef,
        q<get_module_abstract_from_string() with no abstract>,
    );
}


{
    my $source = <<'END_MODULE';

=head1 NAME

A::Not::So::Stupendous::Module -

END_MODULE

    my $result = get_raw_module_abstract_from_string( $source );

    is(
        $result,
        undef,
        q<get_raw_module_abstract_from_string() with hyphen but no abstract>,
    );

    $result = get_module_abstract_from_string( $source );

    is(
        $result,
        undef,
        q<get_module_abstract_from_string() with hyphen but no abstract>,
    );
}


{
    my $source = <<'END_MODULE';

=head1 NAME

A::Not::So::Stupendous::Module No hyphen.

END_MODULE

    test_exception_from_get_raw_module_abstract_from_string(
        $source, q<with abstract but no hyphen>,
    );

    test_exception_from_get_module_abstract_from_string(
        $source, q<with abstract but no hyphen>,
    );
}


{
    my $source = <<'END_MODULE';

=head1 NAME

A::Not::So::Stupendous::Module -- Double hyphen.

END_MODULE

    test_exception_from_get_raw_module_abstract_from_string(
        $source, q<with double hyphen>,
    );

    test_exception_from_get_module_abstract_from_string(
        $source, q<with double hyphen>,
    );
}


{
    my $source = <<'END_MODULE';

=head1 NAME

A::Not::So::Stupendous::Module - Abstract goes across
multiple lines.

END_MODULE

    test_exception_from_get_raw_module_abstract_from_string(
        $source, q<with multiple lines>,
    );

# Cannot do this test: Pod::PlainText merges the lines.
#    test_exception_from_get_module_abstract_from_string(
#        $source, q<with multiple lines>,
#    );
}

#-----------------------------------------------------------------------------

sub test_exception_from_get_raw_module_abstract_from_string {
    my ($source, $name) = @_;

    my $result;
    my $message_like_name =
        qq<Got expected message for get_raw_module_abstract_from_string() $name>;

    local $EVAL_ERROR = undef;
    eval {
        $result = get_raw_module_abstract_from_string( $source );
    };
    _test_exception_from_get_module_abstract_from_string(
        $source, $name, $result, $message_like_name,
    );

    return;
}

sub test_exception_from_get_module_abstract_from_string {
    my ($source, $name) = @_;

    my $result;
    my $message_like_name =
        qq<Got expected message for get_module_abstract_from_string() $name>;

    local $EVAL_ERROR = undef;
    eval {
        $result = get_module_abstract_from_string( $source );
    };
    _test_exception_from_get_module_abstract_from_string(
        $source, $name, $result, $message_like_name,
    );

    return;
}

sub _test_exception_from_get_module_abstract_from_string {
    my ($source, $name, $result, $message_like_name) = @_;

    my $eval_error = $EVAL_ERROR;
    my $exception = Perl::Critic::Exception::Fatal::Generic->caught();

    if (
        ok(
            ref $exception,
            qq<Got the right kind of exception for get_module_abstract_from_string() $name>,
        )
    ) {
        like( $exception->message(), $EXCEPTION_MESSAGE_REGEX, $message_like_name );
    }
    else {
        diag( 'Result: ', (defined $result ? ">$result<" : '<undef>') );
        if ($eval_error) {
            diag(
                qq<However, did get an exception: $eval_error>,
            );
            like( $eval_error, $EXCEPTION_MESSAGE_REGEX, $message_like_name );
        }
        else {
            fail($message_like_name);
        }
    }

    return;
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
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
