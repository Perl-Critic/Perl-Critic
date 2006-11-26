=name Basic

=failures 6

=cut

local $foo;
local ($foo, $bar);

local $|;
local ($|, $$);

local $OUTPUT_RECORD_SEPARATOR;
local ($OUTPUT_RECORD_SEPARATOR, $PROGRAM_NAME);

#----------------------------------------------------------------

=name Initialized passes

=failures 0

=cut

local $foo = 'foo';
local ($foo, $bar) = 'foo';       #Not right, but still passes
local ($foo, $bar) = qw(foo bar);

my $foo;
my ($foo, $bar);
our $bar
our ($foo, $bar);

#----------------------------------------------------------------

=name key named "local"

=TODO PPI bug prevents this from working

=failures 0

=cut

$x->{local};
