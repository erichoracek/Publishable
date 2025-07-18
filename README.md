# Publishable

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNSFatalError%2FPublishable%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/NSFatalError/Publishable)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNSFatalError%2FPublishable%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/NSFatalError/Publishable)
[![Codecov](https://codecov.io/github/NSFatalError/Publishable/graph/badge.svg?token=axMe8BnuvB)](https://codecov.io/github/NSFatalError/Publishable)

Synchronous observation of `Observable` changes through `Combine`

#### Contents
- [What Problem Publishable Solves?](#what-problem-publishable-solves)
- [How Publishable Works?](#how-publishable-works)
- [Documentation](#documentation)
- [Installation](#installation)

## What Problem Publishable Solves?

With the introduction of [SE-0475: Transactional Observation of Values](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0475-observed.md),
Swift gains built-in support for observing changes to `Observable` types. This solution is great, but it only covers some of the use cases, as it
publishes the updates via an `AsyncSequence`.

In some scenarios, however, developers need to perform actions synchronously - immediately after a change occurs.

This is where `Publishable` comes in. It allows `Observation` and `Combine` to coexist within a single type, letting you take advantage of the latest
`Observable` features, while processing changes synchronously when needed. It even works with the `SwiftData.Model` macro!

```swift
import Publishable

// To publish specific stored properties, apply both `@ObservationPublished`
// and `@ObservationIgnored` to each property you want to observe.
@Publishable @Observable
final class Person {
    @ObservationPublished @ObservationIgnored
    var name = "John"

    @ObservationPublished @ObservationIgnored
    var surname = "Doe"

    var fullName: String {
        "\(name) \(surname)"
    }
}

let person = Person()
let nameCancellable = person.publisher.name.sink { name in
    print("Name -", name)
}
let fullNameCancellable = person.publisher.fullName.sink { fullName in
    print("Full name -", fullName)
}

// Initially prints:
// Name - John
// Full name - John Doe

person.name = "Kamil"
// Prints:
// Name - Kamil
// Full name - Kamil Doe

person.surname = "Strzelecki"
// Prints:
// Full name - Kamil Strzelecki
```

## How Publishable Works?

For properties annotated with the `@ObservationPublished @ObservationIgnored` macro, the
`@ObservationPublished`  macro synthesizes the same getter/setter/etc. as `@ObservationTracked`,
but with additional calls to publish updates to the associated `publisher.property` `Publisher.

## Installation

```swift
.package(
    url: "https://github.com/NSFatalError/Publishable",
    from: "1.0.0"
)
```
