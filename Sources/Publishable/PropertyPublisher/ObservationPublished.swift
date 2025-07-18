import Foundation

@attached(accessor, names: named(init), named(get), named(set), named(_modify))
@attached(peer, names: prefixed(_))
public macro ObservationPublished() = #externalMacro(
    module: "PublishableMacros",
    type: "ObservationPublishedMacro",
)
