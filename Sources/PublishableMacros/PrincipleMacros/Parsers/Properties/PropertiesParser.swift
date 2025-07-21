//
//  PropertiesParser.swift
//  PrincipleMacros
//
//  Created by Kamil Strzelecki on 12/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import SwiftSyntax
import SwiftSyntaxMacros

public enum PropertiesParser {

    public static func parse(
        memberBlock: MemberBlockSyntax,
        in context: some MacroExpansionContext
    ) -> PropertiesList {
        PropertiesList(
            memberBlock.members.flatMap { member in
                parse(declaration: member.decl, in: context)
            }
        )
    }

    public static func parse(
        declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext,
        ifConfigClauses: IfConfigClauseSyntax? = nil
    ) -> PropertiesList {
        if let ifConfigDecl = IfConfigDeclSyntax(declaration) {
            return PropertiesList(ifConfigDecl.clauses.flatMap { declaration -> PropertiesList in
                guard let elements = declaration.elements?.as(MemberBlockItemListSyntax.self)
                else {
                    return .init([])
                }

                return PropertiesList(elements.flatMap { item in
                    Self.parse(declaration: item.decl, in: context, ifConfigClauses: declaration)
                })
            })
        }

        guard let declaration = VariableDeclSyntax(declaration) else {
            return .init([])
        }

        return PropertiesList(
            declaration.bindings.compactMap { binding -> Property? in
                guard let name = binding.name else {
                    context.diagnose(
                        node: declaration,
                        errorMessage: "Property cannot be parsed"
                    )
                    return nil
                }

                guard let inferredType = binding.inferredType else {
                    context.diagnose(
                        node: declaration,
                        errorMessage: "Type of property cannot be inferred - provide it explicitly"
                    )
                    return nil
                }

                return Property(
                    declaration: declaration,
                    binding: binding,
                    name: name,
                    inferredType: inferredType,
                    ifConfig: ifConfigClauses
                )
            }
        )
    }
}
