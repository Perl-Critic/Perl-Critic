FROM alpine:latest

RUN \
    apk --no-cache update \
    && apk --no-cache add \
        make \
        wget \
        perl \
        perl-app-cpanminus \
        perl-clone \
        perl-config-tiny \
        perl-dev \
        perl-exception-class \
        perl-list-someutils \
        perl-module-build \
        perl-module-pluggable \
        perl-params-util \
        perl-readonly \
        perl-task-weaken \
    && rm -rf /var/cache/apk/*

RUN \
    cpanm --notest \
        B::Keywords \
        Perl::Tidy \
        PPI::Token::Quote::Single \
        PPIx::QuoteLike \
        PPIx::Regexp \
        PPIx::Utilities::Statement \
        String::Format \
    && apk del --purge --rdepends \
        make \
        wget \
        perl-app-cpanminus \
    && rm -rf /root/.cpanm

COPY lib /usr/local/lib/perl5/site_perl

COPY bin /usr/local/bin
RUN chmod +x /usr/local/bin/perlcritic

USER nobody

ENTRYPOINT [ "/usr/local/bin/perlcritic" ]
CMD [ "--help" ]
