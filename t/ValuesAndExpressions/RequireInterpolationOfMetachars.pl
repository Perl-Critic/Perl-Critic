=name Basic passing

=failures 0

=cut

print "this is not $literal";
print qq{this is not $literal};
print "this is not literal\n";
print qq{this is not literal\n};

#----------------------------------------------------------------

=name Basic failure

=failures 4

=cut

print 'this is not $literal';
print q{this is not $literal};
print 'this is not literal\n';
print q{this is not literal\n};

#----------------------------------------------------------------

=name Sigil characters not looking like sigils

=failures 0

=cut

$sigil_at_end_of_word = 'list@ scalar$';
$sigil_at_end_of_word = 'scalar$ list@';
$sigil_at_end_of_word = q(list@ scalar$);
$sigil_at_end_of_word = q(scalar$ list@);
%options = (  'foo=s@' => \@foo);  #Like with Getopt::Long
%options = ( q{foo=s@} => \@foo);  #Like with Getopt::Long

#----------------------------------------------------------------

##################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##################################################################

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
