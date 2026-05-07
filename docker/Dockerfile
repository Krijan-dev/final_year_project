FROM ghcr.io/cirruslabs/flutter:stable

WORKDIR /app

# Copy dependency descriptors first for better layer caching.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy full project after dependencies are prepared.
COPY . .

# Default command (can be overridden by docker compose run).
CMD ["flutter", "analyze"]
