package Perl::Critic::Utils::POD::Text;
use strict;
use warnings;
use parent 'Pod::Text';
use Readonly;

our $VERSION = '1.156';

Readonly::Scalar our $INF, 9**9**9;

sub new {
    my ($class, %opts) = @_;
    $opts{width} = $INF;
    return $class->SUPER::new(%opts);
}

sub cmd_c {
    my ($self, $attrs, $text) = @_;
    return "`$text'";
}

1;

__END__

=pod

=for stopwords

=head1 NAME

Perl::Critic::Utils::POD::Text - Pod parser for producing plain text

=head1 DESCRIPTION

A subclass of L<Pod::Text> with some tweaks. It does no wrapping, and uses
simple C<`...'> quoting of C<< CE<lt>E<gt> >> formatting codes.

=head1 INTERFACE SUPPORT

This is considered to be a non-public class.  Its interface is subject
to change without notice.

=head1 METHOD OVERRIDES

=over

=item cmd_c

Override Pod::Text to avoid guesswork and consistently add C<`'> quotes.

=back

=head1 AUTHOR

Graham Knop <haarg@haarg.org>

=head1 COPYRIGHT

Copyright (c) 2026 Graham Knop.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
