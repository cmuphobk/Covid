//
//  NetworkRequest.swift
//  Covid
//
//  Created by ksmirnov on 02.04.2020.
//  Copyright © 2020 ksmirnov. All rights reserved.
//

import Foundation

protocol NetworkRequest {
        
    var path: String { get }
    var method: HTTPMethod { get }
    var parameters: Parameters? { get }
    var headers: [String: String]? { get }
    var encoding: ParameterEncoding { get }
    
    func urlRequest(_ baseURL: URL) throws -> URLRequest
}

extension NetworkRequest {
    
    func urlRequest(_ baseURL: URL) throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var request = try encoding.encode(URLRequest(url: url), with: parameters)
        request.httpMethod = method.rawValue
        
        if let headers = headers {
            var allHTTPHeaderFields = request.allHTTPHeaderFields ?? [:]
            allHTTPHeaderFields.merge(headers, uniquingKeysWith: { _, new in new })
            request.allHTTPHeaderFields = allHTTPHeaderFields
        }
        
        return request
    }
    
}
