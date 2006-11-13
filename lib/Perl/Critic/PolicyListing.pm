###############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/Perl-Critic/bin/
#     $Date: 2006-11-12 16:25:00 -0800 (Sun, 12 Nov 2006) $
#   $Author: thaljef $
# $Revision: 851 $
#        ex: set ts=8 sts=4 sw=4 expandtab
##############################################################################

package Perl::Critic::PolicyListing;

use strict;
use warnings;
use Carp qw(carp confess);
use English qw(-no_match_vars);


#-----------------------------------------------------------------------------

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    my $policies = $args{-policies} || [];
    $self->{_policies} = [ sort _by_type @{ $policies } ];
    return $self;
}

#-----------------------------------------------------------------------------

sub short_listing {
    my $self = shift;
    local $Perl::Critic::Policy::FORMAT =  _short_format();
    return map { "$_" } @{ $self->{_policies} };
}


#-----------------------------------------------------------------------------

sub long_listing {
    my $self = shift;
    local $Perl::Critic::Policy::FORMAT =  _long_format();
    return map { "$_" } @{ $self->{_policies} };
}

#-----------------------------------------------------------------------------

sub _short_format {
    return "%s %p [%t]\n";
}

#-----------------------------------------------------------------------------

sub _long_format {
    return <<'END_OF_FORMAT';
[%P]
set_themes = %t
severity   = %s

END_OF_FORMAT

}

#-----------------------------------------------------------------------------

sub _by_type { return ref $a cmp ref $b }

1;

__END__
