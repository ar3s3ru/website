+++
title = "Designing Aggregates in Rust"
description = "An initial attempt in abstracting the Domain-driven Design Aggregate concept in Rust"
date = 2019-10-12T15:06:16+02:00
draft = true
+++

```rust
pub trait Aggregate {
    type State;
    type Event;
    type Error;

    fn initial_state() -> Self::State;
    fn apply(state: &Self::State, event: Self::Event) -> Result<Self::State, Self::Error>;
}
```
