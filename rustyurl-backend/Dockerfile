# Use the official Rust image as the build environment
FROM rust:latest AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy the Rust project files into the container
COPY . .

# Build the Rust application in release mode
RUN cargo build --release

# Use a minimal image for the final container
FROM debian:buster-slim

# Copy the compiled binary from the build environment
COPY --from=builder /app/target/release/rustyurl-backend /usr/local/bin/rustyurl-backend

# Expose the port the app will run on
EXPOSE 8080

# Set the entry point to run the application
CMD ["rustyurl-backend"]
