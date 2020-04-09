//
//  HTTPMethod.swift
//  Covid
//
//  Created by ksmirnov on 02.04.2020.
//  Copyright © 2020 ksmirnov. All rights reserved.
//

import Foundation

enum HTTPMethod: String {
    case connect = "CONNECT"
    case delete  = "DELETE"
    case get     = "GET"
    case head    = "HEAD"
    case options = "OPTIONS"
    case patch   = "PATCH"
    case post    = "POST"
    case put     = "PUT"
    case trace   = "TRACE"
}
