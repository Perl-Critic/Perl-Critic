FROM alpine:latest

RUN \
    apk --no-cache update \
    && apk --no-cache add \
        make \
        wget \
        perl \
        perl-app-cpanminus \
        perl-class-inspector \
        perl-class-tiny \
        perl-clone \
        perl-config-tiny \
        perl-dev \
        perl-exception-class \
        perl-file-remove \
        perl-file-sharedir \
        perl-file-sharedir-install \
        perl-list-moreutils \
        perl-module-build \
        perl-module-pluggable \
        perl-params-util \
        perl-path-tiny \
        perl-readonly \
        perl-task-weaken \
        perl-test-deep \
    && rm -rf /var/cache/apk/*

RUN \
    cpanm \
        B::Keywords \
        Hook::LexWrap \
        Lingua::EN::Inflect \
        Perl::Tidy \
        Pod::Spell \
        PPI::Token::Quote::Single \
        PPIx::QuoteLike \
        PPIx::Regexp \
        PPIx::Utilities::Statement \
        String::Format \
        Test::Object \
        Test::SubCalls \
    && rm -rf /root/.cpanm

COPY lib /usr/local/lib/perl5/site_perl

COPY bin /usr/local/bin
RUN chmod +x /usr/local/bin/perlcritic

ENTRYPOINT [ "/usr/local/bin/perlcritic" ]
CMD [ "--help" ]
