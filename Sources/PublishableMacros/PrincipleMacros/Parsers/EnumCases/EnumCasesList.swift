//
//  EnumCasesList.swift
//  PrincipleMacros
//
//  Created by Kamil Strzelecki on 22/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import SwiftSyntax

public struct EnumCasesList {

    public let all: [EnumCase]

    init(_ all: [EnumCase]) {
        self.all = all
    }
}
