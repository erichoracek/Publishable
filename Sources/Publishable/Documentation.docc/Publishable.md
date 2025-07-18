# ``Publishable-module``

Observe changes to `Observable` types synchronously with `Combine`.

## Topics

### Making Types Publishable

- ``Publishable()``
- ``Publishable-protocol``

### Getting Property Publishers

- ``AnyPropertyPublisher``

### Opting In Properties

- ``ObservationPublished()``
- ``ObservationIgnored``

## Opting In Specific Properties

Properties that you wish to observe and publish must be explicitly opted in by annotating them with the `@ObservationPublished` and `@ObservationIgnored` macros:

```swift
@Publishable @Observable
final class Person {
    @ObservationPublished @ObservationIgnored
    var name: String
}
```
