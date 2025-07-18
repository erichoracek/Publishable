//
//  File.swift
//  Publishable
//
//  Created by Eric Horacek on 7/17/25.
//

import SwiftSyntax
import SwiftSyntaxMacros

public struct ObservationPublishedMacro: AccessorMacro {
    public static func expansion(
        of _: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let property = declaration.as(VariableDeclSyntax.self),
              property.isValidForObservation,
              let identifier = property.identifier?.trimmed
        else {
            return []
        }

        guard context.lexicalContext[0].as(ClassDeclSyntax.self) != nil else {
            return []
        }

        let initAccessor: AccessorDeclSyntax =
            """
            @storageRestrictions(initializes: _\(identifier))
            init(initialValue) {
              _\(identifier) = initialValue
            }
            """
        let getAccessor: AccessorDeclSyntax =
            """
            get {
              access(keyPath: \\.\(identifier))
              return _\(identifier)
            }
            """

        // the guard else case must include the assignment else
        // cases that would notify then drop the side effects of `didSet` etc
        let setAccessor: AccessorDeclSyntax =
            """
            set {
              guard publishable_shouldNotifyObservers(_\(identifier), newValue) else {
                _\(identifier) = newValue
                return
              }
              withMutation(keyPath: \\.\(identifier)) {
                _\(identifier) = newValue
              }
              publisher._\(identifier).send(newValue)
            }
            """

        let registrarVariableName = "_$observationRegistrar"

        // Note: this accessor cannot test the equality since it would incur
        // additional CoW's on structural types. Most mutations in-place do
        // not leave the value equal so this is "fine"-ish.
        // Warning to future maintence: adding equality checks here can make
        // container mutation O(N) instead of O(1).
        // e.g. observable.array.append(element) should just emit a change
        // to the new array, and NOT cause a copy of each element of the
        // array to an entirely new array.
        let modifyAccessor: AccessorDeclSyntax =
            """
            _modify {
              access(keyPath: \\.\(identifier))
              \(raw: registrarVariableName).willSet(self, keyPath: \\.\(identifier))
              defer { 
                \(raw: registrarVariableName).didSet(self, keyPath: \\.\(identifier)) 
                publisher._\(identifier).send(\(identifier))
              }
              yield &_\(identifier)
            }
            """

        return [initAccessor, getAccessor, setAccessor, modifyAccessor]
    }

    static var name: String {
        "ObservationPublished"
    }
}

extension ObservationPublishedMacro: PeerMacro {
    public static func expansion(
        of _: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let property = declaration.as(VariableDeclSyntax.self),
              property.isValidForObservation,
              property.identifier?.trimmed != nil
        else {
            return []
        }

        guard context.lexicalContext[0].as(ClassDeclSyntax.self) != nil else {
            return []
        }

        let localContext = LocalMacroExpansionContext(context: context)
        let storage = DeclSyntax(property.privatePrefixed("_", addingAttribute: Self.ignoredAttribute, removingAttribute: Self.trackedAttribute, in: localContext))
        return [storage]
    }

    static var ignoredAttribute: AttributeSyntax {
        AttributeSyntax(
            leadingTrivia: .space,
            atSign: .atSignToken(),
            attributeName: IdentifierTypeSyntax(name: .identifier("ObservationIgnored")),
            trailingTrivia: .space
        )
    }

    static var trackedAttribute: AttributeSyntax {
        AttributeSyntax(
            leadingTrivia: .space,
            atSign: .atSignToken(),
            attributeName: IdentifierTypeSyntax(name: .identifier("ObservationPublished")),
            trailingTrivia: .space
        )
    }
}

struct LocalMacroExpansionContext<Context: MacroExpansionContext> {
    var context: Context
}

extension TokenSyntax {
    func privatePrefixed(_ prefix: String, in _: LocalMacroExpansionContext<some MacroExpansionContext>) -> TokenSyntax {
        switch tokenKind {
        case let .identifier(identifier):
            TokenSyntax(.identifier(prefix + identifier), leadingTrivia: leadingTrivia, trailingTrivia: trailingTrivia, presence: presence)
        default:
            self
        }
    }
}

extension VariableDeclSyntax {
    func privatePrefixed(_ prefix: String, addingAttribute attribute: AttributeSyntax, removingAttribute toRemove: AttributeSyntax, in context: LocalMacroExpansionContext<some MacroExpansionContext>) -> VariableDeclSyntax {
        let newAttributes = attributes.filter { attribute in
            switch attribute {
            case let .attribute(attr):
                attr.attributeName.identifier != toRemove.attributeName.identifier
            default: true
            }
        }
        return VariableDeclSyntax(
            leadingTrivia: leadingTrivia,
            attributes: newAttributes,
            modifiers: modifiers.privatePrefixed(prefix, in: context),
            bindingSpecifier: TokenSyntax(bindingSpecifier.tokenKind, leadingTrivia: .space, trailingTrivia: .space, presence: .present),
            bindings: bindings.privatePrefixed(prefix, in: context),
            trailingTrivia: trailingTrivia
        )
    }

    var isValidForObservation: Bool {
        !isComputed && isInstance && !isImmutable && identifier != nil
    }
}

extension PatternBindingListSyntax {
    func privatePrefixed(_ prefix: String, in context: LocalMacroExpansionContext<some MacroExpansionContext>) -> PatternBindingListSyntax {
        var bindings = map(\.self)
        for index in 0 ..< bindings.count {
            let binding = bindings[index]
            if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                bindings[index] = PatternBindingSyntax(
                    leadingTrivia: binding.leadingTrivia,
                    pattern: IdentifierPatternSyntax(
                        leadingTrivia: identifier.leadingTrivia,
                        identifier: identifier.identifier.privatePrefixed(prefix, in: context),
                        trailingTrivia: identifier.trailingTrivia
                    ),
                    typeAnnotation: binding.typeAnnotation,
                    initializer: binding.initializer,
                    accessorBlock: binding.accessorBlock?.locationAnnotated(in: context),
                    trailingComma: binding.trailingComma,
                    trailingTrivia: binding.trailingTrivia
                )
            }
        }

        return PatternBindingListSyntax(bindings)
    }
}

extension CodeBlockSyntax {
    func locationAnnotated(in context: LocalMacroExpansionContext<some MacroExpansionContext>) -> CodeBlockSyntax {
        guard let firstStatement = statements.first, let loc = context.context.location(of: firstStatement) else {
            return self
        }

        return CodeBlockSyntax(
            leadingTrivia: leadingTrivia,
            leftBrace: leftBrace,
            statements: CodeBlockItemListSyntax {
                "#sourceLocation(file: \(loc.file), line: \(loc.line))"
                statements
                "#sourceLocation()"
            },
            rightBrace: rightBrace,
            trailingTrivia: trailingTrivia
        )
    }
}

extension AccessorDeclSyntax {
    func locationAnnotated(in context: LocalMacroExpansionContext<some MacroExpansionContext>) -> AccessorDeclSyntax {
        AccessorDeclSyntax(
            leadingTrivia: leadingTrivia,
            attributes: attributes,
            modifier: modifier,
            accessorSpecifier: accessorSpecifier,
            parameters: parameters,
            effectSpecifiers: effectSpecifiers,
            body: body?.locationAnnotated(in: context),
            trailingTrivia: trailingTrivia
        )
    }
}

extension AccessorBlockSyntax {
    func locationAnnotated(in context: LocalMacroExpansionContext<some MacroExpansionContext>) -> AccessorBlockSyntax {
        switch accessors {
        case let .accessors(accessorList):
            let remapped = AccessorDeclListSyntax {
                accessorList.map { $0.locationAnnotated(in: context) }
            }
            return AccessorBlockSyntax(accessors: .accessors(remapped))
        case let .getter(codeBlockList):
            return AccessorBlockSyntax(accessors: .getter(codeBlockList))
        }
    }
}

extension DeclModifierListSyntax {
    func privatePrefixed(_: String, in _: LocalMacroExpansionContext<some MacroExpansionContext>) -> DeclModifierListSyntax {
        let modifier = DeclModifierSyntax(name: "private", trailingTrivia: .space)
        return [modifier] + filter {
            switch $0.name.tokenKind {
            case let .keyword(keyword):
                switch keyword {
                case .fileprivate: fallthrough
                case .private: fallthrough
                case .internal: fallthrough
                case .package: fallthrough
                case .public:
                    return false
                default:
                    return true
                }
            default:
                return true
            }
        }
    }

    init(keyword: Keyword) {
        self.init([DeclModifierSyntax(name: .keyword(keyword))])
    }
}
