//
// Helper.swift
//
// Copyright (c) 2015 Mathias Koehnke (http://www.mathiaskoehnke.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation


public enum SearchType<T: HTMLElement> {
    /**
     * Returns an element that matches the specified id.
     */
    case id(String)
    /**
     * Returns all elements matching the specified value for their name attribute.
     */
    case name(String)
    /**
     * Returns all elements with inner content, that contain the specified text.
     */
    case text(String)
    /**
     * Returns all elements that match the specified class name.
     */
    case `class`(String)
    /**
     Returns all elements that match the specified attribute name/value combination.
     */
    case attribute(String, String)
    /**
     Returns all elements with an attribute containing the specified value.
     */
    case contains(String, String)
    /**
     Returns all elements that match the specified XPath query.
     */
    case XPathQuery(String)
    
    func xPathQuery() -> String {
        switch self {
        case .text(let value): return T.createXPathQuery("[contains(text(),'\(value)')]")
        case .id(let id): return T.createXPathQuery("[@id='\(id)']")
        case .name(let name): return T.createXPathQuery("[@name='\(name)']")
        case .attribute(let key, let value): return T.createXPathQuery("[@\(key)='\(value)']")
        case .class(let className): return T.createXPathQuery("[@class='\(className)']")
        case .contains(let key, let value): return T.createXPathQuery("[contains(@\(key), '\(value)')]")
        case .XPathQuery(let query): return query
        }
    }
}

//========================================
// MARK: Result
//========================================

public enum Result<T> {
    case success(T)
    case error(ActionError)
    
    init(_ error: ActionError?, _ value: T) {
        if let err = error {
            self = .error(err)
        } else {
            self = .success(value)
        }
    }
}

public extension Result where T:Collection {
    public func first<A>() -> Result<A> {
        switch self {
        case .success(let result): return resultFromOptional(result.first as? A, error: .notFound)
        case .error(let error): return resultFromOptional(nil, error: error)
        }
    }
}

extension Result: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .success(let value):
            return "Success: \(String(describing: value))"
        case .error(let error):
            return "Error: \(String(describing: error))"
        }
    }
}

//========================================
// MARK: Response
//========================================

internal struct Response {
    var data: Data?
    var statusCode: Int = ActionError.Static.DefaultStatusCodeError
    
    init(data: Data?, urlResponse: URLResponse) {
        self.data = data
        if let httpResponse = urlResponse as? HTTPURLResponse {
            self.statusCode = httpResponse.statusCode
        }
    }
    
    init(data: Data?, statusCode: Int) {
        self.data = data
        self.statusCode = statusCode
    }
}

infix operator >>>: AdditionPrecedence
internal func >>><A, B>(a: Result<A>, f: (A) -> Result<B>) -> Result<B> {
    switch a {
    case let .success(x):   return f(x)
    case let .error(error): return .error(error)
    }
}

/**
 This Operator equates to the andThen() method. Here, the left-hand side Action will be started 
 and the result is used as parameter for the right-hand side Action.
 
 - parameter a: An Action.
 - parameter f: A Function.
 
 - returns: An Action.
 */
public func >>><T, U>(a: Action<T>, f: @escaping (T) -> Action<U>) -> Action<U> {
    return a.andThen(f)
}

/**
 This Operator equates to the andThen() method with the exception, that the result of the left-hand
 side Action will be ignored and not passed as paramter to the right-hand side Action.
 
 - parameter a: An Action.
 - parameter b: An Action.
 
 - returns: An Action.
 */
public func >>><T, U>(a: Action<T>, b: Action<U>) -> Action<U> {
    let f : ((T) -> Action<U>) = { _ in b }
    return a.andThen(f)
}


/**
 This Operator equates to the andThen() method with the exception, that the result of the left-hand
 side Action will be ignored and not passed as paramter to the right-hand side Action.

 *Note:* This a workaround to remove the brackets of functions without any parameters (e.g. **inspect()**)
 to provide a consistent API.
 */
public func >>><T, U: Page>(a: Action<T>, f: () -> Action<U>) -> Action<U> {
    return a >>> f()
}

/**
 This Operator equates to the andThen() method. Here, the left-hand side Action will be started
 and the result is used as parameter for the right-hand side Action.
 
 *Note:* This a workaround to remove the brackets of functions without any parameters (e.g. **inspect()**)
 to provide a consistent API.
 */
public func >>><T:Page, U>(a: () -> Action<T>, f: @escaping (T) -> Action<U>) -> Action<U> {
    return a() >>> f
}

/**
 This Operator starts the left-hand side Action and passes the result as Optional to the 
 function on the right-hand side.
 
 - parameter a:          An Action.
 - parameter completion: A Completion Block.
 */
public func ===<T>(a: Action<T>, completion: @escaping (T?) -> Void) {
    return a.start { result in
        switch result {
        case .success(let value): completion(value)
        case .error: completion(nil)
        }
    }
}

/**
 This operator passes the left-hand side Action and passes the result it to the 
 function/closure on the right-hand side.
 
 - parameter a:          An Action.
 - parameter completion: An output function/closure.
 */
public func ===<T>(a: Action<T>, completion: @escaping (Result<T>) -> Void) {
    return a.start { result in
        completion(result)
    }
}

internal func parseResponse(_ response: Response) -> Result<Data> {
    let successRange = 200..<300
    if !successRange.contains(response.statusCode) {
        return .error(.networkRequestFailure)
    }
    return Result(nil, response.data ?? Data())
}

internal func resultFromOptional<A>(_ optional: A?, error: ActionError) -> Result<A> {
    if let a = optional {
        return .success(a)
    } else {
        return .error(error)
    }
}

internal func decodeResult<T: Page>(_ url: URL? = nil) -> (_ data: Data?) -> Result<T> {
    return { (data: Data?) -> Result<T> in
        return resultFromOptional(T.pageWithData(data, url: url) as? T, error: .networkRequestFailure)
    }
}

internal func decodeString(_ data: Data?) -> Result<String> {
    return resultFromOptional(data?.toString(), error: .transformFailure)
}

//========================================
// MARK: Actions
// Borrowed from Javier Soto's 'Back to the Futures' Talk
// https://speakerdeck.com/javisoto/back-to-the-futures
//========================================

public struct Action<T> {
    public typealias ResultType = Result<T>
    public typealias Completion = (ResultType) -> ()
    public typealias AsyncOperation = (@escaping Completion) -> ()
    
    fileprivate let operation: AsyncOperation
    
    public init(result: ResultType) {
        self.init(operation: { completion in
            DispatchQueue.main.async(execute: {
                completion(result)
            })
        })
    }
    
    public init(value: T) {
        self.init(result: .success(value))
    }
    
    public init(error: ActionError) {
        self.init(result: .error(error))
    }
    
    public init(operation: @escaping AsyncOperation) {
        self.operation = operation
    }
    
    public func start(_ completion: @escaping Completion) {
        self.operation() { result in
            DispatchQueue.main.async(execute: {
                completion(result)
            })
        }
    }
}

public extension Action {
    public func map<U>(_ f: @escaping (T) -> U) -> Action<U> {
        return Action<U>(operation: { completion in
            self.start { result in
                DispatchQueue.main.async(execute: {
                    switch result {
                    case .success(let value): completion(Result.success(f(value)))
                    case .error(let error): completion(Result.error(error))
                    }
                })
            }
        })
    }
    
    public func flatMap<U>(_ f: @escaping (T) -> U?) -> Action<U> {
        return Action<U>(operation: { completion in
            self.start { result in
                DispatchQueue.main.async(execute: {
                    switch result {
                    case .success(let value):
                        if let result = f(value) {
                            completion(Result.success(result))
                        } else {
                            completion(Result.error(.transformFailure))
                        }
                    case .error(let error): completion(Result.error(error))
                    }
                })
            }
        })
    }
    
    public func andThen<U>(_ f: @escaping (T) -> Action<U>) -> Action<U> {
        return Action<U>(operation: { completion in
            self.start { firstFutureResult in
                switch firstFutureResult {
                case .success(let value): f(value).start(completion)
                case .error(let error):
                    DispatchQueue.main.async(execute: {
                        completion(Result.error(error))
                    })
                }
            }
        })
    }
}


//========================================
// MARK: Convenience Methods
//========================================

public extension Action {
    
    /**
     Executes the specified action (with the result of the previous action execution as input parameter) until
     a certain condition is met. Afterwards, it will return the collected action results.
     
     - parameter initial: The initial input parameter for the Action.
     - parameter f:       The Action which will be executed.
     - parameter until:   If 'true', the execution of the specified Action will stop.
     
     - returns: The collected Sction results.
     */
    internal static func collect(_ initial: T, f: @escaping (T) -> Action<T>, until: @escaping (T) -> Bool) -> Action<[T]> {
        var values = [T]()
        func loop(_ future: Action<T>) -> Action<[T]> {
            return Action<[T]>(operation: { completion in
                future.start { result in
                    switch result {
                    case .success(let newValue):
                        values.append(newValue)
                        if until(newValue) == true {
                            loop(f(newValue)).start(completion)
                        } else {
                            DispatchQueue.main.async(execute: {
                                completion(Result.success(values))
                            })
                        }
                    case .error(let error):
                        DispatchQueue.main.async(execute: {
                            completion(Result.error(error))
                        })
                    }
                }
            })
        }
        return loop(f(initial))
    }
    
    /**
     Makes a bulk execution of the specified action with the provided input values. Once all actions have
     finished, the collected results will be returned.
     
     - parameter elements: An array containing the input value for the Action.
     - parameter f:        The Action.
     
     - returns: The collected Action results.
     */
    internal static func batch<U>(_ elements: [T], f: @escaping (T) -> Action<U>) -> Action<[U]> {
        return Action<[U]>(operation: { completion in
            let group = DispatchGroup()
            var results = [U]()
            for element in elements {
                group.enter()
                f(element).start({ result in
                    switch result {
                    case .success(let value):
                        results.append(value)
                        group.leave()
                    case .error(let error):
                        DispatchQueue.main.async(execute: {
                            completion(Result.error(error))
                        })
                    }
                })
            }
            group.notify(queue: DispatchQueue.main) {
                completion(Result.success(results))
            }
        })
    }
}


//========================================
// MARK: Post Action
//========================================

/**
An wait/validation action that will be performed after the page has reloaded.
*/
public enum PostAction {
    /**
     The time in seconds that the action will wait (after the page has been loaded) before returning.
     This is useful in cases where the page loading has been completed, but some JavaScript/Image loading
     is still in progress.
     
     - returns: Time in Seconds.
     */
    case wait(TimeInterval)
    /**
     The action will complete if the specified JavaScript expression/script returns 'true'
     or a timeout occurs.
     
     - returns: Validation Script.
     */
    case validate(String)
    /// No Post Action will be performed.
    case none
}


//========================================
// MARK: JSON
// Inspired by Tony DiPasquale's Article 
// https://robots.thoughtbot.com/efficient-json-in-swift-with-functional-concepts-and-generics
//========================================

public typealias JSON = Any
public typealias JSONElement = [String : Any]

internal func parseJSON<U: JSON>(_ data: Data) -> Result<U> {
    var jsonOptional: U?
    var __error = ActionError.parsingFailure
    
    do {
        if let data = htmlToData(NSString(data: data, encoding: String.Encoding.utf8.rawValue)) {
            jsonOptional = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? U
        }
    } catch _ {
        __error = .parsingFailure
        jsonOptional = nil
    }
    
    return resultFromOptional(jsonOptional, error: __error)
}

internal func decodeJSON<U: JSONDecodable>(_ json: JSON?) -> Result<U> {
    if let element = json as? JSONElement {
        return resultFromOptional(U.decode(element), error: .parsingFailure)
    }
    return Result.error(.parsingFailure)
}

internal func decodeJSON<U: JSONDecodable>(_ json: JSON?) -> Result<[U]> {
    let result = [U]()
    if let elements = json as? [JSONElement] {
        var result = [U]()
        for element in elements {
            let decodable : Result<U> = decodeJSON(element as JSON?)
            switch decodable {
            case .success(let value): result.append(value)
            case .error(let error): return Result.error(error)
            }
        }
    }
    return Result.success(result)
}



//========================================
// MARK: Helper Methods
//========================================


private func htmlToData(_ html: NSString?) -> Data? {
    if let html = html {
        let json = html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: NSMakeRange(0, html.length))
        return json.data(using: String.Encoding.utf8)
    }
    return nil
}

extension Dictionary : JSONParsable {
    public func content() -> JSON? {
        return self
    }
}

extension Array : JSONParsable {
    public func content() -> JSON? {
        return self
    }
}

extension String {
    internal func terminate() -> String {
        let terminator : Character = ";"
        var trimmed = trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if (trimmed.characters.last != terminator) { trimmed += String(terminator) }
        return trimmed
    }
}

extension Data {
    internal func toString() -> String? {
        return String(data: self, encoding: String.Encoding.utf8)
    }
}


func dispatch_sync_on_main_thread(_ block: ()->()) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.sync(execute: block)
    }
}

internal func delay(_ time: TimeInterval, completion: @escaping () -> Void) {
    if let currentQueue = OperationQueue.current?.underlyingQueue {
        let delayTime = DispatchTime.now() + Double(Int64(time * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        currentQueue.asyncAfter(deadline: delayTime) {
            completion()
        }
    } else {
        completion()
    }
}
