# syntax=docker/dockerfile:1.7
FROM ghcr.io/mayhemheroes/base:2026-06

ARG COMMIT
ARG REPO_URL
ARG SOURCE_DATE_EPOCH
ARG SANITIZER_FLAGS
ARG MAYHEM_JOBS=

ARG RUST_TOOLCHAIN=nightly-2025-09-05
ARG CARGO_FUZZ_VERSION=0.12.0

ENV RUSTUP_HOME=/opt/rust/rustup \
    CARGO_HOME=/opt/rust/cargo \
    PATH=/opt/rust/cargo/bin:$PATH

USER root
RUN set -eux; \
    mkdir -p "$RUSTUP_HOME" "$CARGO_HOME"; \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
      | sh -s -- -y --no-modify-path --profile minimal --default-toolchain "$RUST_TOOLCHAIN"; \
    rustup component add rust-src --toolchain "$RUST_TOOLCHAIN"; \
    cargo install cargo-fuzz --version "$CARGO_FUZZ_VERSION" --locked; \
    chmod -R a+rX /opt/rust; \
    mkdir -p "$CARGO_HOME/registry" "$CARGO_HOME/git" && chmod -R a+rwX "$CARGO_HOME/registry" "$CARGO_HOME/git"; \
    rustc --version; cargo --version; cargo fuzz --version
USER mayhem

WORKDIR /mayhem
COPY --chown=2000:2000 . /mayhem

RUN bash mayhem/build.sh
RUN if [ -f mayhem/test.sh ]; then bash mayhem/test.sh; else echo "no mayhem/test.sh"; fi

LABEL org.opencontainers.image.source="${REPO_URL}" \
      org.opencontainers.image.revision="${COMMIT}" \
      rlenv.tier="commit" \
      rlenv.source_date_epoch="${SOURCE_DATE_EPOCH}" \
      rlenv.user="mayhem"

USER mayhem
WORKDIR /mayhem
