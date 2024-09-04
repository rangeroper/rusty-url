# Rusty URL

`rusty-url` is a Rust library designed to provide robust and easy-to-use URL parsing, validation, and manipulation. This crate offers efficient handling of URLs in a variety of formats and can be integrated into a wide range of Rust-based projects.

## Features

- **Parsing**: Easily parse URLs from strings into structured components.
- **Validation**: Check URLs for syntactic correctness according to RFC 3986.
- **Manipulation**: Modify components of a URL (e.g., scheme, host, path, query, fragment).
- **Serialization**: Convert URL components back into a valid URL string.

## Installation

To use `rusty-url` in your project, add the following to your `Cargo.toml` file:

```toml
[dependencies]
rusty-url = "0.1.0"
