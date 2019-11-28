+++
title = "Event Sourcing in Rust :: Aggregate"
# description = "Design sketches for Aggregate abstraction"
date = 2019-11-24T10:06:42+01:00
draft = false
tags = [
    "rust",
    "ddd",
    "event-sourcing",
    "aggregate"
]
+++

This post is the first of many to come (hopefully) describing some of the features
and designs included in the crate I'm currently working on: [`eventually-rs`][eventually-rs].

Given the project is at its very first stage of development, your feedback is invaluable.
Share your opinion here in the comments section, or get in touch through my Github, LinkedIn or
plain old [email](mailto:danilocianfr+blog@gmail.com) :-)

---
---

I've been so fascinated by Rust lately: guaranteed safety[^1], strong and expressive
type-system with no bargains in performance...

When I start with a new language, I usually look around for interesting
libraries, projects or articles -- related to topics I deal with in my daily job --
to draw inspiration from.

At [HelloFresh][hellofresh-careers], we're working very hard
towards the goal of decommissioning _The Monolith(s)_ and move to a microservice
architecture.

Some of the new services employ an [_Event Sourcing architecture_][ddd-event-sourcing],
which is a pattern I'm personally very interested to.

Bonus point, [we also have a Go library to help you do Event Sourcing!][goengine]
All our production services leveraging Event Sourcing are using this library,
with quite successful results.

So, given my latest efforts in getting more familiar with Domain-driven Desing
and Event Sourcing _(done right)_, I decided I wanted to try it on Rust.

# Current state of Event Sourcing in Rust

I spent quite some time researching existing libraries for Event Sourcing,
or in-depth articles on the matter.

I wasn't expecting to find something like [Axon][axon]
-- though I had some hopes -- but some work-in-progress crate[^2] of sorts.

What I found instead were a series of very interesting articles and some proof-of-concept crates, such as:

* [Event Sourcing with Aggregates in Rust][event-sourcing-with-aggregates-in-rust] from Kevin Hoffman
* [Building an Event Sourcing Crate for Rust][building-an-event-sourcing-crate-for-rust] again, from Kevin Hoffman
* [`eventsourcing` crate][eventsourcing]
* [`chronicle` crate][chronicle]

Sadly, all these crates seems now to be abandoned and, with _Rust 2018_, outdated.

However, that's actually more than I was expecting to find, and such crates -- especially [`chronicle`][chronicle] --
are going to be very useful reference points.

---

# Designing Aggregates

Before starting with any mental effort, let's level out our terminology:
**what is** an _Aggregate_?

> A DDD aggregate is **a cluster of domain objects that can be treated as a single unit**.
> [..]
> DDD aggregates are **domain concepts** (order, clinic visit, playlist), while collections are generic.
> An aggregate will **often contain mutliple collections, together with simple fields**.
>
> -- <cite>Martin Fowler, [DDD_Aggregate][ddd-aggregate]</cite>

TODO

## Starting point: `chronicle`

[`chronicle`][chronicle] is the crate that I like the most, perhaps containing the most features
among every other crate I came across.

Let's take a look at how it defines the `Aggregate`:

```rust
pub trait Aggregate {
    /// A snapshot of the state of an aggregate. More often than not this is an
    /// `Option<T>`, to signify whether the aggregate has been instantiated or
    /// not.
    type State;

    /// The result of a successful command.
    type Event;

    /// A command to update the state of the aggregate. This may or may not
    /// result in an `Event` being comitted.
    type Command;

    /// An error that may be yeilded by the `handle_command` function on a
    /// validation error.
    type CommandError;

    /// A future that will be returned by the `handle_command` function.
    type EventsFuture: IntoFuture<Item = Vec<Self::Event>, Error = Self::CommandError>;

    /// The seed state, before the aggregate has been created.
    fn initial_state() -> Self::State;

    /// Handle a command based on the current state, returning a future that
    /// either yeilds a vector of resulting `Event`s or a `CommandError`.
    fn handle_command(state: &Self::State, command: Self::Command) -> Self::EventsFuture;

    /// Apply an event to the state of an aggregate. Note that this should
    /// always succeed.
    fn apply_event(state: &mut Self::State, event: Self::Event);
}
```

Essentially, the `Aggregate` in `chronicle` is a:

* _Command Handler_ for all commands defined by the associated type `Command`
* _Event Handler_ to apply all events defined by the associated type `Event` to the current Aggregate's `State`

This trait gives enough flexibility by having a clear separation between the `Aggregate`
implementation and the Aggregate Root, or `State`.

It means that implementation of this trait could go from simple aggregates to more
complicated ones, with lots of links to other entites.

### A simple Aggregate

Let's see how a very simple Aggregate could look like.

We're not going to deal with futures and asynchronous computation just yet, so
the results coming from the `handle_command` method are going to be, in fact,
simple `Result`.

```rust
struct Account {
    id: String,
    balance: f32,
}

enum AccountEvent {
    Created { id: String },
    Withdrawn { quantity: f32 },
    Deposited { quantity: f32 },
}

enum AccountCommand {
    Create { id: String },
    Withdraw { id: String, quantity: f32 },
    Deposit { id: String, quantity: f32 },
}

enum AccountCommandError {
    AlreadyExists,
    NotFound
    NotEnoughFunds,
}

impl Aggregate for Account {
    type State = Option<Self>;
    type Event = AccountEvent;
    type Command = AccoundCommand;
    type CommandError = AccoundCommandError;
    // No async for now, just synchronous operations on command!
    type EventsFuture = Result<Vec<Self::Event>, Self::Error>;

    fn initial_state() -> Self::State {
        None
    }

    fn handle_command(state: &Self::State, command: Self::Command) -> Self::EventsFuture {
        use AccountCommand::*;

        match state {
            Some(state) => match command {
                Create { .. } => Err(AccountCommandError::AlreadyExists),
                Withdraw { quantity, .. } => {
                    if state.quantity < quantity {
                        Err(AccountCommandError::NotEnoughFunds)
                    } else {
                        Ok(AccountEvent::Withdrawn { quantity })
                    }
                },
                Deposit { quantity, .. } => Ok(AccountEvent::Deposited { quantity }),
            },
            None => match command {
                Create { id } => Ok(AccountEvent::Created { id }),
                _ => Err(AccountCommandError::NotFound),
            }
        }
    }

    fn apply_event(state: &mut Self::State, event: Self::Event) {
        use AccountEvent::*;

        match state {
            Some(state) => match event {
                Created { .. } => (),
                Withdrawn { quantity } => {
                    *state.quantity -= quantity;
                },
                Deposited { quantity } => {
                    *state.quantity += quantity;
                }
            },
            None => match event {
                Created { id } => {
                    *state = Some(Account { id, quantity: 0 });
                },
                _ => ()
            }
        }
    }
}
```

Since the aggregate is simple enough, its `State` can be an optional reference
to itself, as you can see from:

```rust
impl Aggregate for Account {
    type State = Option<Self>;
    // ...
```

It all seems awesome, except that, even from a simple example such as this,
you can see some of the drawbacks from this abstraction:

* `Aggregate` has _a lot_ of associated types, mainly because of _Command Handling_ and _Event Handling_ combined
* `apply_event` provides no error handling (`fn(&mut State, Event) -> ()`)
* `handle_command` and `apply_event` can get very complicated to read very quickly, especially in cases where pattern `match`ing is used
* As stated in the comments, `Option<T>` would be your typical `type State`, but using it contributes to some cumbersome code in both `handle_command` and `apply_event`


### Split the Aggregate

The main reason why [`chronicle`][chronicle]'s aggregate abstraction is _too complex_
is due to it having _too many explicit concerns_, being:

* _Command Handling_, which needs:
    * `type Command`
    * `type CommandError`
    * `type EventsFuture`
    * `fn handle_command(...)`
* _Event Handling_, which needs:
    * `type Event`
    * `fn apply_event(...)`

Thus the question: why not **split the _Command Handling_ and the _Event Handling_ apart**?

At the very core of Event Sourcing is the _shift_ in **how we persist** models
from our domain layer: we don't store the latest representation of our entities,
but rather **all the events that changed the state of a single entity in our system**,
in a chronological sequence.

So, at the very least, our Aggregate should be able to **re-create its state**,
given all the events that mutated it in the _same order as they happened_.

In other words, we want to keep the _Event Handling_ part of the `Aggregate` trait:

```rust
pub trait Aggregate {
    type State;
    type Event;

    fn apply(state: &mut Self::State, event: Self::Event);
}
```

It looks way more clean now, doesn't it?

There's something missing, though: `apply` takes a mutable reference to the `State`, but why not adopting a more functional approach, where we take the full ownership of the `State` and return the modified `State`?


```rust
pub trait Aggregate {
    type State;
    type Event;

    fn apply(state: Self::State, event: Self::Event) -> Self::State;
}
```

Much better! Now, applying events will explicitly take ownership of the
current `State`, modify it and return the modified state.

But what about **error handling**?

Though I'd assume events in most cases are just simply applied to the current state,
one might potentially run some validations on them, maybe through _Domain Services_.

In this case, we could change the `Aggregate` as such:

```rust
pub trait Aggregate {
    type State;
    type Event;
    type Error;

    fn apply(state: Self::State, event: Self::Event) -> Result<Self::State, Self::Error>;
}
```

### Event Store support

Our `Aggregate` can now change its state representation based on an incoming `Event`, great!

As we said before however, the `Aggregate` should be able to recreate its current state, provided
all the events -- in chronological order -- that have changed the aggregate state in time.

For the functional programmers out there, this is called **`fold`**:

> In functional programming, **fold** (also termed **reduce**, **accumulate**, **aggregate**, **compress**, or **inject**) refers to a family of higher-order functions that analyze a recursive data structure and through use of a given combining operation, recombine the results of recursively processing its constituent parts, building up a return value.
>
> -- <cite> [Fold (higher-order function)][fold-wiki] -- Wikipedia </cite>

`fold` is typically applied on data structures that are traversable, or _iterable_.

Luckily for us, Rust already provides support for such structures through the [`Iterator` trait][rust-iterator].
In this trait, you can also find a very nice method called -- guess what -- [**`Iterator::fold`**][rust-iterator-fold]!

```rust
// From the Iterator trait
fn fold<B, F>(self, init: B, f: F) -> B where
    F: FnMut(B, Self::Item) -> B,
```

We can add a similar method in our `Aggregate` trait to apply a list of `Event`s given an initial `State` value:

```rust
pub trait Aggregate {
    // ...

    fn fold<I>(state: Self::State, events: I) -> Result<Self::State, Self::Error>
        where I: Iterator<Item = Self::Events>
    {
        // ...
    }
}
```

Since `fold` it's basically just repeating the `apply` for each `Event` in the `Iterator`, we can also provide
a default implementation for it:

```rust
fn fold<I>(state: Self::State, events: I) -> Result<Self::State, Self::Error>
    where I: Iterator<Item = Self::Events>
{
    events.fold(
        // The state in input is ok, since it's been created by either another `fold` or `apply`
        Ok(state),
        // Here `previous` is, as you might imagine, the Result from the previous recursive call,
        // whereas `event` is the current element consumed from the `Iterator`
        |current, event| {
            // Result is basically a Monad of which we can change the internal state
            // in case the Result is thus far `Ok`
            previous.and_then(|state| Self::apply(state, event))
        }
    )
}
```

### What's left?

We have a pretty solid ground so far: we can `apply` and `fold` events into an `Aggregate::State`, yay!

However, there are still some more work that we can do, starting from the `State` itself:

1. For most cases, we could implement the `Aggregate` trait on top of the `State`, having something akin to:
    ```rust
    pub struct MyAggregateState {
        // some state
    }

    impl Aggregate for MyAggregateState {
        type State = Self;

        // ...
    }
    ```

1. In cases where the default state for an `Aggregate` is _nullable_, the `State` would be an `Option<T>`:
    ```rust
    pub struct MyAggregateState {
        // some state
    }

    pub struct MyAggregate{}
    impl Aggregate for MyAggregate {
        type State = Option<MyAggregateState>;

        // ...
    }
    ```

In both cases, we could implement a different trait that would _auto-implement_ `Aggregate` appropriately,
so as to remove unnecessary code from the implementor side.

<!-- Footnotes -->

[^1]: Aside from the memory safety offered by the [Ownership and Borrowing system][ownership-borrowing-rust], Rust provides compile-time guarantees on *thread-safety* with [`Send`][rust-send] and [`Sync`][rust-sync] traits.

[^2]: A _crate_ is the Rust term for _package_.

<!-- Links -->

[eventually-rs]: https://github.com/ar3s3ru/eventually-rs

[hellofresh-careers]: https://www.hellofresh.com/careers/
[ddd-event-sourcing]: https://martinfowler.com/eaaDev/EventSourcing.html
[ddd-aggregate]: https://martinfowler.com/bliki/DDD_Aggregate.html
[goengine]: https://github.com/hellofresh/goengine
[axon]: https://docs.axoniq.io/reference-guide/

[event-sourcing-with-aggregates-in-rust]: https://medium.com/capital-one-tech/event-sourcing-with-aggregates-in-rust-4022af41cf67
[building-an-event-sourcing-crate-for-rust]: https://medium.com/capital-one-tech/building-an-event-sourcing-crate-for-rust-2c4294eea165
[eventsourcing]: https://github.com/pholactery/eventsourcing
[chronicle]: https://github.com/brendanzab/chronicle
[fold-wiki]: https://en.wikipedia.org/wiki/Fold_(higher-order_function)
[rust-iterator]: https://doc.rust-lang.org/std/iter/trait.Iterator.html
[rust-iterator-fold]: https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.fold

[ownership-borrowing-rust]: https://doc.rust-lang.org/book/second-edition/ch04-00-understanding-ownership.html
[rust-send]: https://doc.rust-lang.org/std/marker/trait.Send.html
[rust-sync]: https://doc.rust-lang.org/std/marker/trait.Sync.html
