+++
title = "Implementing a Backend Service in Rust — Part 1"
description = "Project description, Package Structure and Repository setup"
date = "2020-11-05T00:00:00+02:00"
tags = ["rust", "backend"]
draft = false
+++

I've been using Rust for quite a while now.

Most notably, I've been involved in the development of [`eventually-rs`],
a Rust crate providing support for Event-sourced applications.

My background has to do with Systems Programming and Backend Development,
which was the main drive for creating `eventually`.

In the process of writing the crate, I've been reimplementing a couple of those
microservices I was currently working on on my daily job, as a sort of
testing project to validate the soundness of the crate and its design decisions.

During this time, I've gradually learned how to implement much of the features
a service _needs_ for _production-readiness_, in the Rust ecosystem, such as:
**instrumentation**, **distributed tracing**, **package structure**,
**containerization** and so on.

With this series, I aim to lay those concepts down for you,
whether you may or may not be familiar with them already, and apply them using
**stable Rust**.

By the end of the series, we should have a _(almost)_ **production-ready**
Rust service, ready to be deployed somewhere in the cloud.

But... before jumping into the code, let's talk about what we are going
to build.

## _Dumbbit_: A _dumb_ Reddit clone

Well, the title says it all...

For personal projects, I usually draw inspirations from things I use a lot.
As a matter of fact, I'm pretty active on Reddit, so why not trying
to recreate a very small MVP of Reddit?

This is what we're going to implement in the service:

* **Topics** (i.e. _Subreddits_)
    * **Create** a new Topic
    * **Visualize** a Topic
* **Homepage**
  * **Follow** a Topic
  * **Display** new **Posts** from followed Topics
* **Posts**
    * **Create** a Post in a Topic
    * **Upvote** or **Downvote** a Post

We can keep things _fairly_ small, while still have enough content
to cover much of the many aspects you might find in your typical service
development endeavors.

Now that we know what we're going to build, let's talk about how to set up
the repository that is going to host our code!

## Repository Setup

This is the least favorite part of many people. However, I find it of
great importance to get it right, just as much as the actual code
we're going to write.

In this section, we're going to discuss: package structure, Continuous Integration
pipeline, configurations, etc.

It's important to setup all the small things as soon as possible, in order
to keep productivity high during the implementation phase.

### Create a new crate

Let's use `cargo` to create the new crate:

```sh
cargo new --lib dumbbit
```

This will create a _library crate_, which means the first and only Rust
source code file will be in `src/lib.rs`.

I personally prefer having the main crate as a library, and add as many
binaries as artifacts needed under `src/bin`. In our case, let's create
an initial `main.rs` file in `src/bin` with a simple `"Hello World"`:

```rust
//! src/bin/main.rs

fn main() {
    println!("Hello World!")
}
```

If we run `cargo run` we should get the following output:

```sh
$ cargo run
Hello World!
```

#### Why not virtual workspaces?

A [Cargo Workspace][cargo-workspaces] allows to package multiple crates
in the same repository space, by sharing a single `Cargo.lock` instead
of one per each crate member.

There are some notable examples of workspaces, such as [`futures-rs`].

A valid package structure idea might be to split multiple layers of the
service application onto separate crates. This has the following advantages:

1. Incremental compilation for the updated crates
2. **Concurrent** crate compilation from Cargo during `cargo run` or `cargo build`
3. Flat and tidy package structure

However, this makes things a bit more complicated with Docker images, and for most cases
there are no concrete benefits of using such structure (unless, of course, your
application has a high number of potential crates).

_Suggestion:_ start with a single crate, split layers using modules and **if**
the number of modules reaches a "big enough" number, you can:

1. Move the modules from `src/` to the root level,
2. Add a `Cargo.toml` for each module to the root level,
3. Change the `Cargo.toml` in the root level to a [Cargo Workspace][cargo-workspaces] one
4. Import crates as needed

### Set up a Continuous Integration pipeline

Continuing on setting up the development environment, next thing I'd suggest you
to do is to set up a _Continuous Integration pipeline_.

At the very least, the CI should perform the following checks:

* Check that the code compiles successfully
* Run all kinds of testing suites
* Make sure the code conforms to our styleguides using a Linter

There might be additional steps you want to include in your CI pipeline (e.g. generating
documentation), but for now this should be enough.

You can use whatever tool you like the most, but in our case, since the code
is going to be hosted in Github, we're going to use Github Actions.

Luckily, there are a number of very useful Actions already out there
for Rust, such as:

* [actions-rs/toolchain](https://github.com/actions-rs/toolchain), to target a specific Rust version
* [actions-rs/tarpaulin](https://github.com/actions-rs/tarpaulin), to use `cargo-tarpaulin` for running tests and collect coverage profiles
* [actions-rs/clippy-check](https://github.com/actions-rs/clippy-check), to run the Clippy linter

In our particular case, we can use the following Workflow configuration
to enable testing with coverage, compilation and linting:

```yaml
name: Rust (stable)
on:
  pull_request:
  push:
    branches:
      - master

jobs:
  # Make sure the project compiles, without trying to building the whole project.
  check:
    name: Check
    runs-on: ubuntu-latest
    steps:
      - name: Checkout sources
        uses: actions/checkout@v2.3.3

      - name: Install stable toolchain
        uses: actions-rs/toolchain@v1
        with:
          profile: minimal
          toolchain: stable
          override: true

      - name: Run cargo check
        uses: actions-rs/cargo@v1
        with:
          command: check

  # Run unit and integration tests in the project.
  # Using tarpaulin to collect coverage reports and upload to Codecov (requires token).
  tests:
    name: Test Suite
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v2.3.3

      - name: Install stable toolchain
        uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
          override: true

      - name: Run cargo-tarpaulin (main)
        uses: actions-rs/tarpaulin@v0.1

      - name: Upload to codecov.io
        uses: codecov/codecov-action@v1.0.14
        with:
          token: ${{secrets.CODECOV_TOKEN}}
          flags: unit

      - name: Archive code coverage results
        uses: actions/upload-artifact@v2.2.0
        with:
          name: code-coverage-report
          path: cobertura.xml

  # Run clippy to highlight warnings and style errors.
  lints:
      name: Lints
      runs-on: ubuntu-latest
      steps:
        - name: Checkout sources
          uses: actions/checkout@v2.3.3

        - name: Install stable toolchain
          uses: actions-rs/toolchain@v1
          with:
            profile: minimal
            toolchain: stable
            override: true
            components: rustfmt, clippy

        - name: Run cargo fmt
          uses: actions-rs/cargo@v1
          with:
            command: fmt
            args: --all -- --check

        - name: Run cargo clippy
          uses: actions-rs/clippy-check@v1
          with:
            token: ${{ secrets.GITHUB_TOKEN }}
            args: --all-features

```

### Our first _Dumb_ HTTP Server

The application transport choice for now is HTTP.

Let's then create a simple _"Hello World"_ application for now.

Remember: we want this application to run on `stable` so no [Rocket][rocket].
However, a nice `stable`-compatible HTTP library we can use is [`tide`][tide].

Let's add the dependency in `Cargo.toml` like so:
```toml
[dependencies]
tide = "0.14.0"
```

To use [`tide`][tide] however, we need the [`async-std`][async-std] executor to
make the `main()` entrypoint `async`. Let's add it like so:
```toml
[dependencies]
async-std = { version = "1.7.0", features = ["attributes"] }
```

Last but not least, I'm a huge fan of [`anyhow`][anyhow] for generic errors,
rather than using `Box<dyn std::error::Error>`. Let's add that one in `Cargo.toml` too:
```toml
[dependencies]
anyhow = "1.0"
```

Now, let's create the new HTTP server executable in `src/bin/dumbbit.rs`.
The file should look like this:
```rust
#[async_std::main]
async fn main() -> anyhow::Result<()> {
    let mut app = tide::new();

    app.at("/").get(|_| async move { Ok("Hello, world!\n") });

    Ok(app.listen("0.0.0.0:8080").await?)
}
```

As you can probably tell, the HTTP server is listening to incoming connections
on the port `8080`. `tide::new()` creates a new router, and the `at("/").get(..)`
means that every `GET http://localhost:8080/` requests will get `Hello, world!`
in response.

Pretty neat, huh?

`async_std::main` is a macro that runs the `async fn main()` onto the `async_std`
executor (if you don't know what an executor is, [you can check this link][executor]).

We can run the application using `cargo run`.

Let's test it out with `curl`:
```
curl http://localhost:8080/ -v
*   Trying ::1:8080...
* connect to ::1 port 8080 failed: Connection refused
*   Trying 127.0.0.1:8080...
* Connected to localhost (127.0.0.1) port 8080 (#0)
> GET / HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/7.72.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< content-length: 14
< date: Wed, 04 Nov 2020 23:12:40 GMT
< content-type: text/plain;charset=utf-8
<
Hello, world!
* Connection #0 to host localhost left intact
```

🎉 **It works!** 🎉

We have now a pretty decent HTTP server. Bet it can also handle quite a high traffic 😛

## What's next?

Now that we have a functioning HTTP server, the next tasks are:

1. Implementing the **domain layer**
2. Implementing the **infrastructure layer** (e.g. database connections, HTTP API, etc.)
3. Package the application in a **Docker image**
4. **Deploy it** somewhere!

In the next blog post, we're going to tackle the Domain implementation. We'll start with
some light domain modeling using **Event Storming**, and how that would translate into
our Rust code. You'll find out, Rust's type system allows for _very expressive_, and
**safe**, domain modeling.

For now, you'll find the Dumbbit code explained in this blog post so far in this repository, at the `blog-post-part-1` label: https://github.com/ar3s3ru/dumbbit/tree/blog-post-part-1

Let me know what you think!

You can reach out to me on Github, or my [email account][mailto]. You can find me on
Twitter or LinkedIn, all the places!


<!-- Links -->

[`eventually-rs`]: https://github.com/ar3s3ru/eventually-rs
[cargo-workspaces]: https://doc.rust-lang.org/book/ch14-03-cargo-workspaces.html
[`futures-rs`]: https://github.com/rust-lang/futures-rs
[rocket]: https://github.com/SergioBenitez/Rocket
[tide]: https://github.com/http-rs/tide
[async-std]: https://github.com/async-rs/async-std
[executor]: https://rust-lang.github.io/async-book/02_execution/05_io.html
[mailto]: mailto:danilocianfr+blog@gmail.com
