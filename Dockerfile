# Base image with Elixir and Erlang
FROM hexpm/elixir:1.15.7-erlang-26.1.2-debian-bookworm-20231009-slim AS base

# Install build dependencies
RUN apt-get update -y && \
    apt-get install -y build-essential git curl postgresql-client && \
    apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set working directory
WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Development stage
FROM base AS dev

# Install node for assets and inotify-tools for live reload
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs inotify-tools && \
    apt-get clean && rm -f /var/lib/apt/lists/*_*

# Copy mix files
COPY mix.exs mix.lock ./

# Install dependencies
RUN mix deps.get

# Copy app files
COPY . .

# Compile dependencies
RUN mix deps.compile

# Expose port
EXPOSE 4000

# Start Phoenix server
CMD ["mix", "phx.server"]

# Production build stage
FROM base AS build

ENV MIX_ENV=prod

# Copy mix files
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy app files
COPY . .

# Compile assets (when ready for production)
# RUN mix assets.deploy

# Compile release
RUN mix compile
RUN mix release

# Production runtime stage
FROM debian:bookworm-20231009-slim AS prod

RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses5 locales postgresql-client && \
    apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR /app

# Copy release from build stage
COPY --from=build /app/_build/prod/rel/cuisine13 ./

# Expose port
EXPOSE 4000

# Start the release
CMD ["/app/bin/cuisine13", "start"]
