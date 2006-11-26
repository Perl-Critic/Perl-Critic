=name Basic

=failures 10

=cut

use English;
use English qw($PREMATCH);
use English qw($MATCH);
use English qw($POSTMATCH);
$`;
$&;
$';
$PREMATCH;
$MATCH;
$POSTMATCH;


=name no_match_vars

=failures 0

=cut

use English qw(-no_match_vars);
use English qw($EVAL_ERROR);
