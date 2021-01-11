# Validate with cpanfile-dump
# https://metacpan.org/release/Module-CPANfile
# https://metacpan.org/pod/distribution/Module-CPANfile/lib/cpanfile.pod

requires 'B::Keywords'                => '1.05';
requires 'Carp'                       => 0;
requires 'Config::Tiny'               => 2;
requires 'English'                    => 0;
requires 'Exception::Class'           => '1.23';
requires 'Exporter'                   => '5.63';
requires 'Fatal'                      => 0;
requires 'File::Basename'             => 0;
requires 'File::Find'                 => 0;
requires 'File::Path'                 => 0;
requires 'File::Spec'                 => 0;
requires 'File::Spec::Unix'           => 0;
requires 'File::Temp'                 => 0;
requires 'File::Which'                => 0;
requires 'Getopt::Long'               => 0;
requires 'IO::String'                 => 0;
requires 'IPC::Open2'                 => 1;
requires 'List::MoreUtils'            => '0.19';
requires 'List::Util'                 => 0;
requires 'Module::Build'              => '0.4204';
requires 'Module::Pluggable'          => '3.1';
requires 'PPI'                        => '1.265';
requires 'PPI::Document'              => '1.265';
requires 'PPI::Document::File'        => '1.265';
requires 'PPI::Node'                  => '1.265';
requires 'PPI::Token::Quote::Single'  => '1.265';
requires 'PPI::Token::Whitespace'     => '1.265';
requires 'PPIx::QuoteLike'            => 0;
requires 'PPIx::Regexp'               => '0.027'; # Literal { deprecated in re
requires 'PPIx::Regexp::Util'         => '0.068'; # is_ppi_regexp_element()
requires 'PPIx::Utilities::Node'      => '1.001';
requires 'PPIx::Utilities::Statement' => '1.001';
requires 'Perl::Tidy'                 => 0;
requires 'Pod::Parser'                => 0;
requires 'Pod::PlainText'             => 0;
requires 'Pod::Select'                => 0;
requires 'Pod::Spell'                 => 1;
requires 'Pod::Usage'                 => 0;
requires 'Readonly'                   => '2.00';
requires 'Scalar::Util'               => 0;
requires 'String::Format'             => '1.18';
requires 'Task::Weaken'               => 0;
requires 'Term::ANSIColor'            => '2.02';
requires 'Test::Builder'              => '0.92';
requires 'Text::ParseWords'           => 3;
requires 'base'                       => 0;
requires 'charnames'                  => 0;
requires 'overload'                   => 0;
requires 'strict'                     => 0;
requires 'version'                    => '0.77';
requires 'warnings'                   => 0;

on 'test' => sub {
    requires 'Test::Deep' => 0;
    requires 'Test::More' => 0;

    # For author testing
    requires 'Devel::EnforceEncapsulation' => 0;
    requires 'Test::Kwalitee'              => 0;
    requires 'Test::Memory::Cycle'         => 0;
    requires 'Test::Perl::Critic'          => 0;
    requires 'Test::Pod'                   => 0;
    requires 'Test::Pod::Coverage'         => 0;
};


# vi:et:sw=4 ts=4 ft=perl
