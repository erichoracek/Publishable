//
//  PublishableMacroTests.swift
//  Publishable
//
//  Created by Kamil Strzelecki on 12/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

#if canImport(PublishableMacros)
    import PublishableMacros
    import SwiftSyntaxMacros
    import SwiftSyntaxMacrosTestSupport
    import XCTest

    internal final class PublishableMacroTests: XCTestCase {

        private let macros: [String: any Macro.Type] = [
            "Publishable": PublishableMacro.self
        ]

        func testExpansion() {
            assertMacroExpansion(
                #"""
                @Publishable @Observable
                public final class Person {

                    static var user: Person?

                    let id: UUID
                    @ObservationPublished @ObservationIgnored
                    fileprivate(set) var age: Int
                    @ObservationPublished @ObservationIgnored
                    var name: String

                    public var surname: String {
                        didSet {
                            print(oldValue)
                        }
                    }

                    internal var fullName: String {
                        "\(name) \(surname)"
                    }

                    package var initials: String {
                        get { "\(name.prefix(1))\(surname.prefix(1))" }
                        set { _ = newValue }
                    }
                }
                """#,
                expandedSource:
                #"""
                @Observable
                public final class Person {

                    static var user: Person?

                    let id: UUID
                    @ObservationPublished @ObservationIgnored
                    fileprivate(set) var age: Int
                    @ObservationPublished @ObservationIgnored
                    var name: String

                    public var surname: String {
                        didSet {
                            print(oldValue)
                        }
                    }

                    internal var fullName: String {
                        "\(name) \(surname)"
                    }

                    package var initials: String {
                        get { "\(name.prefix(1))\(surname.prefix(1))" }
                        set { _ = newValue }
                    }

                    public private(set) lazy var publisher = PropertyPublisher(object: self)

                    public final class PropertyPublisher: AnyPropertyPublisher<Person> {

                        deinit {
                            _age.send(completion: .finished)
                            _name.send(completion: .finished)
                        }

                        fileprivate let _age = PassthroughSubject<Int, Never>()
                        var age: some Publisher<Int, Never> {
                            _storedPropertyPublisher(_age, for: \.age)
                        }
                        fileprivate let _name = PassthroughSubject<String, Never>()
                        var name: some Publisher<String, Never> {
                            _storedPropertyPublisher(_name, for: \.name)
                        }
                    }

                    private nonisolated func publishable_shouldNotifyObservers<__macro_local_6MemberfMu_>(_ lhs: __macro_local_6MemberfMu_, _ rhs: __macro_local_6MemberfMu_) -> Bool {
                        true
                    }

                    private nonisolated func publishable_shouldNotifyObservers<__macro_local_6MemberfMu0_: Equatable>(_ lhs: __macro_local_6MemberfMu0_, _ rhs: __macro_local_6MemberfMu0_) -> Bool {
                        lhs != rhs
                    }

                    private nonisolated func publishable_shouldNotifyObservers<__macro_local_6MemberfMu1_: AnyObject>(_ lhs: __macro_local_6MemberfMu1_, _ rhs: __macro_local_6MemberfMu1_) -> Bool {
                        lhs !== rhs
                    }

                    private nonisolated func publishable_shouldNotifyObservers<__macro_local_6MemberfMu2_: Equatable & AnyObject>(_ lhs: __macro_local_6MemberfMu2_, _ rhs: __macro_local_6MemberfMu2_) -> Bool {
                        lhs != rhs
                    }
                }

                extension Person: Publishable {
                }
                """#,
                macros: macros
            )
        }

        func testMainActorExpansion() {
            assertMacroExpansion(
                #"""
                @MainActor
                @Publishable @Observable
                public final class Person {

                    static var user: Person?

                    let id: UUID
                    @ObservationPublished @ObservationIgnored
                    fileprivate(set) var age: Int
                    @ObservationPublished @ObservationIgnored
                    var name: String

                    public var surname: String {
                        didSet {
                            print(oldValue)
                        }
                    }

                    internal var fullName: String {
                        "\(name) \(surname)"
                    }

                    package var initials: String {
                        get { "\(name.prefix(1))\(surname.prefix(1))" }
                        set { _ = newValue }
                    }
                }
                """#,
                expandedSource:
                #"""
                @MainActor
                @Observable
                public final class Person {

                    static var user: Person?

                    let id: UUID
                    @ObservationPublished @ObservationIgnored
                    fileprivate(set) var age: Int
                    @ObservationPublished @ObservationIgnored
                    var name: String

                    public var surname: String {
                        didSet {
                            print(oldValue)
                        }
                    }

                    internal var fullName: String {
                        "\(name) \(surname)"
                    }

                    package var initials: String {
                        get { "\(name.prefix(1))\(surname.prefix(1))" }
                        set { _ = newValue }
                    }

                    public private(set) lazy var publisher = PropertyPublisher(object: self)

                    @MainActor
                    public final class PropertyPublisher: AnyPropertyPublisher<Person> {

                        deinit {
                            _age.send(completion: .finished)
                            _name.send(completion: .finished)
                        }

                        fileprivate let _age = PassthroughSubject<Int, Never>()
                        var age: some Publisher<Int, Never> {
                            _storedPropertyPublisher(_age, for: \.age)
                        }
                        fileprivate let _name = PassthroughSubject<String, Never>()
                        var name: some Publisher<String, Never> {
                            _storedPropertyPublisher(_name, for: \.name)
                        }
                    }

                    private nonisolated func publishable_shouldNotifyObservers<__macro_local_6MemberfMu_>(_ lhs: __macro_local_6MemberfMu_, _ rhs: __macro_local_6MemberfMu_) -> Bool {
                        true
                    }

                    private nonisolated func publishable_shouldNotifyObservers<__macro_local_6MemberfMu0_: Equatable>(_ lhs: __macro_local_6MemberfMu0_, _ rhs: __macro_local_6MemberfMu0_) -> Bool {
                        lhs != rhs
                    }

                    private nonisolated func publishable_shouldNotifyObservers<__macro_local_6MemberfMu1_: AnyObject>(_ lhs: __macro_local_6MemberfMu1_, _ rhs: __macro_local_6MemberfMu1_) -> Bool {
                        lhs !== rhs
                    }

                    private nonisolated func publishable_shouldNotifyObservers<__macro_local_6MemberfMu2_: Equatable & AnyObject>(_ lhs: __macro_local_6MemberfMu2_, _ rhs: __macro_local_6MemberfMu2_) -> Bool {
                        lhs != rhs
                    }
                }

                extension Person: MainActorPublishable {
                }
                """#,
                macros: macros
            )
        }

        func testPlatformConditionalExpansion() {
            assertMacroExpansion(
                #"""
                @MainActor
                @Publishable @Observable
                public final class Person {

                    static var user: Person?

                    let id: UUID
                    #if os(macOS)
                    @ObservationPublished @ObservationIgnored
                    fileprivate(set) var age: Int
                    #endif
                    @ObservationPublished @ObservationIgnored
                    var name: String

                    public var surname: String {
                        didSet {
                            print(oldValue)
                        }
                    }

                    internal var fullName: String {
                        "\(name) \(surname)"
                    }

                    package var initials: String {
                        get { "\(name.prefix(1))\(surname.prefix(1))" }
                        set { _ = newValue }
                    }
                }
                """#,
                expandedSource:
                #"""
                @MainActor
                @Observable
                public final class Person {

                    static var user: Person?

                    let id: UUID
                    #if os(macOS)
                    @ObservationPublished @ObservationIgnored
                    fileprivate(set) var age: Int
                    #endif
                    @ObservationPublished @ObservationIgnored
                    var name: String

                    public var surname: String {
                        didSet {
                            print(oldValue)
                        }
                    }

                    internal var fullName: String {
                        "\(name) \(surname)"
                    }

                    package var initials: String {
                        get { "\(name.prefix(1))\(surname.prefix(1))" }
                        set { _ = newValue }
                    }

                    public private(set) lazy var publisher = PropertyPublisher(object: self)

                    @MainActor
                    public final class PropertyPublisher: AnyPropertyPublisher<Person> {

                        deinit {
                            #if os(macOS)
                            _age.send(completion: .finished)
                            #endif
                            _name.send(completion: .finished)
                        }

                        #if os(macOS)
                        fileprivate let _age = PassthroughSubject<Int, Never>()
                        var age: some Publisher<Int, Never> {
                            _storedPropertyPublisher(_age, for: \.age)
                        }
                        #endif
                        fileprivate let _name = PassthroughSubject<String, Never>()
                        var name: some Publisher<String, Never> {
                            _storedPropertyPublisher(_name, for: \.name)
                        }
                    }

                    private nonisolated func publishable_shouldNotifyObservers<__macro_local_6MemberfMu_>(_ lhs: __macro_local_6MemberfMu_, _ rhs: __macro_local_6MemberfMu_) -> Bool {
                        true
                    }

                    private nonisolated func publishable_shouldNotifyObservers<__macro_local_6MemberfMu0_: Equatable>(_ lhs: __macro_local_6MemberfMu0_, _ rhs: __macro_local_6MemberfMu0_) -> Bool {
                        lhs != rhs
                    }

                    private nonisolated func publishable_shouldNotifyObservers<__macro_local_6MemberfMu1_: AnyObject>(_ lhs: __macro_local_6MemberfMu1_, _ rhs: __macro_local_6MemberfMu1_) -> Bool {
                        lhs !== rhs
                    }

                    private nonisolated func publishable_shouldNotifyObservers<__macro_local_6MemberfMu2_: Equatable & AnyObject>(_ lhs: __macro_local_6MemberfMu2_, _ rhs: __macro_local_6MemberfMu2_) -> Bool {
                        lhs != rhs
                    }
                }

                extension Person: MainActorPublishable {
                }
                """#,
                macros: macros
            )
        }
    }
#endif
