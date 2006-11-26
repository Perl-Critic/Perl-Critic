=name Basic passes

=failures 0

=cut

%hash   = %{ $some_ref };
@array  = @{ $some_ref };
$scalar = ${ $some_ref };

$some_ref = \%hash;
$some_ref = \@array;
$some_ref = \$scalar;
$some_ref = \&code;

#----------------------------------------------------------------

=name Basic failures

=failures 6

=cut

%hash   = %$some_ref;
%array  = @$some_ref;
%scalar = $$some_ref;

%hash   = ( %$some_ref );
%array  = ( @$some_ref );
%scalar = ( $$some_ref );

#----------------------------------------------------------------

=name Multiplication is not a glob

old PPI bug (fixed as of PPI v1.112): multiplication is mistakenly
interpreted as a glob.

=failures 0

=cut

$value = $one*$two;
