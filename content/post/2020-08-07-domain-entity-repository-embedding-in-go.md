---
title: "Domain Entities and Repository design using Embedding in Go"
date: 2020-08-07T18:05:20+02:00
# draft: true
---

[Embedding] is a very neat feature of Go that allow for
composition of different types into another types.

The concept might look confusing at first, especially people that are used to inheritance
and `abstract class` a lot, but the idea is very simple: types that share a common trait
can be **composed** of *smaller types* implementing those traits.

As an example, let's talk about Entities in the database.

### Example: Entities in the database

In the Software Engineering realm, Entities -- and how they interact with each other -- are of utmost importance.
They're so important that we usually want to keep them safe and sound into a *database table*.

A typical database table might look like this:

```sql
CREATE TABLE entities (
    -- some fields here...
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

It's very usual to find `created_at` and `updated_at` columns in our tables.

This usually translates in the following Go code:
```go
type Entity struct {
    // Some fields here...

    CreatedAt time.Time `db:"created_at"`
    UpdatedAt time.Time `db:"updated_at"`
}
```

However, given that these fields are very common, we could *extract* them in
separate `struct`s and **embed them** into the `Entity` structure as such:

```go
type Created struct {
    CreatedAt time.Time `db:"created_at"`
}

type Updated struct {
    UpdatedAt time.Time `db:"updated_at"`
}

type Entity struct {
    // Compose our entity of two created/updated traits.
    Created
    Updated

    // Some fields here...
}
```

This gives us the possibility of removing a common trait declaration from
the `Entity` to a smaller type. Also, we could use these smaller types
in other types that share a similar need.

## Domain Entities, Repositories and Embedding

We can leverage embedding to build cleaner Domain Entities,
and more expressive Repository interfaces.

As we said earlier, Domain Entities are usually the most important part of
a business (think Orders, Payments, etc.), so it's fair to want to store them
in a persistent data source.

For that, it's very common to use some abstraction patterns as the [Repository pattern].

Some examples of it I've seen in the wild have the following design:
```go
type Entity struct {
    EntityID  int64     `db:"entity_id"`
    CreatedAt time.Time `db:"created_at"`
    UpdatedAt time.Time `db:"updated_at"`

    // Some fields ...
}

type Repository interface {
    // Listing all the fields in the Create method, depending on the entity
    // it might get with a very high ariety.
    Create(context.Context, fields...) (Entity, error)
    // Or this...
    // Wat? Create with an entity and returns the entity again?
    Create(context.Contex, Entity) (Entity, error)
    // Same goes for Update methods.
    Update(context.Context, Entity) (Entity, error)

    FindBySomething(context.Context, Something) ([]Entity, error)
}
```

How can we make it better?

### Decouple Entity and State

An Entity is a uniquely identifiable object -- by its ID -- that carries state.

Usually, the distinction between Entity and its state is: one is _persisted_ in a data source -- and can be retrieved
through a query by ID --, the other is _just data_ (e.g. [Value Objects]).

Let's take an Order for example:

```go
// An Order is an object that is composed of many Items (articles bought),
// a total amount paid and the reference to the buyer.
type Order struct {
    ID           int64
    CreatedAt    time.Time
    UpdatedAt    time.Time
    BuyerID      int64
    OrderItems   []string // SKU or identifier of the items bought
    TotalAmount  float32
}
```

As you can see, the only part of the Order entity that ensure uniqueness
is its `ID` field.

The rest of the fields might potentially have the same values for other entities.
This is what we refer to as _Entity State_, where its equality criteria is
_full equality_ (all the fields must be equal for two objects of the same type
to be considered equals).

We can extract the Entity State in a separate type, and have the Entity
be composed of it:

```go
type OrderState struct {
    BuyerID     int64
    OrderItems  []string
    TotalAmount float32
}

type Order struct {
    Created // As before, remember?
    Updated
    OrderState

    // This is the only additional field that the Order needs for its
    // (partial) equality criteria.
    ID int64
}
```

### Repository interfaces using Entity State

Leveraging composition for decoupling Entities from their State comes
with an added benefit during the Repository design.

First, let's recap what a Repository is:

>A Repository mediates between the domain and data mapping layers,
>acting like an **in-memory domain object collection**.
>
> _Martin Fowler_ -- [Repository](https://martinfowler.com/eaaCatalog/repository.html)

Being the Repository an _abstraction of a Collection_, then the high level
interface should look like this:

```go
type Repository interface {
    // You always "add" elements to a collection, you don't "create".
    // Very important distinction.
    Add(Entity) error


    Update(Entity) error

    // Get should ideally only return one specific element
    // (e.g. collection.get(0) should return the element at element 0).
    //
    // Go has no concept of Optional types (for now), so an error should
    // be returned if no Entity with that id has been found.
    Get(id) (Entity, error)

    // Removal can be done either by Entity...
    Remove(Entity) error
    // ...or by id.
    Remove(id) error

    // FindBy... returns a slice of the "collection" by matching a criteria.
    // There's no such thing as `Not Found` errors in this case (compared to Get()),
    // only empty slices.
    FindByCriteria(Criteria) ([]Entity, error)
}
```

In case the ID can't be generated in the service (namely, `SERIAL PRIMARY KEY`)
then the ID should only be returned by the `Add` function.

We can express the idea of not

[Embedding]: https://golang.org/doc/effective_go.html#embedding
[Repository pattern]: https://deviq.com/repository-pattern/
[Value Objects]: https://martinfowler.com/bliki/ValueObject.html
