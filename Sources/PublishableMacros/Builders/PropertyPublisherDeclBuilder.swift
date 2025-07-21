//
//  PropertyPublisherDeclBuilder.swift
//  Publishable
//
//  Created by Kamil Strzelecki on 12/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

internal struct PropertyPublisherDeclBuilder: ClassDeclBuilder {

    let declaration: ClassDeclSyntax
    let properties: PropertiesList
    let mainActor: Bool

    var settings: DeclBuilderSettings {
        .init(accessControlLevel: .init(inheritingDeclaration: .member))
    }

    func build() -> [DeclSyntax] { // swiftlint:disable:this type_contents_order
        if mainActor {
            [
                """
                @MainActor
                \(inheritedAccessControlLevel)final class PropertyPublisher: AnyPropertyPublisher<\(trimmedTypeName)> {

                    \(deinitializer())

                    \(storedPropertiesPublishers().formatted())
                }
                """
            ]
        } else {
            [
                """
                \(inheritedAccessControlLevel)final class PropertyPublisher: AnyPropertyPublisher<\(trimmedTypeName)> {

                    \(deinitializer())

                    \(storedPropertiesPublishers().formatted())
                }
                """
            ]
        }
    }

    private func deinitializer() -> MemberBlockItemListSyntax {
        """
        deinit {
            \(storedPropertiesPublishersFinishCalls().formatted())
        }
        """
    }

    @CodeBlockItemListBuilder
    private func storedPropertiesPublishersFinishCalls() -> CodeBlockItemListSyntax {
        for property in properties.stored.mutable.instance.all where property.declaration.hasMacroApplication(ObservationPublishedMacro.name) {
            if let ifConfig = property.ifConfig {
                """
                \(raw: ifConfig.poundKeyword.text) \(raw: ifConfig.condition?.trimmedDescription ?? "")
                _\(property.trimmedName).send(completion: .finished)
                #endif
                """
            } else {
                "_\(property.trimmedName).send(completion: .finished)"
            }
        }
    }

    @MemberBlockItemListBuilder
    private func storedPropertiesPublishers() -> MemberBlockItemListSyntax {
        for property in properties.stored.mutable.instance where property.declaration.hasMacroApplication(ObservationPublishedMacro.name) {
            let accessControlLevel = property.declaration.accessControlLevel(inheritedBy: .peer, maxAllowed: .public)
            let name = property.trimmedName
            let type = property.inferredType
            if let ifConfig = property.ifConfig {
                """
                \(raw: ifConfig.poundKeyword.text) \(raw: ifConfig.condition?.trimmedDescription ?? "")
                fileprivate let _\(name) = PassthroughSubject<\(type), Never>()
                \(accessControlLevel)var \(name): some Publisher<\(type), Never> {
                    _storedPropertyPublisher(_\(name), for: \\.\(name))
                }
                #endif
                """
            } else {
                """
                fileprivate let _\(name) = PassthroughSubject<\(type), Never>()
                \(accessControlLevel)var \(name): some Publisher<\(type), Never> {
                    _storedPropertyPublisher(_\(name), for: \\.\(name))
                }
                """
            }
        }
    }
}
