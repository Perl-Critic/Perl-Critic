# NOTE: This module is way too large.  Please think about adding new
# functionality into a P::C::Utils::* module instead.

package Perl::Critic::Utils;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Carp qw( confess );
use English qw(-no_match_vars);
use File::Spec qw();
use Scalar::Util qw( blessed );
use B::Keywords qw();
use PPI::Token::Quote::Single;

use Perl::Critic::Exception::Fatal::Generic qw{ throw_generic };
use Perl::Critic::Utils::PPI qw< is_ppi_expression_or_generic_statement >;

use Exporter 'import';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------
# Exportable symbols here.

Readonly::Array our @EXPORT_OK => qw(
    $TRUE
    $FALSE

    $POLICY_NAMESPACE

    $SEVERITY_HIGHEST
    $SEVERITY_HIGH
    $SEVERITY_MEDIUM
    $SEVERITY_LOW
    $SEVERITY_LOWEST
    @SEVERITY_NAMES

    $DEFAULT_VERBOSITY
    $DEFAULT_VERBOSITY_WITH_FILE_NAME

    $COLON
    $COMMA
    $DQUOTE
    $EMPTY
    $EQUAL
    $FATCOMMA
    $PERIOD
    $PIPE
    $QUOTE
    $BACKTICK
    $SCOLON
    $SPACE
    $SLASH
    $BSLASH
    $LEFT_PAREN
    $RIGHT_PAREN

    all_perl_files
    find_keywords
    first_arg
    hashify
    interpolate
    is_assignment_operator
    is_class_name
    is_function_call
    is_hash_key
    is_in_void_context
    is_included_module_name
    is_integer
    is_label_pointer
    is_method_call
    is_package_declaration
    is_perl_bareword
    is_perl_builtin
    is_perl_builtin_with_list_context
    is_perl_builtin_with_multiple_arguments
    is_perl_builtin_with_no_arguments
    is_perl_builtin_with_one_argument
    is_perl_builtin_with_optional_argument
    is_perl_builtin_with_zero_and_or_one_arguments
    is_perl_filehandle
    is_perl_global
    is_qualified_name
    is_script
    is_subroutine_name
    is_unchecked_call
    is_valid_numeric_verbosity
    parse_arg_list
    policy_long_name
    policy_short_name
    precedence_of
    severity_to_number
    shebang_line
    split_nodes_on_comma
    verbosity_to_format
    words_from_string
);


# Note: this is deprecated.  This should also violate ProhibitAutomaticExportation,
# but at the moment, we aren't smart enough to deal with Readonly variables.
Readonly::Array our @EXPORT => @EXPORT_OK;


Readonly::Hash our %EXPORT_TAGS => (
    all             => [ @EXPORT_OK ],
    booleans        => [ qw{ $TRUE $FALSE } ],
    severities      => [
        qw{
            $SEVERITY_HIGHEST
            $SEVERITY_HIGH
            $SEVERITY_MEDIUM
            $SEVERITY_LOW
            $SEVERITY_LOWEST
            @SEVERITY_NAMES
        }
    ],
    characters      => [
        qw{
            $COLON
            $COMMA
            $DQUOTE
            $EMPTY
            $EQUAL
            $FATCOMMA
            $PERIOD
            $PIPE
            $QUOTE
            $BACKTICK
            $SCOLON
            $SPACE
            $SLASH
            $BSLASH
            $LEFT_PAREN
            $RIGHT_PAREN
        }
    ],
    classification  => [
        qw{
            is_assignment_operator
            is_class_name
            is_function_call
            is_hash_key
            is_included_module_name
            is_integer
            is_label_pointer
            is_method_call
            is_package_declaration
            is_perl_bareword
            is_perl_builtin
            is_perl_filehandle
            is_perl_global
            is_perl_builtin_with_list_context
            is_perl_builtin_with_multiple_arguments
            is_perl_builtin_with_no_arguments
            is_perl_builtin_with_one_argument
            is_perl_builtin_with_optional_argument
            is_perl_builtin_with_zero_and_or_one_arguments
            is_qualified_name
            is_script
            is_subroutine_name
            is_unchecked_call
            is_valid_numeric_verbosity
        }
    ],
    data_conversion => [ qw{ hashify words_from_string interpolate } ],
    ppi             => [ qw{ first_arg parse_arg_list } ],
    internal_lookup => [ qw{ severity_to_number verbosity_to_format } ],
    language        => [ qw{ precedence_of } ],
    deprecated      => [ qw{ find_keywords } ],
);

#-----------------------------------------------------------------------------

Readonly::Scalar our $POLICY_NAMESPACE => 'Perl::Critic::Policy';

#-----------------------------------------------------------------------------

Readonly::Scalar our $SEVERITY_HIGHEST => 5;
Readonly::Scalar our $SEVERITY_HIGH    => 4;
Readonly::Scalar our $SEVERITY_MEDIUM  => 3;
Readonly::Scalar our $SEVERITY_LOW     => 2;
Readonly::Scalar our $SEVERITY_LOWEST  => 1;

#-----------------------------------------------------------------------------

Readonly::Scalar our $COMMA        => q{,};
Readonly::Scalar our $EQUAL        => q{=};
Readonly::Scalar our $FATCOMMA     => q{=>};
Readonly::Scalar our $COLON        => q{:};
Readonly::Scalar our $SCOLON       => q{;};
Readonly::Scalar our $QUOTE        => q{'};
Readonly::Scalar our $DQUOTE       => q{"};
Readonly::Scalar our $BACKTICK     => q{`};
Readonly::Scalar our $PERIOD       => q{.};
Readonly::Scalar our $PIPE         => q{|};
Readonly::Scalar our $SPACE        => q{ };
Readonly::Scalar our $SLASH        => q{/};
Readonly::Scalar our $BSLASH       => q{\\};
Readonly::Scalar our $LEFT_PAREN   => q{(};
Readonly::Scalar our $RIGHT_PAREN  => q{)};
Readonly::Scalar our $EMPTY        => q{};
Readonly::Scalar our $TRUE         => 1;
Readonly::Scalar our $FALSE        => 0;

#-----------------------------------------------------------------------------

#TODO: Should this include punctuations vars?



#-----------------------------------------------------------------------------
## no critic (ProhibitNoisyQuotes);

Readonly::Hash my %PRECEDENCE_OF => (
    '->'   => 1,
    '++'   => 2,
    '--'   => 2,
    '**'   => 3,
    '!'    => 4,
    '~'    => 4,
    '\\'   => 4,
    '=~'   => 5,
    '!~'   => 5,
    '*'    => 6,
    '/'    => 6,
    '%'    => 6,
    'x'    => 6,
    '+'    => 7,
    '-'    => 7,
    '.'    => 7,
    '<<'   => 8,
    '>>'   => 8,
    '-R'   => 9,
    '-W'   => 9,
    '-X'   => 9,
    '-r'   => 9,
    '-w'   => 9,
    '-x'   => 9,
    '-e'   => 9,
    '-O'   => 9,
    '-o'   => 9,
    '-z'   => 9,
    '-s'   => 9,
    '-M'   => 9,
    '-A'   => 9,
    '-C'   => 9,
    '-S'   => 9,
    '-c'   => 9,
    '-b'   => 9,
    '-f'   => 9,
    '-d'   => 9,
    '-p'   => 9,
    '-l'   => 9,
    '-u'   => 9,
    '-g'   => 9,
    '-k'   => 9,
    '-t'   => 9,
    '-T'   => 9,
    '-B'   => 9,
    '<'    => 10,
    '>'    => 10,
    '<='   => 10,
    '>='   => 10,
    'lt'   => 10,
    'gt'   => 10,
    'le'   => 10,
    'ge'   => 10,
    '=='   => 11,
    '!='   => 11,
    '<=>'  => 11,
    'eq'   => 11,
    'ne'   => 11,
    'cmp'  => 11,
    '~~'   => 11,
    '&'    => 12,
    '|'    => 13,
    '^'    => 13,
    '&&'   => 14,
    '//'   => 15,
    '||'   => 15,
    '..'   => 16,
    '...'  => 17,
    '?'    => 18,
    ':'    => 18,
    '='    => 19,
    '+='   => 19,
    '-='   => 19,
    '*='   => 19,
    '/='   => 19,
    '%='   => 19,
    '||='  => 19,
    '&&='  => 19,
    '|='   => 19,
    '&='   => 19,
    '**='  => 19,
    'x='   => 19,
    '.='   => 19,
    '^='   => 19,
    '<<='  => 19,
    '>>='  => 19,
    '//='  => 19,
    ','    => 20,
    '=>'   => 20,
    'not'  => 22,
    'and'  => 23,
    'or'   => 24,
    'xor'  => 24,
);

## use critic

Readonly::Scalar my $MIN_PRECEDENCE_TO_TERMINATE_PARENLESS_ARG_LIST =>
    precedence_of( 'not' );

#-----------------------------------------------------------------------------

sub hashify {  ## no critic (ArgUnpacking)
    return map { $_ => 1 } @_;
}

#-----------------------------------------------------------------------------

sub interpolate {
    my ( $literal ) = @_;
    return eval "\"$literal\"" || confess $EVAL_ERROR;  ## no critic (StringyEval);
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

sub _name_for_sub_or_stringified_element {
    my $elem = shift;

    if ( blessed $elem and $elem->isa('PPI::Statement::Sub') ) {
        return $elem->name();
    }

    return "$elem";
}

#-----------------------------------------------------------------------------
## no critic (ProhibitPackageVars)

Readonly::Hash my %BUILTINS => hashify( @B::Keywords::Functions );

sub is_perl_builtin {
    my $elem = shift;
    return if !$elem;

    return exists $BUILTINS{ _name_for_sub_or_stringified_element($elem) };
}

#-----------------------------------------------------------------------------

Readonly::Hash my %BAREWORDS => hashify( @B::Keywords::Barewords );

sub is_perl_bareword {
    my $elem = shift;
    return if !$elem;

    return exists $BAREWORDS{ _name_for_sub_or_stringified_element($elem) };
}

#-----------------------------------------------------------------------------

sub _build_globals_without_sigils {
    # B::Keywords as of 1.08 forgot $\
    my @globals =
        map { substr $_, 1 }
            @B::Keywords::Arrays,
            @B::Keywords::Hashes,
            @B::Keywords::Scalars,
            '$\\'; ## no critic (RequireInterpolationOfMetachars)

    # Not all of these have sigils
    foreach my $filehandle (@B::Keywords::Filehandles) {
        (my $stripped = $filehandle) =~ s< \A [*] ><>xms;
        push @globals, $stripped;
    }

    return @globals;
}

Readonly::Array my @GLOBALS_WITHOUT_SIGILS => _build_globals_without_sigils();

Readonly::Hash my %GLOBALS => hashify( @GLOBALS_WITHOUT_SIGILS );

sub is_perl_global {
    my $elem = shift;
    return if !$elem;
    my $var_name = "$elem"; #Convert Token::Symbol to string
    $var_name =~ s{\A [\$@%*] }{}xms;  #Chop off the sigil
    return exists $GLOBALS{ $var_name };
}

#-----------------------------------------------------------------------------

Readonly::Hash my %FILEHANDLES => hashify( @B::Keywords::Filehandles );

sub is_perl_filehandle {
    my $elem = shift;
    return if !$elem;

    return exists $FILEHANDLES{ _name_for_sub_or_stringified_element($elem) };
}

## use critic
#-----------------------------------------------------------------------------

# egrep '=item.*LIST' perlfunc.pod
Readonly::Hash my %BUILTINS_WHICH_PROVIDE_LIST_CONTEXT =>
    hashify(
        qw{
            chmod
            chown
            die
            exec
            formline
            grep
            import
            join
            kill
            map
            no
            open
            pack
            print
            printf
            push
            reverse
            say
            sort
            splice
            sprintf
            syscall
            system
            tie
            unlink
            unshift
            use
            utime
            warn
        },
    );

sub is_perl_builtin_with_list_context {
    my $elem = shift;

    return
        exists
            $BUILTINS_WHICH_PROVIDE_LIST_CONTEXT{
                _name_for_sub_or_stringified_element($elem)
            };
}

#-----------------------------------------------------------------------------

# egrep '=item.*[A-Z],' perlfunc.pod
Readonly::Hash my %BUILTINS_WHICH_TAKE_MULTIPLE_ARGUMENTS =>
    hashify(
        qw{
            accept
            atan2
            bind
            binmode
            bless
            connect
            crypt
            dbmopen
            fcntl
            flock
            gethostbyaddr
            getnetbyaddr
            getpriority
            getservbyname
            getservbyport
            getsockopt
            index
            ioctl
            link
            listen
            mkdir
            msgctl
            msgget
            msgrcv
            msgsnd
            open
            opendir
            pipe
            read
            recv
            rename
            rindex
            seek
            seekdir
            select
            semctl
            semget
            semop
            send
            setpgrp
            setpriority
            setsockopt
            shmctl
            shmget
            shmread
            shmwrite
            shutdown
            socket
            socketpair
            splice
            split
            substr
            symlink
            sysopen
            sysread
            sysseek
            syswrite
            truncate
            unpack
            vec
            waitpid
        },
        keys %BUILTINS_WHICH_PROVIDE_LIST_CONTEXT
    );

sub is_perl_builtin_with_multiple_arguments {
    my $elem = shift;

    return
        exists
            $BUILTINS_WHICH_TAKE_MULTIPLE_ARGUMENTS{
                _name_for_sub_or_stringified_element($elem)
            };
}

#-----------------------------------------------------------------------------

Readonly::Hash my %BUILTINS_WHICH_TAKE_NO_ARGUMENTS =>
    hashify(
        qw{
            endgrent
            endhostent
            endnetent
            endprotoent
            endpwent
            endservent
            fork
            format
            getgrent
            gethostent
            getlogin
            getnetent
            getppid
            getprotoent
            getpwent
            getservent
            setgrent
            setpwent
            split
            time
            times
            wait
            wantarray
        }
    );

sub is_perl_builtin_with_no_arguments {
    my $elem = shift;

    return
        exists
            $BUILTINS_WHICH_TAKE_NO_ARGUMENTS{
                _name_for_sub_or_stringified_element($elem)
            };
}

#-----------------------------------------------------------------------------

Readonly::Hash my %BUILTINS_WHICH_TAKE_ONE_ARGUMENT =>
    hashify(
        qw{
            closedir
            dbmclose
            delete
            each
            exists
            fileno
            getgrgid
            getgrnam
            gethostbyname
            getnetbyname
            getpeername
            getpgrp
            getprotobyname
            getprotobynumber
            getpwnam
            getpwuid
            getsockname
            goto
            keys
            local
            prototype
            readdir
            readline
            readpipe
            rewinddir
            scalar
            sethostent
            setnetent
            setprotoent
            setservent
            telldir
            tied
            untie
            values
        }
    );

sub is_perl_builtin_with_one_argument {
    my $elem = shift;

    return
        exists
            $BUILTINS_WHICH_TAKE_ONE_ARGUMENT{
                _name_for_sub_or_stringified_element($elem)
            };
}

#-----------------------------------------------------------------------------

## no critic (ProhibitPackageVars)
Readonly::Hash my %BUILTINS_WHICH_TAKE_OPTIONAL_ARGUMENT =>
    hashify(
        grep { not exists $BUILTINS_WHICH_TAKE_ONE_ARGUMENT{ $_ } }
        grep { not exists $BUILTINS_WHICH_TAKE_NO_ARGUMENTS{ $_ } }
        grep { not exists $BUILTINS_WHICH_TAKE_MULTIPLE_ARGUMENTS{ $_ } }
        @B::Keywords::Functions
    );
## use critic

sub is_perl_builtin_with_optional_argument {
    my $elem = shift;

    return
        exists
            $BUILTINS_WHICH_TAKE_OPTIONAL_ARGUMENT{
                _name_for_sub_or_stringified_element($elem)
            };
}

#-----------------------------------------------------------------------------

sub is_perl_builtin_with_zero_and_or_one_arguments {
    my $elem = shift;

    return if not $elem;

    my $name = _name_for_sub_or_stringified_element($elem);

    return (
            exists $BUILTINS_WHICH_TAKE_ONE_ARGUMENT{ $name }
        or  exists $BUILTINS_WHICH_TAKE_NO_ARGUMENTS{ $name }
        or  exists $BUILTINS_WHICH_TAKE_OPTIONAL_ARGUMENT{ $name }
    );
}

#-----------------------------------------------------------------------------

sub is_qualified_name {
    my $name = shift;

    return if not $name;

    return index ( $name, q{::} ) >= 0;
}

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

    #If followed by an argument list, then its a function call, not a literal
    return if _is_followed_by_parens($elem);

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

sub _is_followed_by_parens {
    my $elem = shift;
    return if !$elem;

    my $sibling = $elem->snext_sibling() || return;
    return $sibling->isa('PPI::Structure::List');
}

#-----------------------------------------------------------------------------

sub is_included_module_name {
    my $elem  = shift;
    return if !$elem;
    my $stmnt = $elem->statement();
    return if !$stmnt;
    return if !$stmnt->isa('PPI::Statement::Include');
    return $stmnt->schild(1) == $elem;
}

#-----------------------------------------------------------------------------

sub is_integer {
    my ($value) = @_;
    return 0 if not defined $value;

    return $value =~ m{ \A [+-]? \d+ \z }xms;
}

#-----------------------------------------------------------------------------

sub is_label_pointer {
    my $elem = shift;
    return if !$elem;

    my $statement = $elem->statement();
    return if !$statement;

    my $psib = $elem->sprevious_sibling();
    return if !$psib;

    return $statement->isa('PPI::Statement::Break')
        && $psib =~ m/(?:redo|goto|next|last)/xmso;
}

#-----------------------------------------------------------------------------

sub is_method_call {
    my $elem = shift;
    return if !$elem;

    return _is_dereference_operator( $elem->sprevious_sibling() );
}

#-----------------------------------------------------------------------------

sub is_class_name {
    my $elem = shift;
    return if !$elem;

    return _is_dereference_operator( $elem->snext_sibling() )
        && !_is_dereference_operator( $elem->sprevious_sibling() );
}

#-----------------------------------------------------------------------------

sub _is_dereference_operator {
    my $elem = shift;
    return if !$elem;

    return $elem->isa('PPI::Token::Operator') && $elem eq q{->};
}

#-----------------------------------------------------------------------------

sub is_package_declaration {
    my $elem  = shift;
    return if !$elem;
    my $stmnt = $elem->statement();
    return if !$stmnt;
    return if !$stmnt->isa('PPI::Statement::Package');
    return $stmnt->schild(1) == $elem;
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
    my $elem = shift or return;

    return if is_perl_bareword($elem);
    return if is_perl_filehandle($elem);
    return if is_package_declaration($elem);
    return if is_included_module_name($elem);
    return if is_method_call($elem);
    return if is_class_name($elem);
    return if is_subroutine_name($elem);
    return if is_label_pointer($elem);
    return if is_hash_key($elem);

    return 1;
}

#-----------------------------------------------------------------------------

sub is_script {
    my $doc = shift;

    warnings::warnif(
        'deprecated',
        'Perl::Critic::Utils::is_script($doc) deprecated, use $doc->is_program() instead.',  ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
    );

    return $doc->is_program()
        if blessed($doc) && $doc->isa('Perl::Critic::Document');

    return 1 if shebang_line($doc);
    return 1 if _is_PL_file($doc);
    return 0;
}

#-----------------------------------------------------------------------------

sub _is_PL_file {  ## no critic (NamingConventions::Capitalization)
    my ($doc) = @_;
    return if not $doc->can('filename');
    my $filename = $doc->filename() || return;
    return 1 if $filename =~ m/[.] PL \z/xms;
    return 0;
}

#-----------------------------------------------------------------------------

sub is_in_void_context {
    my ($token) = @_;

    # If part of a collective, can't be void.
    return if $token->sprevious_sibling();

    my $parent = $token->statement()->parent();
    if ($parent) {
        return if $parent->isa('PPI::Structure::List');
        return if $parent->isa('PPI::Structure::For');
        return if $parent->isa('PPI::Structure::Condition');
        return if $parent->isa('PPI::Structure::Constructor');
        return if $parent->isa('PPI::Structure::Subscript');

        my $grand_parent = $parent->parent();
        if ($grand_parent) {
            return if
                    $parent->isa('PPI::Structure::Block')
                and not $grand_parent->isa('PPI::Statement::Compound');
        }
    }

    return $TRUE;
}

#-----------------------------------------------------------------------------

sub policy_long_name {
    my ( $policy_name ) = @_;
    if ( $policy_name !~ m{ \A $POLICY_NAMESPACE }xms ) {
        $policy_name = $POLICY_NAMESPACE . q{::} . $policy_name;
    }
    return $policy_name;
}

#-----------------------------------------------------------------------------

sub policy_short_name {
    my ( $policy_name ) = @_;
    $policy_name =~ s{\A $POLICY_NAMESPACE ::}{}xms;
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
        my @list_contents = $sib->schildren();
        return if not @list_contents;

        my @list_expressions;
        foreach my $item (@list_contents) {
            if (
                is_ppi_expression_or_generic_statement($item)
            ) {
                push
                    @list_expressions,
                    split_nodes_on_comma( $item->schildren() );
            }
            else {
                push @list_expressions, $item;
            }
        }

        return @list_expressions;
    }
    else {

        #Gather up remaining nodes in the statement
        my $iter     = $elem;
        my @arg_list = ();

        while ($iter = $iter->snext_sibling() ) {
            last if $iter->isa('PPI::Token::Structure') and $iter eq $SCOLON;
            last if $iter->isa('PPI::Token::Operator')
                and $MIN_PRECEDENCE_TO_TERMINATE_PARENLESS_ARG_LIST <=
                    precedence_of( $iter );
            push @arg_list, $iter;
        }
        return split_nodes_on_comma( @arg_list );
    }
}

#---------------------------------

sub split_nodes_on_comma {
    my @nodes = @_;

    my $i = 0;
    my @node_stacks;
    for my $node (@nodes) {
        if (
                $node->isa('PPI::Token::Operator')
            and ($node eq $COMMA or $node eq $FATCOMMA)
        ) {
            if (@node_stacks) {
                $i++; #Move forward to next 'node stack'
            }
            next;
        } elsif ( $node->isa('PPI::Token::QuoteLike::Words' )) {
            my $section = $node->{sections}->[0];
            my @words = words_from_string(substr $node->content, $section->{position}, $section->{size});
            my $loc = $node->location;
            for my $word (@words) {
                my $token = PPI::Token::Quote::Single->new(q{'} . $word . q{'});
                $token->{_location} = $loc;
                push @{ $node_stacks[$i++] }, $token;
            }
            next;
        }
        push @{ $node_stacks[$i] }, $node;
    }
    return @node_stacks;
}

#-----------------------------------------------------------------------------

# XXX: You must keep the regular expressions in extras/perlcritic.el in sync
# if you change these.
Readonly::Hash my %FORMAT_OF => (
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

Readonly::Scalar our $DEFAULT_VERBOSITY => 4;
Readonly::Scalar our $DEFAULT_VERBOSITY_WITH_FILE_NAME => 5;
Readonly::Scalar my $DEFAULT_FORMAT => $FORMAT_OF{$DEFAULT_VERBOSITY};

sub is_valid_numeric_verbosity {
    my ($verbosity) = @_;

    return exists $FORMAT_OF{$verbosity};
}

sub verbosity_to_format {
    my ($verbosity) = @_;
    return $DEFAULT_FORMAT if not defined $verbosity;
    return $FORMAT_OF{abs int $verbosity} || $DEFAULT_FORMAT if is_integer($verbosity);
    return interpolate( $verbosity );  #Otherwise, treat as a format spec
}

#-----------------------------------------------------------------------------

Readonly::Hash my %SEVERITY_NUMBER_OF => (
   gentle  => 5,
   stern   => 4,
   harsh   => 3,
   cruel   => 2,
   brutal  => 1,
);

Readonly::Array our @SEVERITY_NAMES =>  #This is exported!
    sort
        { $SEVERITY_NUMBER_OF{$a} <=> $SEVERITY_NUMBER_OF{$b} }
        keys %SEVERITY_NUMBER_OF;

sub severity_to_number {
    my ($severity) = @_;
    return _normalize_severity( $severity ) if is_integer( $severity );
    my $severity_number = $SEVERITY_NUMBER_OF{lc $severity};

    if ( not defined $severity_number ) {
        throw_generic qq{Invalid severity: "$severity"};
    }

    return $severity_number;
}

sub _normalize_severity {
    my $s = shift || return $SEVERITY_HIGHEST;
    $s = $s > $SEVERITY_HIGHEST ? $SEVERITY_HIGHEST : $s;
    $s = $s < $SEVERITY_LOWEST  ? $SEVERITY_LOWEST : $s;
    return $s;
}

#-----------------------------------------------------------------------------

Readonly::Array my @SKIP_DIR => qw( CVS RCS .svn _darcs {arch} .bzr .cdv .git .hg .pc _build blib );
Readonly::Hash my %SKIP_DIR => hashify( @SKIP_DIR );

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
            @newfiles = grep { not $SKIP_DIR{$_} } @newfiles;
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
    return 1 if $file =~ m{ [.] swp \z}xms;
    return 1 if $file =~ m{ [.] bak \z}xms;
    return 1 if $file =~ m{  ~ \z}xms;
    return 1 if $file =~ m{ \A [#] .+ [#] \z}xms;
    return;
}

#-----------------------------------------------------------------------------
# Returns true if the argument ends with a perl-ish file
# extension, or if it has a shebang-line containing 'perl' This
# subroutine was also poached from Test::Perl::Critic

sub _is_perl {
    my ($file) = @_;

    #Check filename extensions
    return 1 if $file =~ m{ [.] PL    \z}xms;
    return 1 if $file =~ m{ [.] p[lm] \z}xms;
    return 1 if $file =~ m{ [.] t     \z}xms;

    #Check for shebang
    open my $fh, '<', $file or return;
    my $first = <$fh>;
    close $fh or throw_generic "unable to close $file: $OS_ERROR";

    return 1 if defined $first && ( $first =~ m{ \A [#]!.*perl }xms );
    return;
}

#-----------------------------------------------------------------------------

sub shebang_line {
    my $doc = shift;
    my $first_element = $doc->first_element();
    return if not $first_element;
    return if not $first_element->isa('PPI::Token::Comment');
    my $location = $first_element->location();
    return if !$location;
    # The shebang must be the first two characters in the file, according to
    # http://en.wikipedia.org/wiki/Shebang_(Unix)
    return if $location->[0] != 1; # line number
    return if $location->[1] != 1; # column number
    my $shebang = $first_element->content;
    return if $shebang !~ m{ \A [#]! }xms;
    return $shebang;
}

#-----------------------------------------------------------------------------

sub words_from_string {
    my $str = shift;

    return split q{ }, $str; # This must be a literal space, not $SPACE
}

#-----------------------------------------------------------------------------

Readonly::Hash my %ASSIGNMENT_OPERATORS => hashify( qw( = **= += -= .= *= /= %= x= &= |= ^= <<= >>= &&= ||= //= ) );

sub is_assignment_operator {
    my $elem = shift;

    return $ASSIGNMENT_OPERATORS{ $elem };
}

#-----------------------------------------------------------------------------

sub is_unchecked_call {
    my $elem = shift;

    return if not is_function_call( $elem );

    # check to see if there's an '=' or 'unless' or something before this.
    if( my $sib = $elem->sprevious_sibling() ){
        return if $sib;
    }


    if( my $statement = $elem->statement() ){

        # "open or die" is OK.
        # We can't check snext_sibling for 'or' since the next siblings are an
        # unknown number of arguments to the system call. Instead, check all of
        # the elements to this statement to see if we find 'or' or '||'.

        my $or_operators = sub  {
            my (undef, $elem) = @_;  ## no critic(Variables::ProhibitReusedNames)
            return if not $elem->isa('PPI::Token::Operator');
            return if $elem ne q{or} && $elem ne q{||};
            return 1;
        };

        return if $statement->find( $or_operators );


        if( my $parent = $elem->statement()->parent() ){

            # Check if we're in an if( open ) {good} else {bad} condition
            return if $parent->isa('PPI::Structure::Condition');

            # Return val could be captured in data structure and checked later
            return if $parent->isa('PPI::Structure::Constructor');

            # "die if not ( open() )" - It's in list context.
            if ( $parent->isa('PPI::Structure::List') ) {
                if( my $uncle = $parent->sprevious_sibling() ){
                    return if $uncle;
                }
            }
        }
    }

    return if _is_fatal($elem);

    # Otherwise, return. this system call is unchecked.
    return 1;
}

# Based upon autodie 2.10.
Readonly::Hash my %AUTODIE_PARAMETER_TO_AFFECTED_BUILTINS_MAP => (
    # Map builtins to themselves.
    (
        map { $_ => { hashify( $_ ) } }
            qw<
                accept bind binmode chdir chmod close closedir connect
                dbmclose dbmopen exec fcntl fileno flock fork getsockopt ioctl
                link listen mkdir msgctl msgget msgrcv msgsnd open opendir
                pipe read readlink recv rename rmdir seek semctl semget semop
                send setsockopt shmctl shmget shmread shutdown socketpair
                symlink sysopen sysread sysseek system syswrite truncate umask
                unlink
            >
    ),

    # Generate these using tools/dump-autodie-tag-contents
    ':threads'      => { hashify( qw< fork                          > ) },
    ':system'       => { hashify( qw< exec system                   > ) },
    ':dbm'          => { hashify( qw< dbmclose dbmopen              > ) },
    ':semaphore'    => { hashify( qw< semctl semget semop           > ) },
    ':shm'          => { hashify( qw< shmctl shmget shmread         > ) },
    ':msg'          => { hashify( qw< msgctl msgget msgrcv msgsnd   > ) },
    ':file'     => {
        hashify(
            qw<
                binmode chmod close fcntl fileno flock ioctl open sysopen
                truncate
            >
        )
    },
    ':filesys'      => {
        hashify(
            qw<
                chdir closedir link mkdir opendir readlink rename rmdir
                symlink umask unlink
            >
        )
    },
    ':ipc'      => {
        hashify(
            qw<
                msgctl msgget msgrcv msgsnd pipe semctl semget semop shmctl
                shmget shmread
            >
        )
    },
    ':socket'       => {
        hashify(
            qw<
                accept bind connect getsockopt listen recv send setsockopt
                shutdown socketpair
            >
        )
    },
    ':io'       => {
        hashify(
            qw<
                accept bind binmode chdir chmod close closedir connect
                dbmclose dbmopen fcntl fileno flock getsockopt ioctl link
                listen mkdir msgctl msgget msgrcv msgsnd open opendir pipe
                read readlink recv rename rmdir seek semctl semget semop send
                setsockopt shmctl shmget shmread shutdown socketpair symlink
                sysopen sysread sysseek syswrite truncate umask unlink
            >
        )
    },
    ':default'      => {
        hashify(
            qw<
                accept bind binmode chdir chmod close closedir connect
                dbmclose dbmopen fcntl fileno flock fork getsockopt ioctl link
                listen mkdir msgctl msgget msgrcv msgsnd open opendir pipe
                read readlink recv rename rmdir seek semctl semget semop send
                setsockopt shmctl shmget shmread shutdown socketpair symlink
                sysopen sysread sysseek syswrite truncate umask unlink
            >
        )
    },
    ':all'      => {
        hashify(
            qw<
                accept bind binmode chdir chmod close closedir connect
                dbmclose dbmopen exec fcntl fileno flock fork getsockopt ioctl
                link listen mkdir msgctl msgget msgrcv msgsnd open opendir
                pipe read readlink recv rename rmdir seek semctl semget semop
                send setsockopt shmctl shmget shmread shutdown socketpair
                symlink sysopen sysread sysseek system syswrite truncate umask
                unlink
            >
        )
    },
);

sub _is_fatal {
    my ($elem) = @_;

    my $top = $elem->top();
    return if not $top->isa('PPI::Document');

    my $includes = $top->find('PPI::Statement::Include');
    return if not $includes;

    for my $include (@{$includes}) {
        next if 'use' ne $include->type();

        if ('Fatal' eq $include->module()) {
            my @args = parse_arg_list($include->schild(1));
            foreach my $arg (@args) {
                return $TRUE if $arg->[0]->isa('PPI::Token::Quote') && $elem eq $arg->[0]->string();
            }
        }
        elsif ('Fatal::Exception' eq $include->module()) {
            my @args = parse_arg_list($include->schild(1));
            shift @args;  # skip exception class name
            foreach my $arg (@args) {
                return $TRUE if $arg->[0]->isa('PPI::Token::Quote') && $elem eq $arg->[0]->string();
            }
        }
        elsif ('autodie' eq $include->pragma()) {
            return _is_covered_by_autodie($elem, $include);
        }
    }

    return;
}

sub _is_covered_by_autodie {
    my ($elem, $include) = @_;

    my $autodie = $include->schild(1);
    my @args = parse_arg_list($autodie);
    my $first_arg = first_arg($autodie);

    # The first argument to any `use` pragma could be a version number.
    # If so, then we just discard it. We only want the arguments after it.
    if ($first_arg and $first_arg->isa('PPI::Token::Number')){ shift @args };

    if (@args) {
        foreach my $arg (@args) {
            my $builtins =
                $AUTODIE_PARAMETER_TO_AFFECTED_BUILTINS_MAP{
                    $arg->[0]->string
                };

            return $TRUE if $builtins and $builtins->{$elem->content()};
        }
    }
    else {
        my $builtins =
            $AUTODIE_PARAMETER_TO_AFFECTED_BUILTINS_MAP{':default'};

        return $TRUE if $builtins and $builtins->{$elem->content()};
    }

    return;
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Utils - General utility subroutines and constants for Perl::Critic and derivative distributions.


=head1 DESCRIPTION

This module provides several static subs and variables that are useful
for developing L<Perl::Critic::Policy|Perl::Critic::Policy>
subclasses.  Unless you are writing Policy modules, you probably don't
care about this package.


=head1 INTERFACE SUPPORT

This is considered to be a public module.  Any changes to its
interface will go through a deprecation cycle.


=head1 IMPORTABLE SUBS

=over

=item C<find_keywords( $doc, $keyword )>

B<DEPRECATED:> Since version 0.11, every Policy is evaluated at each
element of the document.  So you shouldn't need to go looking for a
particular keyword.  If you I<do> want to use this, please import it
via the C<:deprecated> tag, rather than directly, to mark the module
as needing updating.

Given a L<PPI::Document|PPI::Document> as C<$doc>, returns a reference
to an array containing all the L<PPI::Token::Word|PPI::Token::Word>
elements that match C<$keyword>.  This can be used to find any
built-in function, method call, bareword, or reserved keyword.  It
will not match variables, subroutine names, literal strings, numbers,
or symbols.  If the document doesn't contain any matches, returns
undef.

=item C<is_assignment_operator( $element )>

Given a L<PPI::Token::Operator|PPI::Token::Operator> or a string,
returns true if that token represents one of the assignment operators
(e.g. C<= &&= ||= //= += -=> etc.).

=item C<is_perl_global( $element )>

Given a L<PPI::Token::Symbol|PPI::Token::Symbol> or a string, returns
true if that token represents one of the global variables provided by
the L<English|English> module, or one of the builtin global variables
like C<%SIG>, C<%ENV>, or C<@ARGV>.  The sigil on the symbol is
ignored, so things like C<$ARGV> or C<$ENV> will still return true.


=item C<is_perl_builtin( $element )>

Given a L<PPI::Token::Word|PPI::Token::Word>,
L<PPI::Statement::Sub|PPI::Statement::Sub>, or string, returns true if
that token represents a call to any of the builtin functions defined
in Perl 5.8.8.


=item C<is_perl_bareword( $element )>

Given a L<PPI::Token::Word|PPI::Token::Word>,
L<PPI::Statement::Sub|PPI::Statement::Sub>, or string, returns true if
that token represents a bareword (e.g. "if", "else", "sub", "package")
defined in Perl 5.8.8.


=item C<is_perl_filehandle( $element )>

Given a L<PPI::Token::Word|PPI::Token::Word>, or string, returns true
if that token represents one of the global filehandles (e.g. C<STDIN>,
C<STDERR>, C<STDOUT>, C<ARGV>) that are defined in Perl 5.8.8.  Note
that this function will return false if given a filehandle that is
represented as a typeglob (e.g. C<*STDIN>)


=item C<is_perl_builtin_with_list_context( $element )>

Given a L<PPI::Token::Word|PPI::Token::Word>,
L<PPI::Statement::Sub|PPI::Statement::Sub>, or string, returns true if
that token represents a call to any of the builtin functions defined
in Perl 5.8.8 that provide a list context to the following tokens.


=item C<is_perl_builtin_with_multiple_arguments( $element )>

Given a L<PPI::Token::Word|PPI::Token::Word>,
L<PPI::Statement::Sub|PPI::Statement::Sub>, or string, returns true if
that token represents a call to any of the builtin functions defined
in Perl 5.8.8 that B<can> take multiple arguments.


=item C<is_perl_builtin_with_no_arguments( $element )>

Given a L<PPI::Token::Word|PPI::Token::Word>,
L<PPI::Statement::Sub|PPI::Statement::Sub>, or string, returns true if
that token represents a call to any of the builtin functions defined
in Perl 5.8.8 that B<cannot> take any arguments.


=item C<is_perl_builtin_with_one_argument( $element )>

Given a L<PPI::Token::Word|PPI::Token::Word>,
L<PPI::Statement::Sub|PPI::Statement::Sub>, or string, returns true if
that token represents a call to any of the builtin functions defined
in Perl 5.8.8 that takes B<one and only one> argument.


=item C<is_perl_builtin_with_optional_argument( $element )>

Given a L<PPI::Token::Word|PPI::Token::Word>,
L<PPI::Statement::Sub|PPI::Statement::Sub>, or string, returns true if
that token represents a call to any of the builtin functions defined
in Perl 5.8.8 that takes B<no more than one> argument.

The sets of values for which
C<is_perl_builtin_with_multiple_arguments()>,
C<is_perl_builtin_with_no_arguments()>,
C<is_perl_builtin_with_one_argument()>, and
C<is_perl_builtin_with_optional_argument()> return true are disjoint
and their union is precisely the set of values that
C<is_perl_builtin()> will return true for.


=item C<is_perl_builtin_with_zero_and_or_one_arguments( $element )>

Given a L<PPI::Token::Word|PPI::Token::Word>,
L<PPI::Statement::Sub|PPI::Statement::Sub>, or string, returns true if
that token represents a call to any of the builtin functions defined
in Perl 5.8.8 that takes no and/or one argument.

Returns true if any of C<is_perl_builtin_with_no_arguments()>,
C<is_perl_builtin_with_one_argument()>, and
C<is_perl_builtin_with_optional_argument()> returns true.


=item C<is_qualified_name( $name )>

Given a string, L<PPI::Token::Word|PPI::Token::Word>, or
L<PPI::Token::Symbol|PPI::Token::Symbol>, answers whether it has a
module component, i.e. contains "::".


=item C<precedence_of( $element )>

Given a L<PPI::Token::Operator|PPI::Token::Operator> or a string,
returns the precedence of the operator, where 1 is the highest
precedence.  Returns undef if the precedence can't be determined
(which is usually because it is not an operator).


=item C<is_hash_key( $element )>

Given a L<PPI::Element|PPI::Element>, returns true if the element is a
literal hash key.  PPI doesn't distinguish between regular barewords
(like keywords or subroutine calls) and barewords in hash subscripts
(which are considered literal).  So this subroutine is useful if your
Policy is searching for L<PPI::Token::Word|PPI::Token::Word> elements
and you want to filter out the hash subscript variety.  In both of the
following examples, "foo" is considered a hash key:

    $hash1{foo} = 1;
    %hash2 = (foo => 1);

But if the bareword is followed by an argument list, then perl treats
it as a function call.  So in these examples, "foo" is B<not>
considered a hash key:

    $hash1{ foo() } = 1;
    &hash2 = (foo() => 1);


=item C<is_included_module_name( $element )>

Given a L<PPI::Token::Word|PPI::Token::Word>, returns true if the
element is the name of a module that is being included via C<use>,
C<require>, or C<no>.


=item C<is_integer( $value )>

Answers whether the parameter, as a string, looks like an integral
value.


=item C<is_class_name( $element )>

Given a L<PPI::Token::Word|PPI::Token::Word>, returns true if the
element that immediately follows this element is the dereference
operator "->". When a bareword has a "->" on the B<right> side, it
usually means that it is the name of the class (from which a method is
being called).


=item C<is_label_pointer( $element )>

Given a L<PPI::Token::Word|PPI::Token::Word>, returns true if the
element is the label in a C<next>, C<last>, C<redo>, or C<goto>
statement.  Note this is not the same thing as the label declaration.


=item C<is_method_call( $element )>

Given a L<PPI::Token::Word|PPI::Token::Word>, returns true if the
element that immediately precedes this element is the dereference
operator "->". When a bareword has a "->" on the B<left> side, it
usually means that it is the name of a method (that is being called
from a class).


=item C<is_package_declaration( $element )>

Given a L<PPI::Token::Word|PPI::Token::Word>, returns true if the
element is the name of a package that is being declared.


=item C<is_subroutine_name( $element )>

Given a L<PPI::Token::Word|PPI::Token::Word>, returns true if the
element is the name of a subroutine declaration.  This is useful for
distinguishing barewords and from function calls from subroutine
declarations.


=item C<is_function_call( $element )>

Given a L<PPI::Token::Word|PPI::Token::Word> returns true if the
element appears to be call to a static function.  Specifically, this
function returns true if C<is_hash_key>, C<is_method_call>,
C<is_subroutine_name>, C<is_included_module_name>,
C<is_package_declaration>, C<is_perl_bareword>, C<is_perl_filehandle>,
C<is_label_pointer> and C<is_subroutine_name> all return false for the
given element.


=item C<first_arg( $element )>

Given a L<PPI::Element|PPI::Element> that is presumed to be a function
call (which is usually a L<PPI::Token::Word|PPI::Token::Word>), return
the first argument.  This is similar of C<parse_arg_list()> and
follows the same logic.  Note that for the code:

    int($x + 0.5)

this function will return just the C<$x>, not the whole expression.
This is different from the behavior of C<parse_arg_list()>.  Another
caveat is:

    int(($x + $y) + 0.5)

which returns C<($x + $y)> as a
L<PPI::Structure::List|PPI::Structure::List> instance.


=item C<parse_arg_list( $element )>

Given a L<PPI::Element|PPI::Element> that is presumed to be a function
call (which is usually a L<PPI::Token::Word|PPI::Token::Word>), splits
the argument expressions into arrays of tokens.  Returns a list
containing references to each of those arrays.  This is useful because
parentheses are optional when calling a function, and PPI parses them
very differently.  So this method is a poor-man's parse tree of PPI
nodes.  It's not bullet-proof because it doesn't respect precedence.
In general, I don't like the way this function works, so don't count
on it to be stable (or even present).


=item C<split_nodes_on_comma( @nodes )>

This has the same return type as C<parse_arg_list()> but expects to be
passed the nodes that represent the interior of a list, like:

    'foo', 1, 2, 'bar'


=item C<is_script( $document )>

B<This subroutine is deprecated and will be removed in a future release.> You
should use the L<Perl::Critic::Document/"is_program()"> method instead.


=item C<is_in_void_context( $token )>

Given a L<PPI::Token|PPI::Token>, answer whether it appears to be in a
void context.


=item C<policy_long_name( $policy_name )>

Given a policy class name in long or short form, return the long form.


=item C<policy_short_name( $policy_name )>

Given a policy class name in long or short form, return the short
form.


=item C<all_perl_files( @directories )>

Given a list of directories, recursively searches through all the
directories (depth first) and returns a list of paths for all the
files that are Perl code files.  Any administrative files for CVS or
Subversion are skipped, as are things that look like temporary or
backup files.

A Perl code file is:

=over

=item * Any file that ends in F<.PL>, F<.pl>, F<.pm>, or F<.t>

=item * Any file that has a first line with a shebang containing 'perl'

=back


=item C<severity_to_number( $severity )>

If C<$severity> is given as an integer, this function returns
C<$severity> but normalized to lie between C<$SEVERITY_LOWEST> and
C<$SEVERITY_HIGHEST>.  If C<$severity> is given as a string, this
function returns the corresponding severity number.  If the string
doesn't have a corresponding number, this function will throw an
exception.


=item C<is_valid_numeric_verbosity( $severity )>

Answers whether the argument has a translation to a Violation format.


=item C<verbosity_to_format( $verbosity_level )>

Given a verbosity level between 1 and 10, returns the corresponding
predefined format string.  These formats are suitable for passing to
the C<set_format> method in
L<Perl::Critic::Violation|Perl::Critic::Violation>.  See the
L<perlcritic|perlcritic> documentation for a listing of the predefined
formats.


=item C<hashify( @list )>

Given C<@list>, return a hash where C<@list> is in the keys and each
value is 1.  Duplicate values in C<@list> are silently squished.


=item C<interpolate( $literal )>

Given a C<$literal> string that may contain control characters (e.g..
'\t' '\n'), this function does a double interpolation on the string
and returns it as if it had been declared in double quotes.  For
example:

    'foo \t bar \n' ...becomes... "foo \t bar \n"


=item C<shebang_line( $document )>

Given a L<PPI::Document|PPI::Document>, test if it starts with C<#!>.
If so, return that line.  Otherwise return undef.


=item C<words_from_string( $str )>

Given config string I<$str>, return all the words from the string.
This is safer than splitting on whitespace.


=item C<is_unchecked_call( $element )>

Given a L<PPI::Element|PPI::Element>, test to see if it contains a
function call whose return value is not checked.


=back


=head1 IMPORTABLE VARIABLES

=over

=item C<$COMMA>

=item C<$FATCOMMA>

=item C<$COLON>

=item C<$SCOLON>

=item C<$QUOTE>

=item C<$DQUOTE>

=item C<$BACKTICK>

=item C<$PERIOD>

=item C<$PIPE>

=item C<$EMPTY>

=item C<$EQUAL>

=item C<$SPACE>

=item C<$SLASH>

=item C<$BSLASH>

=item C<$LEFT_PAREN>

=item C<$RIGHT_PAREN>

These character constants give clear names to commonly-used strings
that can be hard to read when surrounded by quotes and other
punctuation.  Can be imported in one go via the C<:characters> tag.

=item C<$SEVERITY_HIGHEST>

=item C<$SEVERITY_HIGH>

=item C<$SEVERITY_MEDIUM>

=item C<$SEVERITY_LOW>

=item C<$SEVERITY_LOWEST>

These numeric constants define the relative severity of violating each
L<Perl::Critic::Policy|Perl::Critic::Policy>.  The C<get_severity> and
C<default_severity> methods of every Policy subclass must return one
of these values. Can be imported via the C<:severities> tag.

=item C<$DEFAULT_VERBOSITY>

The default numeric verbosity.

=item C<$DEFAULT_VERBOSITY_WITH_FILE_NAME>

The numeric verbosity that corresponds to the format indicated by
C<$DEFAULT_VERBOSITY>, but with the file name prefixed to it.

=item C<$TRUE>

=item C<$FALSE>

These are simple booleans. 1 and 0 respectively.  Be mindful of using
these with string equality.  C<$FALSE ne $EMPTY>.  Can be imported via
the C<:booleans> tag.


=back


=head1 IMPORT TAGS

The following groups of functions and constants are available as
parameters to a C<use Perl::Critic::Util> statement.

=over

=item C<:all>

The lot.


=item C<:booleans>

Includes:
C<$TRUE>, C<$FALSE>


=item C<:severities>

Includes:
C<$SEVERITY_HIGHEST>,
C<$SEVERITY_HIGH>,
C<$SEVERITY_MEDIUM>,
C<$SEVERITY_LOW>,
C<$SEVERITY_LOWEST>,
C<@SEVERITY_NAMES>


=item C<:characters>

Includes:
C<$COLON>,
C<$COMMA>,
C<$DQUOTE>,
C<$EMPTY>,
C<$FATCOMMA>,
C<$PERIOD>,
C<$PIPE>,
C<$QUOTE>,
C<$BACKTICK>,
C<$SCOLON>,
C<$SPACE>,
C<$SLASH>,
C<$BSLASH>
C<$LEFT_PAREN>
C<$RIGHT_PAREN>


=item C<:classification>

Includes:
C<is_function_call>,
C<is_hash_key>,
C<is_included_module_name>,
C<is_integer>,
C<is_method_call>,
C<is_package_declaration>,
C<is_perl_builtin>,
C<is_perl_global>,
C<is_perl_builtin_with_list_context>
C<is_perl_builtin_with_multiple_arguments>
C<is_perl_builtin_with_no_arguments>
C<is_perl_builtin_with_one_argument>
C<is_perl_builtin_with_optional_argument>
C<is_perl_builtin_with_zero_and_or_one_arguments>
C<is_script>,
C<is_subroutine_name>,
C<is_unchecked_call>
C<is_valid_numeric_verbosity>

See also L<Perl::Critic::Utils::PPI|Perl::Critic::Utils::PPI>.


=item C<:data_conversion>

Generic manipulation, not having anything specific to do with
Perl::Critic.

Includes:
C<hashify>,
C<words_from_string>,
C<interpolate>


=item C<:ppi>

Things for dealing with L<PPI|PPI>, other than classification.

Includes:
C<first_arg>,
C<parse_arg_list>

See also L<Perl::Critic::Utils::PPI|Perl::Critic::Utils::PPI>.


=item C<:internal_lookup>

Translations between internal representations.

Includes:
C<severity_to_number>,
C<verbosity_to_format>


=item C<:language>

Information about Perl not programmatically available elsewhere.

Includes:
C<precedence_of>


=item C<:deprecated>

Not surprisingly, things that are deprecated.  It is preferred to use
this tag to get to these functions, rather than the function names
themselves, so as to mark any module using them as needing cleanup.

Includes:
C<find_keywords>


=back


=head1 SEE ALSO

L<Perl::Critic::Utils::Constants|Perl::Critic::Utils::Constants>,
L<Perl::Critic::Utils::McCabe|Perl::Critic::Utils::McCabe>,
L<Perl::Critic::Utils::PPI|Perl::Critic::Utils::PPI>,


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2005-2011 Imaginative Software Systems.  All rights reserved.

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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
