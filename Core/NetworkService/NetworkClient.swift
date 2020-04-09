//
//  NetworkService.swift
//  Covid
//
//  Created by ksmirnov on 02.04.2020.
//  Copyright © 2020 ksmirnov. All rights reserved.
//

import Foundation

final class NetworkService: NSObject {
    
    enum NetworkSerivceError: Error {
        case unknown
    }
    
    private let baseURL: URL
    private let configuration: URLSessionConfiguration = URLSessionConfiguration.default
    
    private let fileManager: FileManager = FileManager.default
    
    init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    private lazy var session = URLSession(configuration: configuration)
    
    func executNetworkRequest<Request: NetworkRequest, Response: Codable>(
        _ request: Request,
        completion: @escaping (Result<Response, Error>) -> Void
    ) {
        var urlRequest: URLRequest?
        do {
            urlRequest = try request.urlRequest(baseURL)
        } catch {
            completion(.failure(error))
            return
        }
        guard let urlRequestUnwrapped = urlRequest else {
            completion(.failure(NetworkSerivceError.unknown))
            return
        }
        let task = session.dataTask(with: urlRequestUnwrapped) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard
                let data = data,
                let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                    // FIXME: - handle status code or empty data and return error after handling
                    completion(.failure(NetworkSerivceError.unknown))
                    return
            }
            
            if let str = String(data: data, encoding: String.Encoding.utf8) { print(str) }
            do {
                let response: Response = try JSONDecoder().decode(Response.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
                return
            }
        }
        task.resume()
    }
    
    func download<Request: NetworkRequest>(
        _ request: Request,
        to locations: [URL],
        completion: @escaping (Result<[URL], Error>) -> Void
    ) {
        download(request) { [weak self] result in
            guard let self = self else {
                completion(.failure(NetworkSerivceError.unknown))
                return
            }
            
            switch result {
            case .success(let localURL):
                do {
                    var forSavingURLs: [URL] = []
                    for forSavingURL in locations {
                        if self.fileManager.fileExists(atPath: forSavingURL.path) {
                            try self.fileManager.removeItem(at: forSavingURL)
                        }
                        let directory = forSavingURL.deletingLastPathComponent()
                        if !self.fileManager.fileExists(atPath: directory.path) {
                            try self.fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
                        }
                        try self.fileManager.copyItem(at: localURL, to: forSavingURL)
                        forSavingURLs.append(forSavingURL)
                    }
                    try self.fileManager.removeItem(at: localURL)
                    completion(.success(forSavingURLs))
                } catch {
                    completion(.failure(error))
                    return
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func download<Request: NetworkRequest>(
        _ request: Request,
        to location: URL? = nil,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        download(request) { [weak self] result in
            guard let self = self else {
                completion(.failure(NetworkSerivceError.unknown))
                return
            }
            switch result {
            case .success(let localURL):
                do {
                    let forSavingURL: URL!
                    if let location = location {
                        forSavingURL = location
                    } else {
                        let documentURL = try self.fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                        forSavingURL = documentURL.appendingPathComponent(localURL.lastPathComponent)
                    }
                    if self.fileManager.fileExists(atPath: forSavingURL.path) {
                        try self.fileManager.removeItem(at: forSavingURL)
                    }
                    try self.fileManager.moveItem(at: localURL, to: forSavingURL)
                    completion(.success(forSavingURL))
                } catch {
                    completion(.failure(error))
                    return
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func download<Request: NetworkRequest>(
        _ request: Request,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        var urlRequest: URLRequest?
        do {
            urlRequest = try request.urlRequest(baseURL)
        } catch {
            completion(.failure(error))
            return
        }
        guard let urlRequestUnwrapped = urlRequest else {
            completion(.failure(NetworkSerivceError.unknown))
            return
        }
        let task = session.downloadTask(with: urlRequestUnwrapped) { (localURL, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard
                let localURL = localURL,
                let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                    // FIXME: - handle status code or empty data and return error after handling
                    completion(.failure(NetworkSerivceError.unknown))
                    return
            }
            completion(.success(localURL))
        }
        task.resume()
    }

}
