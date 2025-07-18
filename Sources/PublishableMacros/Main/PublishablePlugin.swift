//
//  PublishablePlugin.swift
//  Publishable
//
//  Created by Kamil Strzelecki on 11/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros

@main
internal struct PublishablePlugin: CompilerPlugin {

    let providingMacros: [any Macro.Type] = [
        PublishableMacro.self,
        ObservationPublishedMacro.self
    ]
}
