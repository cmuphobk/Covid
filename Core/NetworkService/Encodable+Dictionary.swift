//
//  Encodable+Dictionary.swift
//  Covid
//
//  Created by ksmirnov on 02.04.2020.
//  Copyright © 2020 ksmirnov. All rights reserved.
//

import Foundation

extension Encodable {
    
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : Any]
        return dictionary ?? [:]
    }
    
}
