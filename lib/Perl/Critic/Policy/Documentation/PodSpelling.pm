##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::Documentation::PodSpelling;

use strict;
use warnings;
use Readonly;

use File::Spec;
use List::MoreUtils qw(uniq);
use English qw(-no_match_vars);
use Carp;

use Perl::Critic::Utils qw{
    :characters
    :booleans
    :severities
    &words_from_string
};
use base 'Perl::Critic::Policy';

our $VERSION = 1.07;

#-----------------------------------------------------------------------------

Readonly::Scalar my $POD_RX => qr{\A = (?: for|begin|end ) }mx;
Readonly::Scalar my $DESC => q{Check the spelling in your POD};
Readonly::Scalar my $EXPL => [148];

#-----------------------------------------------------------------------------

sub supported_parameters { return qw(spell_command stop_words) }
sub default_severity     { return $SEVERITY_LOWEST        }
sub default_themes       { return qw( core cosmetic pbp ) }
sub applies_to           { return 'PPI::Document'         }

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    my ( $self, $config ) = @_;

    #Set configuration if defined
    $self->_set_spell_command( $config->{spell_command} || 'aspell list' );
    $self->_set_stop_words(
        [ words_from_string($config->{stop_words} || $EMPTY) ]
    );

    my $exe = $self->_get_spell_command_line();
    return $FALSE if !$exe;

    eval {
        require Pod::Spell;
        require IO::String;
        require IPC::Open2;
    };
    return $FALSE if $EVAL_ERROR;

    return $TRUE;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my $code = $doc->serialize;
    my $text;
    my $infh = IO::String->new( $code );
    my $outfh = IO::String->new( $text );
    my @words;
    {
       # temporarily add our special wordlist to this annoying global
       my @stop_words = @{ $self->_get_stop_words() };
       local @Pod::Wordlist::Wordlist{ @stop_words } ##no critic(ProhibitPackageVars)
           = (1) x @stop_words;
       Pod::Spell->new()->parse_from_filehandle($infh, $outfh);

       # shortcut if no words to spellcheck
       return if $text !~ m/\S/xms;

       # run spell command and fetch output
       my $command_line = $self->_get_spell_command_line();
       my $reader_fh;
       my $writer_fh;
       my $pid = IPC::Open2::open2($reader_fh, $writer_fh, @{$command_line});
       return if ! $pid;

       print {$writer_fh} $text;
       close $writer_fh or croak 'Failed to close pipe to spelling program';
       @words = uniq <$reader_fh>;
       close $reader_fh or croak 'Failed to close pipe to spelling program';
       waitpid $pid, 0;

       for (@words) {
          chomp;
       }

       # Why is this extra step needed???
       @words = grep { ! exists $Pod::Wordlist::Wordlist{$_} } @words;  ##no critic(ProhibitPackageVars)
    }
    return if !@words;

    return $self->violation( "$DESC: @words", $EXPL, $doc );
}

#-----------------------------------------------------------------------------

sub _get_spell_command_line {
    my ($self) = @_;

    return if $self->_get_failed();

    if (! ref $self->{_spell_command_line}) {
        eval {
            require File::Which;
            require Text::ParseWords;
        };
        if ($EVAL_ERROR) {
            $self->_set_failed($TRUE);
            return;
        }
        my @words = Text::ParseWords::shellwords($self->_get_spell_command());
        if (!@words) {
            $self->_set_failed($TRUE);
            return;
        }
        if (! File::Spec->file_name_is_absolute($words[0])) {
           $words[0] = File::Which::which($words[0]);
        }
        if (! $words[0] || ! -x $words[0]) {
            $self->_set_failed($TRUE);
            return;
        }
        $self->{_spell_command_line} = \@words;
    }

    return $self->{_spell_command_line};
}

#-----------------------------------------------------------------------------

sub _get_spell_command {
    my ( $self ) = @_;

    return $self->{_spell_command};
}

sub _set_spell_command {
    my ( $self, $spell_command ) = @_;

    $self->{_spell_command} = $spell_command;

    return;
}

#-----------------------------------------------------------------------------

sub _get_stop_words {
    my ( $self ) = @_;

    return $self->{_stop_words};
}

sub _set_stop_words {
    my ( $self, $stop_words ) = @_;

    $self->{_stop_words} = $stop_words;

    return;
}

#-----------------------------------------------------------------------------

sub _get_failed {
    my ( $self ) = @_;

    return $self->{_failed};
}

sub _set_failed {
    my ( $self, $failed ) = @_;

    $self->{_failed} = $failed;

    return;
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords Hmm stopwords

=head1 NAME

Perl::Critic::Policy::Documentation::PodSpelling

=head1 DESCRIPTION

Did you write the documentation?  Check.

Did you document all of the public methods?  Check.

Is your documentation readable?  Hmm...

Ideally, we'd like Perl::Critic to tell you when your documentation is
inadequate.  That's hard to code, though.  So, inspired by
L<Test::Spelling>, this module checks the spelling of your POD.  It
does this by pulling the prose out of the code and passing it to an
external spell checker.  It skips over words you flagged to ignore.
If the spell checker returns any misspelled words, this policy emits a
violation.

If anything else goes wrong -- you don't have Pod::Spell installed or
we can't locate the spell checking program or (gasp!) your module has
no POD -- then this policy passes.

To add exceptions on a module-by-module basis, add "stopwords" as
described in L<Pod::Spell>.  For example:

   =for stopword gibbles
   
   =head1 Gibble::Manip -- manipulate your gibbles
   
   =cut

=head1 CONFIGURATION

This policy can be configured to tell which spell checker to use or to
set a global list of spelling exceptions.  To do this, put entries in
a F<.perlcriticrc> file like this:

  [Documentation::PodSpelling]
  spellcommand = aspell list
  stopwords = gibbles foobar

The default spell command is C<aspell list> and it is interpreted as a
shell command.  We parse the individual arguments via
L<Text::ParseWords> so feel free to use quotes around your arguments.
If the executable path is an absolute file name, it is used as-is.  If
it is a relative file name, we employ L<File::Which> to convert it to
an absolute path via the C<PATH> environment variable.  As described
in Pod::Spell and Test::Spelling, the spell checker must accept text
on STDIN and print misspelled words one per line on STDOUT.

=head1 NOTES

L<Pod::Spell> is not included with Perl::Critic, nor is a spell
checking program.

=head1 CREDITS

Initial development of this policy was supported by a grant from the Perl Foundation.

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2007 Chris Dolan.  Many rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
