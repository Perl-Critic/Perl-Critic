##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

use 5.006001;
use strict;
use warnings;

use PPI::Document;
use Test::More;

#-----------------------------------------------------------------------------

our $VERSION = '1.098';

#-----------------------------------------------------------------------------

plan( skip_all => 'Need PPI version 1.203 to test optimizations')
  if $PPI::Document::VERSION ne '1.203';

#-----------------------------------------------------------------------------

plan( tests => 2 );
use_ok('Perl::Critic::PPIx::SpeedHacks');
my $code = q{print "Hello World" && wave($hand);};
my $doc = PPI::Document->new(\$code);
my $found_elems = PPI::Node::find($doc, 'PPI::Element');
my @descendant_elems = $doc->descendants();
is_deeply($found_elems, \@descendant_elems, 'find() and descdendants() return the same thing.');

#-----------------------------------------------------------------------------

# ensure we run true if this test is loaded by
# t/05_utils_ppi.t_without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
