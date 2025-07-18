//
//  PublishableMacro.swift
//  Publishable
//
//  Created by Kamil Strzelecki on 12/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import SwiftSyntax
import SwiftSyntaxMacros

public enum PublishableMacro {

    private static func validate(
        _ declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) -> ClassDeclSyntax? {
        guard let declaration = declaration as? ClassDeclSyntax,
              declaration.attributes.contains(likeOneOf: "@Observable", "@Model"),
              declaration.isFinal
        else {
            context.diagnose(
                node: declaration,
                errorMessage: "Publishable macro can only be applied to final @Observable or @Model classes"
            )
            return nil
        }
        return declaration
    }
}

extension PublishableMacro: MemberMacro {

    public static func expansion(
        of _: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let declaration = validate(declaration, in: context) else {
            return []
        }

        let properties = PropertiesParser.parse(
            memberBlock: declaration.memberBlock,
            in: context
        )

        // Propagate @MainActor isolation if declared on the type
        let isMainActor = declaration.attributes.contains(likeOneOf: "@MainActor")
        let builderTypes: [any ClassDeclBuilder] = [
            PublisherDeclBuilder(declaration: declaration, properties: properties),
            PropertyPublisherDeclBuilder(declaration: declaration, properties: properties, mainActor: isMainActor)
        ]

        let builderDecls = try builderTypes.flatMap { builderType in
            try builderType.build()
        }

        var declarations = [DeclSyntax]()

        guard let identified = declaration.asProtocol((any NamedDeclSyntax).self) else {
            return []
        }
        let observableType = identified.name.trimmed
        declaration.addIfNeeded(Self.shouldNotifyObserversNonEquatableFunction(observableType, context: context), to: &declarations)
        declaration.addIfNeeded(Self.shouldNotifyObserversEquatableFunction(observableType, context: context), to: &declarations)
        declaration.addIfNeeded(Self.shouldNotifyObserversNonEquatableObjectFunction(observableType, context: context), to: &declarations)
        declaration.addIfNeeded(Self.shouldNotifyObserversEquatableObjectFunction(observableType, context: context), to: &declarations)

        return builderDecls + declarations
    }

    static let moduleName = "Observation"
    static let ignoredMacroName = "ObservationIgnored"

    static let registrarTypeName = "ObservationRegistrar"
    static var qualifiedRegistrarTypeName: String {
        "\(moduleName).\(registrarTypeName)"
    }

    static let registrarVariableName = "_$observationRegistrar"

    static func registrarVariable(_: TokenSyntax, context _: some MacroExpansionContext) -> DeclSyntax {
        """
        @\(raw: ignoredMacroName) private let \(raw: registrarVariableName) = \(raw: qualifiedRegistrarTypeName)()
        """
    }

    static func accessFunction(_ observableType: TokenSyntax, context: some MacroExpansionContext) -> DeclSyntax {
        let memberGeneric = context.makeUniqueName("Member")
        return
            """
            internal nonisolated func access<\(memberGeneric)>(
              keyPath: KeyPath<\(observableType), \(memberGeneric)>
            ) {
              \(raw: registrarVariableName).access(self, keyPath: keyPath)
            }
            """
    }

    static func withMutationFunction(_ observableType: TokenSyntax, context: some MacroExpansionContext) -> DeclSyntax {
        let memberGeneric = context.makeUniqueName("Member")
        let mutationGeneric = context.makeUniqueName("MutationResult")
        return
            """
            internal nonisolated func withMutation<\(memberGeneric), \(mutationGeneric)>(
              keyPath: KeyPath<\(observableType), \(memberGeneric)>,
              _ mutation: () throws -> \(mutationGeneric)
            ) rethrows -> \(mutationGeneric) {
              try \(raw: registrarVariableName).withMutation(of: self, keyPath: keyPath, mutation)
            }
            """
    }

    static func shouldNotifyObserversNonEquatableFunction(_: TokenSyntax, context: some MacroExpansionContext) -> DeclSyntax {
        let memberGeneric = context.makeUniqueName("Member")
        return
            """
             private nonisolated func publishable_shouldNotifyObservers<\(memberGeneric)>(_ lhs: \(memberGeneric), _ rhs: \(memberGeneric)) -> Bool { true }
            """
    }

    static func shouldNotifyObserversEquatableFunction(_: TokenSyntax, context: some MacroExpansionContext) -> DeclSyntax {
        let memberGeneric = context.makeUniqueName("Member")
        return
            """
            private nonisolated func publishable_shouldNotifyObservers<\(memberGeneric): Equatable>(_ lhs: \(memberGeneric), _ rhs: \(memberGeneric)) -> Bool { lhs != rhs }
            """
    }

    static func shouldNotifyObserversNonEquatableObjectFunction(_: TokenSyntax, context: some MacroExpansionContext) -> DeclSyntax {
        let memberGeneric = context.makeUniqueName("Member")
        return
            """
             private nonisolated func publishable_shouldNotifyObservers<\(memberGeneric): AnyObject>(_ lhs: \(memberGeneric), _ rhs: \(memberGeneric)) -> Bool { lhs !== rhs }
            """
    }

    static func shouldNotifyObserversEquatableObjectFunction(_: TokenSyntax, context: some MacroExpansionContext) -> DeclSyntax {
        let memberGeneric = context.makeUniqueName("Member")
        return
            """
            private nonisolated func publishable_shouldNotifyObservers<\(memberGeneric): Equatable & AnyObject>(_ lhs: \(memberGeneric), _ rhs: \(memberGeneric)) -> Bool { lhs != rhs }
            """
    }
}

extension PublishableMacro: ExtensionMacro {

    public static func expansion(
        of _: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard validate(declaration, in: context) != nil else {
            return []
        }

        let isMainActor = declaration.attributes.contains(likeOneOf: "@MainActor")

        return [
            .init(
                extendedType: type,
                inheritanceClause: .init(
                    inheritedTypes: [
                        .init(type: IdentifierTypeSyntax(name: isMainActor ? "MainActorPublishable" : "Publishable"))
                    ]
                ),
                memberBlock: "{}"
            )
        ]
    }
}
