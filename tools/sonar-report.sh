#!/bin/bash

set -e # Exit with nonzero exit code if anything fails

# make sure Devel::Cover::Report::Clover and Perl::Critic are installed locally.
cpanm --notest Devel::Cover::Report::Clover Perl::Critic

# run tests and generate coverage and TAP report
HARNESS_OPTIONS="j:c:a_build/testReport.tgz" HARNESS_PERL_SWITCHES="-MDevel::Cover" ./Build test

# extract clover.xml report from cover_db
cover -report clover

# make sure we map the reported coverage on lib and not blib/lib
sed -i 's#blib/lib#lib#' cover_db/clover.xml

# self-critique with "core" theme
perlcritic --gentle --theme core --quiet --verbose "%f~|~%s~|~%l~|~%c~|~%m~|~%e~|~%p~||~%n" lib t > _build/perlcritic_report.txt || true

# upload to sonarqube
sonar-scanner -Dsonar.host.url=http://sonarqube.racodond.com/ -Dsonar.login=$SONAR_TOKEN
