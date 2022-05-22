//
//  WordPair.swift
//  Lingo
//
//  Created by Balaji V on 5/19/22.
//

import Foundation

struct WordPair: Codable {
    let english: String
    let spanish:  String

    enum CodingKeys: String, CodingKey {
        case english = "text_eng"
        case spanish = "text_spa"
    }
}
