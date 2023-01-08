package Perl::Critic::BuildUtilities 1.150;

use 5.010001;
use strict;
use warnings;

use English q<-no_match_vars>;

use Exporter 'import';

our @EXPORT_OK = qw<
    required_module_versions
    test_required_module_versions
    configure_required_module_versions
    emit_tar_warning_if_necessary
    get_PL_files
>;


use Devel::CheckOS qw< os_is >;


sub required_module_versions {
    return (
        'B::Keywords'                   => 1.23,
        'Carp'                          => 0,
        'Config::Tiny'                  => 2,
        'English'                       => 0,
        'Exception::Class'              => 1.23,
        'Exporter'                      => 5.63,
        'File::Basename'                => 0,
        'File::Find'                    => 0,
        'File::Path'                    => 0,
        'File::Spec'                    => 0,
        'File::Spec::Unix'              => 0,
        'File::Temp'                    => 0,
        'File::Which'                   => 0, # Only for PodSpelling
        'Getopt::Long'                  => 0,
        'List::SomeUtils'               => '0.55',
        'List::Util'                    => 0,
        'Module::Pluggable'             => 3.1,
        'PPI'                           => '1.271',
        'PPI::Document'                 => '1.271',
        'PPI::Document::File'           => '1.271',
        'PPI::Node'                     => '1.271',
        'PPI::Token::Quote::Single'     => '1.271',
        'PPI::Token::Whitespace'        => '1.271',
        'PPIx::QuoteLike'               => 0,
        'PPIx::Regexp'                  => '0.027', # Literal { deprecated in re
        'PPIx::Regexp::Util'            => '0.068', # is_ppi_regexp_element()
        'PPIx::Utilities::Node'         => '1.001',
        'PPIx::Utilities::Statement'    => '1.001',
        'Perl::Tidy'                    => 0, # Only for RequireTidyCode
        'Pod::PlainText'                => 0,
        'Pod::Select'                   => 0,
        'Pod::Spell'                    => 1, # Only for PodSpelling
        'Pod::Usage'                    => 0,
        'Readonly'                      => 2.00,
        'Scalar::Util'                  => 0,
        'String::Format'                => '1.18',
        'Term::ANSIColor'               => '2.02',
        'Test::Builder'                 => 0.92,
        'Text::ParseWords'              => 3,
        'charnames'                     => 0,
        'overload'                      => 0,
        'parent'                        => 0,
        'perl'                          => 5.010001,
        'strict'                        => 0,
        'version'                       => 0.77,
        'warnings'                      => 0,
    );
}


sub test_required_module_versions {
    return (
        'Test::More'    => 0,
        'lib'           => 0,
    );
}


sub configure_required_module_versions {
    return (
        'Carp'          => 0,
        'English'       => 0,
        'Exporter'      => '5.63',
        'Module::Build' => '0.4204',
        'base'          => 0,
        'lib'           => 0,
    );
}


my @TARGET_FILES = qw<
    t/ControlStructures/ProhibitNegativeExpressionsInUnlessAndUntilConditions.run
    t/NamingConventions/Capitalization.run
    t/Variables/RequireLocalizedPunctuationVars.run
>;

sub get_PL_files {
    my %PL_files = map { ( "$_.PL" => $_ ) } @TARGET_FILES;

    return \%PL_files;
}

sub emit_tar_warning_if_necessary {
    if ( os_is( qw<Solaris> ) ) {
        print <<'END_OF_TAR_WARNING';
NOTE: tar(1) on some Solaris systems cannot deal well with long file
names.

If you get warnings about missing files below, please ensure that you
extracted the Perl::Critic tarball using GNU tar.

END_OF_TAR_WARNING
    }
}




1;

__END__

=head1 NAME

Perl::Critic::BuildUtilities - Common bits of compiling Perl::Critic.


=head1 DESCRIPTION

Various utilities used in assembling Perl::Critic, primary for use by
*.PL programs that generate code.


=head1 IMPORTABLE SUBROUTINES

=over

=item C<get_PL_files()>

Returns a reference to a hash with a mapping from the name of a .PL
program to an array of the parameters to be passed to it, suited for
use by L<Module::Build::API/"PL_files"> or
L<ExtUtils::MakeMaker/"PL_FILES">.  May print to C<STDOUT> messages
about what it is doing.


=item C<dump_unlisted_or_optional_module_versions()>

Prints to C<STDOUT> a list of all the unlisted (e.g. things in core
like L<Exporter|Exporter>), optional (e.g.
L<File::Which|File::Which>), or potentially indirect (e.g.
L<Readonly::XS|Readonly::XS>) dependencies, plus their versions, if
they're installed.


=item C<emit_tar_warning_if_necessary()>

On some Solaris systems, C<tar(1)> can't deal with long file names and
thus files are not correctly extracted from the tarball.  So this
prints a warning if the current system is Solaris.


=back


=head1 AUTHOR

Elliot Shank  C<< <perl@galumph.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007-2023, Elliot Shank.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
