##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::InputOutput::RequireCheckedSyscalls;

use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :booleans
                            hashify words_from_string is_perl_bareword };
use base 'Perl::Critic::Policy';

our $VERSION = '1.079_001';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Return value of flagged function ignored};
Readonly::Scalar my $EXPL => [208, 278];

Readonly::Array my @DEFAULT_FUNCTIONS => qw(
    open close print
);
# I created this list by searching for "return" in perlfunc
Readonly::Array my @BUILTIN_FUNCTIONS => qw(
    accept bind binmode chdir chmod chown close closedir connect
    dbmclose dbmopen exec fcntl flock fork ioctl kill link listen
    mkdir msgctl msgget msgrcv msgsnd open opendir pipe print read
    readdir readline readlink readpipe recv rename rmdir seek seekdir
    semctl semget semop send setpgrp setpriority setsockopt shmctl
    shmget shmread shutdown sleep socket socketpair symlink syscall
    sysopen sysread sysseek system syswrite tell telldir truncate
    umask unlink utime wait waitpid
);

#-----------------------------------------------------------------------------

sub supported_parameters { return qw(functions)          }
sub default_severity     { return $SEVERITY_LOWEST       }
sub default_themes       { return qw( core maintenance ) }
sub applies_to           { return 'PPI::Token::Word'     }

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    my ($self, $config) = @_;

    #Set configuration if defined
    if (defined $config->{functions}) {
        my $functions = $config->{functions};
        $functions =~ s/ :defaults / @DEFAULT_FUNCTIONS /gxms;
        $functions =~ s/ :builtins / @BUILTIN_FUNCTIONS /gxms;
        $self->{_functions} = { hashify words_from_string($functions) };
    } else {
        $self->{_functions} = { hashify @DEFAULT_FUNCTIONS };
    }

    return $TRUE;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $self->{_functions}->{':all'} ? is_perl_bareword($elem) : !$self->{_functions}->{$elem};
    return if ! is_unchecked_call( $elem );

    return $self->violation( $DESC . ' - ' . $elem, $EXPL, $elem );
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords nyah

=head1 NAME

Perl::Critic::Policy::InputOutput::RequireCheckedSyscalls

=head1 DESCRIPTION

This performs identically to InputOutput::RequireCheckedOpen/Close except that
this is configurable to apply to any function, whether core or user-defined.

If your module uses L<Fatal> or C<Fatal::Exception>, then any functions
wrapped by those modules will not trigger this policy.  For example:

   use Fatal qw(open);
   open my $fh, $filename;  # no violation
   close $fh;               # yes violation

=head1 CONFIGURATION

This policy watches for a configurable list of function names.  By default, it
applies to C<open>, C<print> and C<close>.  You can override this to set it to
a different list of functions with the C<functions> setting.  To do this, put
entries in a F<.perlcriticrc> file like this:

  [InputOutput::RequireCheckedSyscalls]
  functions = open opendir read readline readdir close closedir

We have defined a few shortcuts for creating this list

  [InputOutput::RequireCheckedSyscalls]
  functions = :defaults opendir readdir closedir

  [InputOutput::RequireCheckedSyscalls]
  functions = :builtins

  [InputOutput::RequireCheckedSyscalls]
  functions = :all

The C<:builtins> shortcut above represents all of the builtin functions that
have error conditions (about 65 of them, many of them rather obscure).

The C<:all> is the insane case: you must check the return value of EVERY
function call, even C<return> and C<exit>.  Yes, this "feature" is overkill
and is wasting CPU cycles on your computer by just existing.  Nyah nyah.  I
shouldn't code after midnight.

=head1 CREDITS

Initial development of this policy was supported by a grant from the Perl Foundation.

This policy module is based heavily on policies written by Andrew Moore <amoore@mooresystems.com>

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2007 Chris Dolan.  Many rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
