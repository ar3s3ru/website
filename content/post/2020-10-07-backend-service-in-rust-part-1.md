---
title: "Backend Service in Rust — Part 1"
description: "Project description, Package Structure and Repository setup"
date: 2020-10-07T23:15:57+02:00
draft: false
---

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

* **Users** registration
* Session handling (**login**/**logout**)
* **Topics** (i.e. _Subreddits_)
    * **Create** a new Topic
    * **Follow** a Topic
    * **Visualize** a Topic
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



<!-- Links -->

[`eventually-rs`]: https://github.com/ar3s3ru/eventually-rs
