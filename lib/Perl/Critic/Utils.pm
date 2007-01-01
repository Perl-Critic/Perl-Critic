##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Utils;

use strict;
use warnings;
use Carp qw(confess);
use File::Spec qw();
use B::Keywords qw();
use base 'Exporter';

our $VERSION = 1.00;

#-----------------------------------------------------------------------------
# Exported symbols here. TODO: Use @EXPORT_OK and %EXPORT_TAGS instead


## no critic (AutomaticExport)
our @EXPORT = qw(

    $TRUE
    $FALSE

    $POLICY_NAMESPACE

    $SEVERITY_HIGHEST
    $SEVERITY_HIGH
    $SEVERITY_MEDIUM
    $SEVERITY_LOW
    $SEVERITY_LOWEST
    @SEVERITY_NAMES

    $COLON
    $COMMA
    $DQUOTE
    $EMPTY
    $FATCOMMA
    $PERIOD
    $PIPE
    $QUOTE
    $SCOLON
    $SPACE
    $SLASH
    $BSLASH

    &all_perl_files
    &find_keywords
    &hashify
    &interpolate
    &is_function_call
    &is_hash_key
    &is_method_call
    &is_perl_builtin
    &is_perl_global
    &is_script
    &is_subroutine_name
    &first_arg
    &parse_arg_list
    &policy_long_name
    &policy_short_name
    &precedence_of
    &shebang_line
    &severity_to_number
    &verbosity_to_format
    &words_from_string
);

#-----------------------------------------------------------------------------

our $POLICY_NAMESPACE = 'Perl::Critic::Policy';

#-----------------------------------------------------------------------------

our $SEVERITY_HIGHEST = 5;
our $SEVERITY_HIGH    = 4;
our $SEVERITY_MEDIUM  = 3;
our $SEVERITY_LOW     = 2;
our $SEVERITY_LOWEST  = 1;

#-----------------------------------------------------------------------------

our $COMMA      = q{,};
our $FATCOMMA   = q{=>};
our $COLON      = q{:};
our $SCOLON     = q{;};
our $QUOTE      = q{'};
our $DQUOTE     = q{"};
our $PERIOD     = q{.};
our $PIPE       = q{|};
our $SPACE      = q{ };
our $SLASH      = q{/};
our $BSLASH     = q{\\};
our $EMPTY      = q{};
our $TRUE       = 1;
our $FALSE      = 0;

#-----------------------------------------------------------------------------

#TODO: Should this include punctuations vars?



#-----------------------------------------------------------------------------
## no critic (ProhibitNoisyQuotes);

my %PRECEDENCE_OF = (
  '->'  => 1,       '<'    => 10,      '//'  => 15,      '.='  => 19,
  '++'  => 2,       '>'    => 10,      '||'  => 15,     '^='  => 19,
  '--'  => 2,       '<='   => 10,      '..'  => 16,     '<<=' => 19,
  '**'  => 3,       '>='   => 10,      '...' => 17,     '>>=' => 19,
  '!'   => 4,       'lt'   => 10,      '?'   => 18,     ','   => 20,
  '~'   => 4,       'gt'   => 10,      ':'   => 18,     '=>'  => 20,
  '\\'  => 4,       'le'   => 10,      '='   => 19,     'not' => 22,
  '=~'  => 5,       'ge'   => 10,      '+='  => 19,     'and' => 23,
  '!~'  => 5,       '=='   => 11,      '-='  => 19,     'or'  => 24,
  '*'   => 6,       '!='   => 11,      '*='  => 19,     'xor' => 24,
  '/'   => 6,       '<=>'  => 11,      '/='  => 19,
  '%'   => 6,       'eq'   => 11,      '%='  => 19,
  'x'   => 6,       'ne'   => 11,      '||=' => 19,
  '+'   => 7,       'cmp'  => 11,      '&&=' => 19,
  '-'   => 7,       '&'    => 12,      '|='  => 19,
  '.'   => 7,       '|'    => 13,      '&='  => 19,
  '<<'  => 8,       '^'    => 13,      '**=' => 19,
  '>>'  => 8,       '&&'   => 14,      'x='  => 19,
);

## use critic
#-----------------------------------------------------------------------------

sub hashify {
    return map { $_ => 1 } @_;
}

#-----------------------------------------------------------------------------

sub interpolate {
    my ( $literal ) = @_;
    return eval "\"$literal\"";  ## no critic 'StringyEval';
}

#-----------------------------------------------------------------------------

sub find_keywords {
    my ( $doc, $keyword ) = @_;
    my $nodes_ref = $doc->find('PPI::Token::Word');
    return if !$nodes_ref;
    my @matches = grep { $_ eq $keyword } @{$nodes_ref};
    return @matches ? \@matches : undef;
}

#-----------------------------------------------------------------------------
## no critic (ProhibitPackageVars)

my %BUILTINS = hashify( @B::Keywords::Functions );

sub is_perl_builtin {
    my $elem = shift;
    return if !$elem;
    my $name= eval {$elem->isa('PPI::Statement::Sub')} ? $elem->name() : $elem;
    return exists $BUILTINS{ $name };
}

#-----------------------------------------------------------------------------

my @GLOBALS_WITHOUT_SIGILS = map { substr $_, 1 }  @B::Keywords::Arrays,
                                                   @B::Keywords::Hashes,
                                                   @B::Keywords::Scalars;

my %GLOBALS= hashify( @GLOBALS_WITHOUT_SIGILS );

sub is_perl_global {
    my $elem = shift;
    return if !$elem;
    my $var_name = "$elem"; #Convert Token::Symbol to string
    $var_name =~ s{\A [\$@%] }{}mx;  #Chop off the sigil
    return exists $GLOBALS{ $var_name };
}

## use critic
#-----------------------------------------------------------------------------

sub precedence_of {
    my $elem = shift;
    return if !$elem;
    return $PRECEDENCE_OF{ ref $elem ? "$elem" : $elem };
}

#-----------------------------------------------------------------------------

sub is_hash_key {
    my $elem = shift;
    return if !$elem;

    #Check curly-brace style: $hash{foo} = bar;
    my $parent = $elem->parent();
    return if !$parent;
    my $grandparent = $parent->parent();
    return if !$grandparent;
    return 1 if $grandparent->isa('PPI::Structure::Subscript');


    #Check declarative style: %hash = (foo => bar);
    my $sib = $elem->snext_sibling();
    return if !$sib;
    return 1 if $sib->isa('PPI::Token::Operator') && $sib eq '=>';

    return;
}

#-----------------------------------------------------------------------------

sub is_method_call {
    my $elem = shift;
    return if !$elem;
    my $sib = $elem->sprevious_sibling();
    return if !$sib;
    return $sib->isa('PPI::Token::Operator') && $sib eq q{->};
}

#-----------------------------------------------------------------------------

sub is_subroutine_name {
    my $elem  = shift;
    return if !$elem;
    my $sib   = $elem->sprevious_sibling();
    return if !$sib;
    my $stmnt = $elem->statement();
    return if !$stmnt;
    return $stmnt->isa('PPI::Statement::Sub') && $sib eq 'sub';
}

#-----------------------------------------------------------------------------

sub is_function_call {
    my $elem  = shift;
    return ! ( is_hash_key($elem) ||
               is_method_call($elem) ||
               is_subroutine_name($elem) ||
               $elem eq 'sub'
    );
}

#-----------------------------------------------------------------------------

sub is_script {
    my $doc = shift;

    return shebang_line($doc) ? 1 : 0;
}

#-----------------------------------------------------------------------------

sub policy_long_name {
    my ( $policy_name ) = @_;
    if ( $policy_name !~ m{ \A $POLICY_NAMESPACE }mx ) {
        $policy_name = $POLICY_NAMESPACE . q{::} . $policy_name;
    }
    return $policy_name;
}

#-----------------------------------------------------------------------------

sub policy_short_name {
    my ( $policy_name ) = @_;
    $policy_name =~ s{\A $POLICY_NAMESPACE ::}{}mx;
    return $policy_name;
}

#-----------------------------------------------------------------------------

sub first_arg {
    my $elem = shift;
    my $sib  = $elem->snext_sibling();
    return if !$sib;

    if ( $sib->isa('PPI::Structure::List') ) {

        my $expr = $sib->schild(0);
        return if !$expr;
        return $expr->isa('PPI::Statement') ? $expr->schild(0) : $expr;
    }

    return $sib;
}

#-----------------------------------------------------------------------------

sub parse_arg_list {
    my $elem = shift;
    my $sib  = $elem->snext_sibling();
    return if !$sib;

    if ( $sib->isa('PPI::Structure::List') ) {

        #Pull siblings from list
        my $expr = $sib->schild(0);
        return if !$expr;
        return _split_nodes_on_comma( $expr->schildren() );
    }
    else {

        #Gather up remaining nodes in the statement
        my $iter     = $elem;
        my @arg_list = ();

        while ($iter = $iter->snext_sibling() ) {
            last if $iter->isa('PPI::Token::Structure') and $iter eq $SCOLON;
            push @arg_list, $iter;
        }
        return  _split_nodes_on_comma( @arg_list );
    }
}

#---------------------------------

sub _split_nodes_on_comma {
    my @nodes = ();
    my $i = 0;
    for my $node (@_) {
        if ( $node->isa('PPI::Token::Operator') &&
                (($node eq $COMMA) || ($node eq $FATCOMMA)) ) {
            $i++; #Move forward to next 'node stack'
            next;
        }
        push @{ $nodes[$i] }, $node;
    }
    return @nodes;
}

#-----------------------------------------------------------------------------

my %FORMAT_OF = (
    1 => "%f:%l:%c:%m\n",
    2 => "%f: (%l:%c) %m\n",
    3 => "%m at %f line %l\n",
    4 => "%m at line %l, column %c.  %e.  (Severity: %s)\n",
    5 => "%f: %m at line %l, column %c.  %e.  (Severity: %s)\n",
    6 => "%m at line %l, near '%r'.  (Severity: %s)\n",
    7 => "%f: %m at line %l near '%r'.  (Severity: %s)\n",
    8 => "[%p] %m at line %l, column %c.  (Severity: %s)\n",
    9 => "[%p] %m at line %l, near '%r'.  (Severity: %s)\n",
   10 => "%m at line %l, column %c.\n  %p (Severity: %s)\n%d\n",
   11 => "%m at line %l, near '%r'.\n  %p (Severity: %s)\n%d\n",
);

my $DEFAULT_FORMAT = $FORMAT_OF{4};

sub verbosity_to_format {
    my ($verbosity) = @_;
    return $DEFAULT_FORMAT if not defined $verbosity;
    return $FORMAT_OF{abs int $verbosity} || $DEFAULT_FORMAT if _is_integer($verbosity);
    return interpolate( $verbosity );  #Otherwise, treat as a format spec
}

sub _is_integer { return $_[0] =~  m{ \A [+-]? \d+ \z }mx }

#-----------------------------------------------------------------------------

my %SEVERITY_NUMBER_OF = (
   gentle  => 5,
   stern   => 4,
   harsh   => 3,
   cruel   => 2,
   brutal  => 1,
);

our @SEVERITY_NAMES = sort { $SEVERITY_NUMBER_OF{$a} <=> $SEVERITY_NUMBER_OF{$b} }
    keys %SEVERITY_NUMBER_OF;  #This is exported!

sub severity_to_number {
    my ($severity) = @_;
    return _normalize_severity( $severity ) if _is_integer( $severity );
    my $severity_number = $SEVERITY_NUMBER_OF{lc $severity};
    confess qq{Invalid severity: "$severity"} if not defined $severity_number;
    return $severity_number;
}

sub _normalize_severity {
    my $s = shift || return $SEVERITY_HIGHEST;
    $s = $s > $SEVERITY_HIGHEST ? $SEVERITY_HIGHEST : $s;
    $s = $s < $SEVERITY_LOWEST  ? $SEVERITY_LOWEST : $s;
    return $s;
}

#-----------------------------------------------------------------------------

my @skip_dir = qw( CVS RCS .svn _darcs {arch} .bzr _build blib );
my %skip_dir = hashify( @skip_dir );

sub all_perl_files {

    # Recursively searches a list of directories and returns the paths
    # to files that seem to be Perl source code.  This subroutine was
    # poached from Test::Perl::Critic.

    my @queue      = @_;
    my @code_files = ();

    while (@queue) {
        my $file = shift @queue;
        if ( -d $file ) {
            opendir my ($dh), $file or next;
            my @newfiles = sort readdir $dh;
            closedir $dh;

            @newfiles = File::Spec->no_upwards(@newfiles);
            @newfiles = grep { !$skip_dir{$_} } @newfiles;
            push @queue, map { File::Spec->catfile($file, $_) } @newfiles;
        }

        if ( (-f $file) && ! _is_backup($file) && _is_perl($file) ) {
            push @code_files, $file;
        }
    }
    return @code_files;
}


#-----------------------------------------------------------------------------
# Decide if it's some sort of backup file

sub _is_backup {
    my ($file) = @_;
    return 1 if $file =~ m{ [.] swp \z}mx;
    return 1 if $file =~ m{ [.] bak \z}mx;
    return 1 if $file =~ m{  ~ \z}mx;
    return 1 if $file =~ m{ \A [#] .+ [#] \z}mx;
    return;
}

#-----------------------------------------------------------------------------
# Returns true if the argument ends with a perl-ish file
# extension, or if it has a shebang-line containing 'perl' This
# subroutine was also poached from Test::Perl::Critic

sub _is_perl {
    my ($file) = @_;

    #Check filename extensions
    return 1 if $file =~ m{ [.] PL          \z}mx;
    return 1 if $file =~ m{ [.] p (?: l|m ) \z}mx;
    return 1 if $file =~ m{ [.] t           \z}mx;

    #Check for shebang
    open my ($fh), '<', $file or return;
    my $first = <$fh>;
    close $fh;

    return 1 if defined $first && ( $first =~ m{ \A \#![ ]*\S*perl }mx );
    return;
}

#-----------------------------------------------------------------------------

sub shebang_line {
    my $doc = shift;
    my $first_comment = $doc->find_first('PPI::Token::Comment');
    return if !$first_comment;
    my $location = $first_comment->location();
    return if !$location;
    # The shebang must be the first two characters in the file, according to
    # http://en.wikipedia.org/wiki/Shebang_(Unix)
    return if $location->[0] != 1; # line number
    return if $location->[1] != 1; # column number
    my $shebang = $first_comment->content;
    return if $shebang !~ m{ \A \#\! }mx;
    return $shebang;
}

#-----------------------------------------------------------------------------

sub words_from_string {
    my $str = shift;

    return split q{ }, $str; # This must be a literal space, not $SPACE
}


1;

__END__

=pod

=head1 NAME

Perl::Critic::Utils - Utility subs and vars for Perl::Critic

=head1 DESCRIPTION

This module exports several static subs and variables that are useful
for developing L<Perl::Critic::Policy> subclasses.  Unless you are
writing Policy modules, you probably don't care about this package.

=head1 EXPORTED SUBS

=over 8

=item C<find_keywords( $doc, $keyword )>

B<DEPRECATED:> Since version 0.11, every Policy is evaluated at each
element of the document.  So you shouldn't need to go looking for a
particular keyword.

Given a L<PPI::Document> as C<$doc>, returns a reference to an array
containing all the L<PPI::Token::Word> elements that match
C<$keyword>.  This can be used to find any built-in function, method
call, bareword, or reserved keyword.  It will not match variables,
subroutine names, literal strings, numbers, or symbols.  If the
document doesn't contain any matches, returns undef.

=item C<is_perl_global( $element )>

Given a L<PPI::Token::Symbol> or a string, returns true if that token
represents one of the global variables provided by the L<English>
module, or one of the builtin global variables like C<%SIG>, C<%ENV>,
or C<@ARGV>.  The sigil on the symbol is ignored, so things like
C<$ARGV> or C<$ENV> will still return true.

=item C<is_perl_builtin( $element )>

Given a L<PPI::Token::Word> or a string, returns true if that token
represents a call to any of the builtin functions defined in Perl
5.8.8

=item C<precedence_of( $element )>

Given a L<PPI::Token::Operator> or a string, returns the precedence of
the operator, where 1 is the highest precedence.  Returns undef if the
precedence can't be determined (which is usually because it is not an
operator).

=item C<is_hash_key( $element )>

Given a L<PPI::Element>, returns true if the element is a hash key.
PPI doesn't distinguish between regular barewords (like keywords or
subroutine calls) and barewords in hash subscripts (which are
considered literal).  So this subroutine is useful if your Policy is
searching for L<PPI::Token::Word> elements and you want to filter out
the hash subscript variety.  In both of the following examples, 'foo'
is considered a hash key:

  $hash1{foo} = 1;
  %hash2 = (foo => 1);

=item C<is_method_call( $element )>

Given a L<PPI::Element> that is presumed to be a function call (which
is usually a L<PPI::Token::Word>), returns true if the function is a
method being called on some reference.  Basically, it just looks to see
if the preceding operator is "->".  This is useful for distinguishing
static function calls from object method calls.

=item C<is_subroutine_name( $element )>

Given a L<PPI::Token::Word>, returns true if the element is the name
of a subroutine declaration.  This is useful for distinguishing
barewords and from function calls from subroutine declarations.

=item C<is_function_call( $element )>

Given a L<PPI::Token::Word> returns true if the element appears to be
call to a static function.  Specifically, this function returns true
if C<is_hash_key>, C<is_method_call>, and C<is_subroutine_name> all
return false for the given element.

=item C<first_arg( $element )>

Given a L<PPI::Element> that is presumed to be a function call (which is
usually a L<PPI::Token::Word>), return the first argument.  This is similar
of C<parse_arg_list()> and follows the same logic.  Note that for the code:

  int($x + 0.5)

this function will return just the C<$x>, not the whole expression.  This is
different from the behavior of C<parse_arg_list()>.  Another caveat is:

  int(($x + $y) + 0.5)

which returns C<($x + $y)> as a L<PPI::Structure::List> instance.

=item C<parse_arg_list( $element )>

Given a L<PPI::Element> that is presumed to be a function call (which
is usually a L<PPI::Token::Word>), splits the argument expressions
into arrays of tokens.  Returns a list containing references to each
of those arrays.  This is useful because parens are optional when
calling a function, and PPI parses them very differently.  So this
method is a poor-man's parse tree of PPI nodes.  It's not bullet-proof
because it doesn't respect precedence.  In general, I don't like the
way this function works, so don't count on it to be stable (or even
present).

=item C<is_script( $document )>

Given a L<PPI::Document>, test if it starts with C</#!.*/>.  If so,
it is judged to be a script instead of a module.  See C<shebang_line()>.

=item C< policy_long_name( ) >

=item C< policy_short_name( ) >

=item C<all_perl_files( @directories )>

Given a list of directories, recursively searches through all the
directories (depth first) and returns a list of paths for all the
files that are Perl code files.  Any administrative files for CVS or
Subversion are skipped, as are things that look like temporary or
backup files.

A Perl code file is:

=over 4

=item * Any file that ends in F<.PL>, F<.pl>, F<.pm>, or F<.t>

=item * Any file that has a first line with a shebang containing 'perl'

=back

=item C<severity_to_number( $severity )>

If C<$severity> is given as an integer, this function returns C<$severity> but
normalized to lie between C<$SEVERITY_LOWEST> and C<$SEVERITY_HIGHEST>.  If
C<$severity> is given as a string, this function returns the corresponding
severity number.  If the string doesn't have a corresponding number, this
function will throw an exception.

=item C<verbosity_to_format( $verbosity_level )>

Given a verbosity level between 1 and 10, returns the corresponding
predefined format string.  These formats are suitable for passing to
the C<set_format> method in L<Perl::Critic::Violation>.  See the
L<perlcritic> documentation for a listing of the predefined formats.

=item C<hashify( @list )>

Given C<@list>, return a hash where C<@list> is in the keys and each
value is 1.  Duplicate values in C<@list> are silently squished.

=item C<interpolate( $literal )>

Given a C<$literal> string that may contain control characters
(e.g.. '\t' '\n'), this function does a double interpolation on the
string and returns it as if it had been declared in double quotes.
For example:

  'foo \t bar \n' ...becomes... "foo \t bar \n"

=item C<shebang_line( $document )>

Given a L<PPI::Document>, test if it starts with C<#!>.  If so,
return that line.  Otherwise return undef.

=item C<words_from_string( $str )>

Given config string I<$str>, return all the words from the string.
This is safer than splitting on whitespace.

=back

=head1 EXPORTED VARIABLES

=over 8

=item C<$COMMA>

=item C<$FATCOMMA>

=item C<$COLON>

=item C<$SCOLON>

=item C<$QUOTE>

=item C<$DQUOTE>

=item C<$PERIOD>

=item C<$PIPE>

=item C<$EMPTY>

=item C<$SPACE>

=item C<$SLASH>

=item C<$BSLASH>

These character constants give clear names to commonly-used strings
that can be hard to read when surrounded by quotes and other
punctuation.

=item C<$SEVERITY_HIGHEST>

=item C<$SEVERITY_HIGH>

=item C<$SEVERITY_MEDIUM>

=item C<$SEVERITY_LOW>

=item C<$SEVERITY_LOWEST>

These numeric constants define the relative severity of violating each
L<Perl::Critic::Policy>.  The C<get_severity> and C<default_severity>
methods of every Policy subclass must return one of these values.

=item C<$TRUE>

=item C<$FALSE>

These are simple booleans. 1 and 0 respectively.  Be mindful of using these
with string equality.  C<$FALSE ne $EMPTY>.

=back

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
