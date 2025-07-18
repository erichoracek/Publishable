//
//  ObservableTests.swift
//  Publishable
//
//  Created by Kamil Strzelecki on 18/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@testable import Publishable
import Foundation
import Testing

internal struct ObservableTests {

    @Test
    func testStoredPropertyPublisher() {
        var person: Person? = .init()
        var publishableQueue = [String]()
        nonisolated(unsafe) var observationsQueue: [Void] = []

        var completion: Subscribers.Completion<Never>?
        let cancellable = person?.publisher.name.sink(
            receiveCompletion: { completion = $0 },
            receiveValue: { publishableQueue.append($0) }
        )

        func observe() {
            withObservationTracking {
                _ = person?.name
            } onChange: {
                observationsQueue.append(())
            }
        }

        observe()
        #expect(publishableQueue.popFirst() == "John")
        #expect(observationsQueue.popFirst() == nil)

        person?.surname = "Strzelecki"
        #expect(publishableQueue.popFirst() == nil)
        #expect(observationsQueue.popFirst() == nil)

        person?.name = "Kamil"
        #expect(publishableQueue.popFirst() == "Kamil")
        #expect(observationsQueue.popFirst() != nil)
        observe()

        person = nil
        #expect(publishableQueue.isEmpty)
        #expect(observationsQueue.isEmpty)
        #expect(completion == .finished)
        cancellable?.cancel()
    }
}

extension ObservableTests {

    @Publishable @Observable
    public final class Person {

        let id = UUID()
        @ObservationPublished @ObservationIgnored
        var age = 25
        @ObservationPublished @ObservationIgnored
        fileprivate(set) var name = "John"
        @ObservationPublished @ObservationIgnored
        public var surname = "Doe"

        package var initials: String {
            get { "\(name.prefix(1))\(surname.prefix(1))" }
            set { _ = newValue }
        }
    }
}
