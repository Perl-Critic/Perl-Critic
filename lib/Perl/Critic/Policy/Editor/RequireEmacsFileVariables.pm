#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
########################################################################

package Perl::Critic::Policy::Editor::RequireEmacsFileVariables;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.21;

#---------------------------------------------------------------------------

my $desc = 'Use Emacs file variables to declare coding style';
my $expl = 'Emacs can read per-file settings';


#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_LOW       }
sub default_themes   { return qw(readability editor) }
sub applies_to       { return 'PPI::Document'     }

#---------------------------------------------------------------------------

sub new {
    my ( $class, %config ) = @_;
    my $self = bless {}, $class;


    return $self;
}

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my $code = $doc->serialize();

    ## Look for first line file vars.  Example:
    #! /usr/bin/perl -w -*- mode: cperl; cperl-indent-level: 4 -*-

    my $one_line_local_var   = qr/-[*]- .* -[*]-/xms;

    # Note: If PPI changes away from native newlines, this may break
    my ($first_line, $second_line) = $code =~ m/\A ([^\n]*) (?: \n ([^\n]*) )? /xms;
    return if $first_line =~ m/$one_line_local_var/xms;
    return if ($second_line
	       && $first_line =~ m/\A \#!/xms
	       && $second_line =~ m/$one_line_local_var/xms);


    ## Look for end of doc file vars  Example:
    #  Local Variables:
    #   mode: cperl-mode
    #  End:
    my $last_page = substr $code, -3000;
    # Remove anything not on the last page, as delimited by "^L", aka
    # "\f", aka formfeed.
    $last_page =~ s/ .* \f//xms;

    # This regex is transliterated from emacs22 files.el
    # Note that the [ \t]* before "End:" appears to be wrong, but is
    # added for compatibility
    return if $last_page =~ m/
			      ^ ([^\n]*) Local [ ] Variables: [ \t]* ([^\n]*) $
			      .*?
			      ^ \1 [ \t]* End: [ \t]* \2 $
			      /ixms;

    return $self->violation( $desc, $expl, $doc );
}

1;

__END__

#---------------------------------------------------------------------------

=pod

=for stopwords elisp syntaxes files.el

=head1 NAME

Perl::Critic::Policy::Editor::RequireEmacsFileVariables;

=head1 DESCRIPTION

Many text editors know how to find magic strings in files that
indicate settings that work best for that file.  For example, the file
can indicate that it expects four-character indentation.

In emacs, this magic string is called "File Variables".  There are two
syntaxes:
  C<-*- ... -*-> (single-line)
and
  C<Local Variables:\n...\nEnd:> (multi-line).
Both syntaxes allow leading and trailing text on the line.

The single-line syntax must be used on the first line of the file to
be recognized, or on the second line if the first line is a shebang.
The following examples are explicitly allowed by Perl:

   #!perl -w -*- cperl -*-
   #!perl -w # -*- cperl -*-
   #!perl # -*- cperl -*-

The multi-line syntax must be used "in the last page" (that is, after
the last formfeed) at the end of the file.  As of Emacs21, the "end of
the file" is hard-coded to be the last 3000 bytes of the file (in the
hack-local-variables function in files.el).  In this syntax, each line
must begin and end with the same prefix/suffix pair.  That pair is
defined by the text before and after the "Local Variables:" string.

=head1 SEE ALSO

L<Perl::Critic::Policy::Editor::RequireViModeline>

L<http://www.gnu.org/software/emacs/manual/html_node/File-Variables.html>

In Emacs, you can view the "File Variables" info node by typing:
C<Help-key>, C<i>, C<g>, C<(emacs)File Variables>
(where C<Help-key> is often C<C-h> or C<F1>.)

Alternatively, you can execute the following elisp:
  (info "(emacs)File Variables")

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

Michael Wolf <MichaelRWolf@att.net>

=head1 COPYRIGHT

Copyright (c) 2006 Chris Dolan.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 expandtab
