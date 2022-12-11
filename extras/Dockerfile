FROM alpine:latest

RUN apk --no-cache update && \
    apk --no-cache add wget make perl perl-app-cpanminus \
      perl-readonly perl-dev perl-params-util perl-file-remove perl-clone \
      perl-class-inspector perl-test-deep perl-task-weaken perl-list-moreutils \
      perl-exception-class perl-module-pluggable perl-module-build \
      perl-file-sharedir perl-path-tiny perl-class-tiny perl-config-tiny && \
    rm -rf /var/cache/apk/*

RUN cpanm B::Keywords && \
    cpanm IO::String && \
    cpanm Test::Object && \
    cpanm Hook::LexWrap && \
    cpanm Test::SubCalls && \
    cpanm PPI::Token::Quote::Single && \
    cpanm PPIx::QuoteLike && \
    cpanm PPIx::Utilities::Statement && \
    cpanm PPIx::Regexp && \
    cpanm String::Format && \
    cpanm Perl::Tidy && \
    cpanm Lingua::EN::Inflect && \
    cpanm Pod::Spell && \
    rm -rf /root/.cpanm

COPY lib /usr/local/lib/perl5/site_perl

COPY bin /usr/local/bin
RUN chmod +x /usr/local/bin/perlcritic

ENTRYPOINT [ "/usr/local/bin/perlcritic" ]
CMD [ "--help" ]
