=name basics

=failures 3

=cut

local $foo = $bar;
local ($foo, $bar) = ();
local ($foo, %SIG);

#----------------------------------------------------------------

=name exceptions

=failures 0

=cut

local $/ = undef;
local $| = 1;
local ($/) = undef;
local ($RS, $>) = ();
local ($RS);
local $INPUT_RECORD_SEPARATOR;
local $PROGRAM_NAME;
local ($EVAL_ERROR, $OS_ERROR);
local $Other::Package::foo;
local (@Other::Package::foo, $EVAL_ERROR);
my  $var1 = 'foo';
our $var2 = 'bar';
local $SIG{HUP} \&handler;
local $INC{$module} = $path;
