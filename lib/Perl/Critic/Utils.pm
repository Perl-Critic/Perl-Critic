package Perl::Critic::Utils;

use strict;
use warnings;
use base 'Exporter';

our $VERSION = '0.13';
$VERSION = eval $VERSION;    ## no critic

#-------------------------------------------------------------------
# Exported symbols here

our @EXPORT =
  qw(@BUILTINS    @GLOBALS       $TRUE
     $COMMA       $DQUOTE        $FALSE
     $COLON       $PERIOD        &find_keywords
     $SCOLON      $PIPE          &is_hash_key
     $QUOTE       $EMPTY         &is_method_call
     $SPACE                      &parse_arg_list                
);

#---------------------------------------------------------------------------

our $COMMA  = q{,};
our $COLON  = q{:};
our $SCOLON = q{;};
our $QUOTE  = q{'};
our $DQUOTE = q{"};
our $PERIOD = q{.};
our $PIPE   = q{|};
our $SPACE  = q{ };
our $EMPTY  = q{};
our $TRUE   = 1;
our $FALSE  = 0;

#---------------------------------------------------------------------------
our @BUILTINS =
  qw(abs         exp              int       readdir      socket     wantarray
     accept      fcntl            ioctl     readline     socketpair warn
     alarm       fileno           join      readlink     sort       write
     atan2       flock            keys      readpipe     splice
     bind        fork             kill      recv         split
     binmode     format           last      redo         sprintf
     bless       formline         lc        ref          sqrt
     caller      getc             lcfirst   rename       srand
     chdir       getgrent         length    require      stat
     chmod       getgrgid         link      reset        study
     chomp       getgrnam         listen    return       sub
     chop        gethostbyaddr    local     reverse      substr
     chown       gethostbyname    localtime rewinddir    symlink
     chr         gethostent       log       rindex       syscall
     chroot      getlogin         lstat     rmdir        sysopen
     close       getnetbyaddr     map       scalar       sysread
     closedir    getnetbyname     mkdir     seek         sysseek
     connect     getnetent        msgctl    seekdir      system
     continue    getpeername      msgget    select       syswrite
     cos         getpgrp          msgrcv    semctl       tell
     crypt       getppid          msgsnd    semget       telldir
     dbmclose    getpriority      next      semop        tie
     dbmopen     getprotobyname   no        send         tied
     defined     getprotobynumber oct       setgrent     time
     delete      getprotoent      open      sethostent   times
     die         getpwent         opendir   setnetent    truncate
     do          getpwnam         ord       setpgrp      uc
     dump        getpwuid         our       setpriority  ucfirst
     each        getservbyname    pack      setprotoent  umask
     endgrent    getservbyport    package   setpwent     undef
     endhostent  getservent       pipe      setservent   unlink
     endnetent   getsockname      pop       setsockopt   unpack
     endprotoent getsockopt       pos       shift        unshift
     endpwent    glob             print     shmctl       untie
     endservent  gmtime           printf    shmget       use
     eof         goto             prototype shmread      utime
     eval        grep             push      shmwrite     values
     exec        hex              quotemeta shutdown     vec
     exists      import           rand      sin          wait
     exit        index            read      sleep        waitpid
);

#---------------------------------------------------------------------------

our @GLOBALS =
  qw(ACCUMULATOR                   INPLACE_EDIT
     BASETIME                      INPUT_LINE_NUMBER NR
     CHILD_ERROR                   INPUT_RECORD_SEPARATOR RS
     COMPILING                     LAST_MATCH_END
     DEBUGGING                     LAST_REGEXP_CODE_RESULT
     EFFECTIVE_GROUP_ID EGID       LIST_SEPARATOR
     EFFECTIVE_USER_ID EUID        OS_ERROR
     ENV                           OSNAME
     EVAL_ERROR                    OUTPUT_AUTOFLUSH
     ERRNO                         OUTPUT_FIELD_SEPARATOR OFS
     EXCEPTIONS_BEING_CAUGHT       OUTPUT_RECORD_SEPARATOR ORS
     EXECUTABLE_NAME               PERL_VERSION
     EXTENDED_OS_ERROR             PROGRAM_NAME
     FORMAT_FORMFEED               REAL_GROUP_ID GID
     FORMAT_LINE_BREAK_CHARACTERS  REAL_USER_ID UID
     FORMAT_LINES_LEFT             SIG
     FORMAT_LINES_PER_PAGE         SUBSCRIPT_SEPARATOR SUBSEP
     FORMAT_NAME                   SYSTEM_FD_MAX
     FORMAT_PAGE_NUMBER            WARNING
     FORMAT_TOP_NAME               PERLDB
     INC ARGV
);

#-------------------------------------------------------------------------

sub find_keywords {
    my ( $doc, $keyword ) = @_;
    my $nodes_ref = $doc->find('PPI::Token::Word') || return;
    my @matches = grep { $_ eq $keyword } @{$nodes_ref};
    return @matches ? \@matches : undef;
}

sub is_hash_key {
    my $elem = shift;

    #Check curly-brace style: $hash{foo} = bar;
    my $parent = $elem->parent() || return;
    my $grandparent = $parent->parent() || return;
    return 1 if $grandparent->isa('PPI::Structure::Subscript');


    #Check declarative style: %hash = (foo => bar);
    my $sib = $elem->snext_sibling() || return;
    return 1 if $sib->isa('PPI::Token::Operator') && $sib eq '=>';

    return 0;
}

sub is_method_call {
    my $elem = shift;
    my $sib = $elem->sprevious_sibling() || return;
    return $sib->isa('PPI::Token::Operator') && $sib eq q{->};
}

sub parse_arg_list {
    my $elem = shift;
    my $sib  = $elem->snext_sibling() || return;

    if ( $sib->isa('PPI::Structure::List') ) {

	#Pull siblings from list
	my $expr = $sib->schild(0) || return;
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

sub _split_nodes_on_comma {
    my @nodes = ();
    my $i = 0;
    for my $node (@_) {
        if ( $node->isa('PPI::Token::Operator') && $node eq $COMMA ) {
	    $i++; #Move forward to next 'node stack'
	    next;
	}

	#Push onto current 'node stack', or create a new 'stack' 
	if ( defined $nodes[$i] ) { 
	    push @{ $nodes[$i] }, $node;
	}
	else {
	    $nodes[$i] = [$node];
	}
    }
    return @nodes;
}
		    
1;

__END__

=head1 NAME

Perl::Critic::Utils - Utility subs and vars for Perl::Critic

=head1 DESCRIPTION

This module has exports several static subs and variables that are
useful for developing L<Perl::Critic::Policy> subclasses.  Unless you
are writing Policy modules, you probably don't care about this
package.

=head1 EXPORTED SUBS

=over 8

=item find_keywords( $doc, $keyword );

B<This function is deprecated!> Since version 0.11, every Policy is
evaluated at each element of the document.  So you shouldn't need to
go looking for a particular keyword.  I've left this function in place
just in case you come across a particular need for it.

Given L<PPI::Document> as C<$doc>, returns a reference to an array
containing all the L<PPI::Token::Word> elements that match
C<$keyword>.  This can be used to find any built-in function, method
call, bareword, or reserved keyword.  It will not match variables,
subroutine names, literal strings, numbers, or symbols.  If the
document doesn't contain any matches, returns undef.

=item is_hash_key( $element )

Given a L<PPI::Element>, returns true if the element is a hash key.
PPI doesn't distinguish between regular barewords (like keywords or
subroutine calls) and barewords in hash subscripts (which are
considered literal).  So this subroutine is useful if your Policy is
searching for L<PPI::Token::Word> elements and you want to filter out
the hash subscript variety.  In both of the following examples, 'foo'
is considered a hash key:

  $hash1{foo} = 1;
  %hash2 = (foo => 1);

=item is_method_call( $element )

Given a L<PPI::Element> that is presumed to be a function call (which
is usually a L<PPI::Token::Word>, returns true if the function is a
method being called on some reference.  Baically, it just looks to see
if the preceding operator is "->".  This is usefull for distinguishing
static from object methods.

=item parse_arg_list( $element )

Given a L<PPI::Element> that is presumed to be a function call (which
is usually a L<PPI::Token::Word>), splits the argument expressions
into arrays of tokens.  Returns a list containing references to each
of those arrays.  This is useful because parens are optional when
calling a function, and PPI parses them very differently.  So this
method is a poor-man's parse tree of PPI nodes.  It's not bullet-proof
because it doesn't respect precedence.  In general, I don't like the
way this function works, so don't count on it to be stable (or even
present).

=back

=head1 EXPORTED VARIABLES

=over 8

=item @BUILTINS

This is a list of all the built-in functions provided by Perl 5.8.  I
imagine this is useful for distinguishing native and non-native
function calls.  In the future, I'm thinking of adding a hash that
maps each built-in function to the maximal number of arguments that it
accepts.  I think this will help facilitate the lexing the children of
L<PPI::Expression> objects.

=item @GLOBALS

This is a list of all the magic global variables provided by the
L<English> module.  Also includes commonly-used global like C<%SIG>,
C<%ENV>, and C<@ARGV>.  The list contains only the variable name,
without the sigil.

=item $COMMA 

=item $COLON

=item $SCOLON

=item $QUOTE

=item $DQUOTE

=item $PERIOD

=item $PIPE 

=item $EMPTY

These give clear names to commonly-used strings that can be hard to
read when surrounded by quotes.

=item $TRUE 

=item $FALSE

These are simple booleans. 1 and 0 respectively.  Be mindful of using these
with string equality.  $FALSE ne $EMPTY.

=back

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.
