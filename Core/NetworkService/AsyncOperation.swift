//
//  AsyncOperation.swift
//  Covid
//
//  Created by ksmirnov on 02.04.2020.
//  Copyright © 2020 ksmirnov. All rights reserved.
//

import Foundation

class AsyncOperation: Operation {
    
    enum State: String {
        case ready
        case executing
        case finished
        
        fileprivate var keyPath: String {
            return "is" + self.rawValue.capitalized
        }
    }
    
    var state = State.ready {
        willSet {
            self.willChangeValue(forKey: newValue.keyPath)
            self.willChangeValue(forKey: self.state.keyPath)
        }
        didSet {
            self.didChangeValue(forKey: oldValue.keyPath)
            self.didChangeValue(forKey: self.state.keyPath)
        }
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    override var isReady: Bool {
        return super.isReady && self.state == .ready
    }
    override var isExecuting: Bool {
        return self.state == .executing
    }
    override var isFinished: Bool {
        return self.state == .finished
    }

    override func start() {
        if isCancelled {
            self.state = .finished
            return
        }
        self.main()
        state = .executing
    }
    
    override func cancel() {
        super.cancel()
        self.state = .finished
    }
}
