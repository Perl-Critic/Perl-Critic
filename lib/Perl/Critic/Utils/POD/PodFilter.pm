package Perl::Critic::Utils::POD::PodFilter;
use strict;
use warnings;
use parent 'Pod::Simple::JustPod';

our $VERSION = '1.156';

# JustPod always adds an initial =pod. instead, only add it if the pod starts
# with a paragraph or verbatim section.
sub _handle_element_start { ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
  my ($self, $element, @args) = @_;
  if ($element eq 'Document') {
    $self->{buffer} = q[];
    return;
  }
  elsif ($element eq 'Para' || $element eq 'Verbatim') {
    if (!$self->{_started_pod}) {
      $self->handle_text("=pod\n\n");
    }
  }
  $self->{_started_pod} = 1;
  return $self->SUPER::_handle_element_start($element, @args);
}

# eliminate ending =cut
sub _handle_element_end { ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
  my ($self, $element, @args) = @_;
  if ($element eq 'Document') {
    $self->emit;
    return;
  }
  return $self->SUPER::_handle_element_end($element, @args);
}

1;

__END__

=pod

=for stopwords

=head1 NAME

Perl::Critic::Utils::POD::PodFilter - Pod parser for filtering Pod

=head1 DESCRIPTION

A subclass of L<Pod::Simple::JustPod> with some tweaks. It omits an unneeded
leading C<=pod> command, and a trailing C<=cut> command.

=head1 INTERFACE SUPPORT

This is considered to be a non-public class.  Its interface is subject
to change without notice.

=head1 AUTHOR

Graham Knop <haarg@haarg.org>

=head1 COPYRIGHT

Copyright (c) 2026 Graham Knop.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
