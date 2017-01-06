package Perl::Critic::Policy::Subroutines::ProhibitNestedSubs;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Nested named subroutine};
Readonly::Scalar my $EXPL =>
    q{Declaring a named sub inside another named sub does not prevent the }
        . q{inner sub from being global};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                    }
sub default_severity     { return $SEVERITY_HIGHEST     }
sub default_themes       { return qw(core bugs)         }
sub applies_to           { return 'PPI::Statement::Sub' }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;

    return if $elem->isa('PPI::Statement::Scheduled');

    my $inner = $elem->find_first(
        sub {
            return
                    $_[1]->isa('PPI::Statement::Sub')
                &&  ! $_[1]->isa('PPI::Statement::Scheduled');
        }
    );
    return if not $inner;

    # Must be a violation...
    return $self->violation($DESC, $EXPL, $inner);
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords RJBS SIGNES

=head1 NAME

Perl::Critic::Policy::Subroutines::ProhibitNestedSubs - C<sub never { sub correct {} }>.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

B<Attention would-be clever Perl writers (including Younger RJBS):>

This does not do what you think:

  sub do_something {
      ...
      sub do_subprocess {
          ...
      }
      ...
  }

C<do_subprocess()> is global, despite where it is declared.  Either
write your subs without nesting or use anonymous code references.



=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 NOTE

Originally part of L<Perl::Critic::Tics|Perl::Critic::Tics>.


=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2007-2011 Ricardo SIGNES.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
