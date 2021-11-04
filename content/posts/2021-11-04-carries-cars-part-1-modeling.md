---
title: "Domain-driven Design: From Nothing to Code — Carries Cars [Part 1]"
date: 2021-11-04T07:46:37+01:00
draft: false
tags: ["ddd", "backend", "domain", "modeling", "event-storming"]
---

Hey there! 👋  
It's been a while, huh?

I know I left an (underwhelming) cliffhanger with my [previous post](./posts), but honestly I wasn't feeling the whole "Dumbbit" thing a lot. The domain doesn't look interesting (to me at least!) and I didn't want to continue exploring it. _Sorry about that_ 😅

I still want to talk about Backend development in Rust at some point in the future, which might happen as part of this new series of posts. Be sure to **stay tuned** for that! 🔔

---

I realized I'm not incredibly good at coming up with fictional domains (I will leave that part to CEOs, Founders and Product folks 😄) but I **love** to explore new domains.

What's more, oftentimes I hear from people starting out with Domain-driven Design/Event-sourcing/CQRS that it's hard to understand all of these concepts without examples. Especially with the Modeling and Stategical Patterns.

Well, guess what? I've found an _interesting_ domain to explore, and we can **do it together!** 🎉

We will explore the [Carries Cars domain][carries-cars], which is part of a workshop by [Marijn Huizendveld][marijn-twitter] — _Disclamer: I've not attended the workshop, so what follows is my own modeling from the public post on his website._

Grab a coffee and follow me in this modeling exercise ☕

## Carries Cars — an introduction

This is the introduction to the domain that Marijn provided:

>Carries Cars is a car-sharing service that started operating in Amsterdam 6 months ago. The service operates 300 **vehicles** that are **spread out** over the compact city center. All vehicles are fully electric vehicles because of demands by the city as part of granting the free-floating fleet operating agreement.
>
>After the **customers reserved a car**, they have **20 minutes to reach it**. If the **vehicle is in good shape** then they accept a **rental agreement** using a **smartphone app**. From that point onwards they can **start driving around**. **Pricing** is straightforward: you **pay per minute** (e.g. € 0.24) and are allowed a **maximum mileage** (e.g. 250 kilometers).

You may notice I've highlighted some words; while analyzing the problem statement/domain introduction we can start deducing some of the concepts that are going to be explored at depth later, such as:
1. Any domain terminology that might end up in the [Ubiquitous Language](#ubiquitous-language) (e.g. _Customers_, _Vehicle_, _Car_, _Rental Agreement_, etc.),
2. Requirements or **Constraints** (e.g. _"Customer have 20 minutes to reach the reserved Car"_, _"Pay per minute¨_, _"Maximum mileage"_),
3. Commands or **Domain Events** (e.g. _"Customer Reserved a Car"_)

### Ubiquitous Language

The language, the terminology we use in our Domain is of primary importance: it lets us talk about it, discuss it, argue it. To use it efficiently, we need our language to be **explicit** and **precise** (as much as possible).

The [Ubiquitous Language][ubiquitous-language-fowler] is one of the most important concepts in Domain-driven Design: it allows _everyone_ to talk about the Domain (usually, Domain Experts with the responsible team, and stakeholders) and should be used as the primary source for implementation naming (which brings the Software closer to the Domain).

For the purposes of this example, I will act as Domain Expert and Team Member to start identifying this Language.

The words we highlighted from the Domain introduction can be used as a starting point for our Ubiquitous Language. To list them all:
* Customer,
* Vehicle,
* Reservation,
* Car,
* Rental Agreement,
* Driving,
* Pricing,
* Maximum Mileage.

Once we find these terms, we need to give them meaning: building a **glossary**.  
Go over each one of them and ask yourself: _what does X mean **to you**?_  
In a team context we'll see some interesting, possibly _diverging_ definitions emerge: explore those differences, capture each point of view and try to come to a common understading. Prefer **explicitness** over implicitness!

Let's see some examples of this exercise:

>_Team Member:_ We have two terms that are pretty close together: Vehicle and Car. Which one is best? Are they the same thing?
>
>_Domain Expert:_ Well currently they are, since our business offering focuses on car sharing. In the future this might change, as we might decide to expand to different products, such as e-moped or e-bikes for example.

At this point we could either decide to model explicitly for Car rental (_business to-be_) and [revisit the Domain model later][continuous-modeling], or we could decide to model for different kinds of Vehicles, focusing on Cars first (_business could-be_).

### Exploratory modeling

There are different kinds of Domain discovery:
* _**As-is:**_ model the Domain exactly as it is right now; not the most exiciting (for me at least!) kind of modeling, but could be the most revealing in terms of bottlenecks, unclarity, and business opportunity;
* _**Could-be**_: model the Domain as it could be scaled in the future; this is a very interesting exercise, but won't be useful for immediate use and rather be referenced to as a desired state;
* _**To-be**_: model the Domain as it is, but also considering any immediate change that is clear to the business; this is the most pragmatic approach, with a good balance of both previous methods, and can be used immediately to drive change in your Domain.  

[carries-cars]: https://marijn.huizendveld.com/workshops/carries-cars-ddd-traineeship
[marijn-twitter]: https://twitter.com/huizendveld
[ubiquitous-language-fowler]: https://martinfowler.com/bliki/UbiquitousLanguage.html
