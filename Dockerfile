# Build stage
FROM elixir:1.18-otp-27-alpine AS build

# Install build dependencies
RUN apk add --no-cache build-base git

# Set build environment
ENV MIX_ENV=prod

# Create app directory
WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy mix files
COPY mix.exs mix.lock ./
COPY config config
COPY apps apps

# Install dependencies
RUN mix deps.get --only prod && \
    mix deps.compile

# Copy source code
COPY lib lib
COPY priv priv

# Compile and build release
RUN mix compile && \
    mix release

# Runtime stage
FROM alpine:3.19 AS runtime

# Install runtime dependencies
RUN apk add --no-cache libstdc++ openssl ncurses-libs

# Create app user
RUN addgroup -g 1000 specforge && \
    adduser -u 1000 -G specforge -s /bin/sh -D specforge

WORKDIR /app

# Copy release from build stage
COPY --from=build --chown=specforge:specforge /app/_build/prod/rel/specforge ./

# Create necessary directories
RUN mkdir -p /app/specs && \
    chown -R specforge:specforge /app

USER specforge

# Expose Phoenix port
EXPOSE 4000

# Set environment variables
ENV HOME=/app \
    LANG=C.UTF-8 \
    PHX_HOST=0.0.0.0 \
    PHX_PORT=4000

# Start the application
CMD ["bin/specforge", "start"]