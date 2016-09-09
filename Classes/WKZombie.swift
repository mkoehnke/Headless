//
// WKZombie.swift
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
import WebKit

open class WKZombie : NSObject {
    
    private static var __once: () = {  Static.instance = WKZombie() }()
    
    /// A shared instance of `Manager`, used by top-level WKZombie methods,
    /// and suitable for multiple web sessions.
    open class var sharedInstance: WKZombie {
        _ = WKZombie.__once
        return Static.instance!
    }
    
    internal struct Static {
        static var token : Int = 0
        static var instance : WKZombie?
    }
    
    fileprivate var _renderer : Renderer!
    fileprivate var _fetcher : ContentFetcher!
    
    /// Returns the name of this WKZombie session.
    open fileprivate(set) var name : String!
    
    /// If false, the loading progress will finish once the 'raw' HTML data
    /// has been transmitted. Media content such as videos or images won't
    /// be loaded.
    open var loadMediaContent : Bool = true {
        didSet {
            _renderer.loadMediaContent = loadMediaContent
        }
    }
    
    /// The custom user agent string or nil if no custom user agent string has been set.
    open var userAgent : String? {
        get {
            return self._renderer.userAgent
        }
        set {
            self._renderer.userAgent = newValue
        }
    }
    
    /// An operation is cancelled if the time it needs to complete exceeds the time 
    /// specified by this property. Default is 30 seconds.
    open var timeoutInSeconds : TimeInterval {
        get {
            return self._renderer.timeoutInSeconds
        }
        set {
            self._renderer.timeoutInSeconds = newValue
        }
    }
    
    #if os(iOS)
    /// Snapshot Handler
    open var snapshotHandler : SnapshotHandler?
    #endif
    
    /**
     The designated initializer.
     
     - parameter name: The name of the WKZombie session.
     
     - returns: A WKZombie instance.
     */
    public init(name: String? = "WKZombie", processPool: WKProcessPool? = nil) {
        super.init()
        self.name = name
        self._renderer = Renderer(processPool: processPool)
        self._fetcher = ContentFetcher()
    }
    
    //========================================
    // MARK: Response Handling
    //========================================
    
    fileprivate func _handleResponse(_ data: Data?, response: URLResponse?, error: Error?) -> Result<Data> {
        var statusCode : Int = (error == nil) ? ActionError.Static.DefaultStatusCodeSuccess : ActionError.Static.DefaultStatusCodeError
        if let response = response as? HTTPURLResponse {
            statusCode = response.statusCode
        }
        let errorDomain : ActionError? = (error == nil) ? nil : .networkRequestFailure
        let responseResult: Result<Response> = Result(errorDomain, Response(data: data, statusCode: statusCode))
        return responseResult >>> parseResponse
    }
    
    //========================================
    // MARK: HTMLRedirectable Handling
    //========================================
    
    fileprivate func redirect<T: Page, U: HTMLRedirectable>(then postAction: PostAction = .none) -> (_ redirectable : U) -> Action<T> {
        return { (redirectable: U) -> Action<T> in
            return Action() { [unowned self] completion in
                if let script = redirectable.actionScript() {
                    self._renderer.executeScript(script, willLoadPage: true, postAction: postAction, completionHandler: { result, response, error in
                        let data = self._handleResponse(result as? Data, response: response, error: error)
                        completion(data >>> decodeResult(response?.url))
                    })
                } else {
                    completion(Result.error(.networkRequestFailure))
                }
            }
        }
    }
}


//========================================
// MARK: Get Page
//========================================

extension WKZombie {
    /**
     The returned WKZombie Action will load and return a HTML or JSON page for the specified URL.
     
     - parameter url: An URL referencing a HTML or JSON page.
     
     - returns: The WKZombie Action.
     */
    public func open<T: Page>(_ url: URL) -> Action<T> {
        return open(then: .none)(url)
    }
    
    /**
     The returned WKZombie Action will load and return a page for the specified URL.
     
     - parameter postAction: An wait/validation action that will be performed after the page has finished loading.
     - parameter url: An URL referencing a HTML or JSON page.
     
     - returns: The WKZombie Action.
     */
    public func open<T: Page>(then postAction: PostAction) -> (_ url: URL) -> Action<T> {
        return { (url: URL) -> Action<T> in
            return Action() { [unowned self] completion in
                let request = URLRequest(url: url)
                self._renderer.renderPageWithRequest(request, postAction: postAction, completionHandler: { data, response, error in
                    let data = self._handleResponse(data as? Data, response: response, error: error)
                    completion(data >>> decodeResult(response?.url))
                })
            }
        }
    }
    
    /**
     The returned WKZombie Action will return the current page.
     
     - returns: The WKZombie Action.
     */
    public func inspect<T: Page>() -> Action<T> {
        return Action() { [unowned self] completion in
            self._renderer.currentContent({ (result, response, error) in
                let data = self._handleResponse(result as? Data, response: response, error: error)
                completion(data >>> decodeResult(response?.url))
            })
        }
    }
}


//========================================
// MARK: Submit Form
//========================================

extension WKZombie {
    /**
     Submits the specified HTML form.
     
     - parameter form: A HTML form.
     
     - returns: The WKZombie Action.
     */
    public func submit<T: Page>(_ form: HTMLForm) -> Action<T> {
        return submit(then: .none)(form)
    }
    
    /**
     Submits the specified HTML form.
     
     - parameter postAction: An wait/validation action that will be performed after the page has reloaded.
     - parameter url: An URL referencing a HTML or JSON page.
     
     - returns: The WKZombie Action.
     */
    public func submit<T: Page>(then postAction: PostAction) -> (_ form: HTMLForm) -> Action<T> {
        return { (form: HTMLForm) -> Action<T> in
            return Action() { [unowned self] completion in
                if let script = form.actionScript() {
                    self._renderer.executeScript(script, willLoadPage: true, postAction: postAction, completionHandler: { result, response, error in
                        let data = self._handleResponse(result as? Data, response: response, error: error)
                        completion(data >>> decodeResult(response?.url))
                    })
                } else {
                    completion(Result.error(.networkRequestFailure))
                }
            }
        }
    }
}


//========================================
// MARK: Click Event
//========================================

extension WKZombie {
    /**
     Simulates the click of a HTML link.
     
     - parameter link: The HTML link.
     
     - returns: The WKZombie Action.
     */
    public func click<T: Page>(_ link : HTMLLink) -> Action<T> {
        return click(then: .none)(link)
    }
    
    /**
     Simulates the click of a HTML link.
     
     - parameter postAction: An wait/validation action that will be performed after the page has reloaded.
     - parameter link: The HTML link.
     
     - returns: The WKZombie Action.
     */
    public func click<T: Page>(then postAction: PostAction) -> (_ link : HTMLLink) -> Action<T> {
        return { [unowned self] (link: HTMLLink) -> Action<T> in
            return self.redirect(then: postAction)(link)
        }
    }
    
    /**
     Simulates HTMLButton press.
     
     - parameter button: The HTML button.
     
     - returns: The WKZombie Action.
     */
    public func press<T: Page>(_ button : HTMLButton) -> Action<T> {
        return press(then: .none)(button)
    }
    
    /**
     Simulates HTMLButton press.
     
     - parameter postAction: An wait/validation action that will be performed after the page has reloaded.
     - parameter button: The HTML button.
     
     - returns: The WKZombie Action.
     */
    public func press<T: Page>(then postAction: PostAction) -> (_ button : HTMLButton) -> Action<T> {
        return { [unowned self] (button: HTMLButton) -> Action<T> in
            return self.redirect(then: postAction)(button)
        }
    }
}

//========================================
// MARK: Swap Page Context
//========================================

extension WKZombie {
    /**
     The returned WKZombie Action will swap the current page context with the context of an embedded iframe.
     
     - parameter iframe: The HTMLFrame (iFrame).
     
     - returns: The WKZombie Action.
     */
    public func swap<T: Page>(_ iframe : HTMLFrame) -> Action<T> {
        return swap(then: .none)(iframe)
    }
    
    /**
     The returned WKZombie Action will swap the current page context with the context of an embedded iFrame.
     
     - parameter postAction: An wait/validation action that will be performed after the page has reloaded.
     - parameter iframe: The HTMLFrame (iFrame).
     
     - returns: The WKZombie Action.
     */
    public func swap<T: Page>(then postAction: PostAction) -> (_ iframe : HTMLFrame) -> Action<T> {
        return { [unowned self] (iframe: HTMLFrame) -> Action<T> in
            return self.redirect(then: postAction)(iframe)
        }
    }
}

//========================================
// MARK: DOM Modification Methods
//========================================

extension WKZombie {
    
    /**
     The returned WKZombie Action will set or update a attribute/value pair on the specified HTMLElement.
     
     - parameter key:   A Attribute Name.
     - parameter value: A Value.
     - parameter element: A HTML element.
     
     - returns: The WKZombie Action.
     */
    public func setAttribute<T: HTMLElement>(_ key: String, value: String?) -> (_ element: T) -> Action<HTMLPage> {
        return { (element: T) -> Action<HTMLPage> in
            return Action() { [unowned self] completion in
                if let script = element.createSetAttributeCommand(key, value: value) {
                    self._renderer.executeScript("\(script) \(Renderer.scrapingCommand.terminate())", completionHandler: { result, response, error in
                        completion(decodeResult(nil)(result as? Data))
                    })
                } else {
                    completion(Result.error(.networkRequestFailure))
                }
            }
        }
    }
    
}

//========================================
// MARK: Find Methods
//========================================

extension WKZombie {    
    /**
     The returned WKZombie Action will search a page and return all elements matching the generic HTML element type and
     the passed key/value attributes.
     
     - parameter by: Key/Value Pairs.
     - parameter page: A HTML page.
     
     - returns: The WKZombie Action.
     */
    public func getAll<T: HTMLElement>(by searchType: SearchType<T>) -> (_ page: HTMLPage) -> Action<[T]> {
        return { (page: HTMLPage) -> Action<[T]> in
            let elements : Result<[T]> = page.findElements(searchType)
            return Action(result: elements)
        }
    }
        
    /**
     The returned WKZombie Action will search a page and return the first element matching the generic HTML element type and
     the passed key/value attributes.
     
     - parameter by: Key/Value Pairs.
     - parameter page: A HTML page.
     
     - returns: The WKZombie Action.
     */
    public func get<T: HTMLElement>(by searchType: SearchType<T>) -> (_ page: HTMLPage) -> Action<T> {
        return { (page: HTMLPage) -> Action<T> in
            let elements : Result<[T]> = page.findElements(searchType)
            return Action(result: elements.first())
        }
    }
}

//========================================
// MARK: JavaScript Methods
//========================================

public typealias JavaScript = String
public typealias JavaScriptResult = String

extension WKZombie {
    
    /**
     The returned WKZombie Action will execute a JavaScript string.
     
     - parameter script: A JavaScript string.
     
     - returns: The WKZombie Action.
     */
    public func execute(_ script: JavaScript) -> Action<JavaScriptResult> {
        return Action() { [unowned self] completion in
            self._renderer.executeScript(script, completionHandler: { result, response, error in
                let data = self._handleResponse(result as? Data, response: response, error: error)
                let output = data >>> decodeString
                Logger.log("Script Result".uppercased() + "\n\(output)\n")
                completion(output)
            })
        }
    }
    
    /**
     The returned WKZombie Action will execute a JavaScript string.
     
     - parameter script: A JavaScript string.
     - parameter page: A HTML page.
     
     - returns: The WKZombie Action.
     */
    public func execute<T: HTMLPage>(_ script: JavaScript) -> (_ page : T) -> Action<JavaScriptResult> {
        return { [unowned self] (page : T) -> Action<JavaScriptResult> in
            return self.execute(script)
        }
    }
}


//========================================
// MARK: Fetch Actions
//========================================

extension WKZombie {
    /**
     The returned WKZombie Action will download the linked data of the passed HTMLFetchable object.
     
     - parameter fetchable: A HTMLElement that implements the HTMLFetchable protocol.
     
     - returns: The WKZombie Action.
     */
    public func fetch<T: HTMLFetchable>(_ fetchable: T) -> Action<T> {
        return Action() { [unowned self] completion in
            if let fetchURL = fetchable.fetchURL {
                self._fetcher.fetch(fetchURL, completion: { (result, response, error) in
                    let data = self._handleResponse(result, response: response, error: error)
                    switch data {
                    case .success(let value): fetchable.fetchedData = value
                    case .error(let error):
                        completion(Result.error(error))
                        return
                    }
                    completion(Result.success(fetchable))
                })
            } else {
                completion(Result.error(.notFound))
            }
        }
    }
}


//========================================
// MARK: Transform Actions
//========================================

extension WKZombie {
    /**
     The returned WKZombie Action will transform a HTMLElement into another HTMLElement using the specified function.
     
     - parameter f: The function that takes a certain HTMLElement as parameter and transforms it into another HTMLElement.
     - parameter object: A HTML element.
     
     - returns: The WKZombie Action.
     */
    public func map<T, A>(_ f: @escaping (T) -> A) -> (_ object: T) -> Action<A> {
        return { (object: T) -> Action<A> in
            return Action(result: resultFromOptional(f(object), error: .notFound))
        }
    }
    
    /**
     This function transforms an object into another object using the specified closure.
     
     - parameter f: The closure that takes an object as parameter and transforms it into another object.
     - parameter object: An object.
     
     - returns: The transformed object.
     */
    public func map<T, A>(_ f: @escaping (T) -> A) -> (_ object: T) -> A {
        return { (object: T) -> A in
            return f(object)
        }
    }
}

//========================================
// MARK: Advanced Actions
//========================================

extension WKZombie {
    /**
     Executes the specified action (with the result of the previous action execution as input parameter) until
     a certain condition is met. Afterwards, it will return the collected action results.
     
     - parameter f:       The Action which will be executed.
     - parameter until:   If 'true', the execution of the specified Action will stop.
     - parameter initial: The initial input parameter for the Action.
     
     - returns: The collected Sction results.
     */
    public func collect<T>(_ f: @escaping (T) -> Action<T>, until: @escaping (T) -> Bool) -> (_ initial: T) -> Action<[T]> {
        return { (initial: T) -> Action<[T]> in
            return Action.collect(initial, f: f, until: until)
        }
    }
    
    /**
     Makes a bulk execution of the specified action with the provided input values. Once all actions have
     finished, the collected results will be returned.
     
     - parameter f:        The Action.
     - parameter elements: An array containing the input value for the Action.
     
     - returns: The collected Action results.
     */
    public func batch<T, U>(_ f: @escaping (T) -> Action<U>) -> (_ elements: [T]) -> Action<[U]> {
        return { (elements: [T]) -> Action<[U]> in
            return Action.batch(elements, f: f)
        }
    }
}

//========================================
// MARK: JSON Actions
//========================================

extension WKZombie {
    
    /**
     The returned WKZombie Action will parse NSData and create a JSON object.
     
     - parameter data: A NSData object.
     
     - returns: A JSON object.
     */
    public func parse<T: JSON>(_ data: Data) -> Action<T> {
        return Action(result: parseJSON(data))
    }
    
    /**
     The returned WKZombie Action will take a JSONParsable (Array, Dictionary and JSONPage) and 
     decode it into a Model object. This particular Model class has to implement the 
     JSONDecodable protocol.
     
     - parameter element: A JSONParsable instance.
     
     - returns: A JSONDecodable object.
     */
    public func decode<T : JSONDecodable>(_ element: JSONParsable) -> Action<T> {
        return Action(result: decodeJSON(element.content()))
    }
    
    /**
     The returned WKZombie Action will take a JSONParsable (Array, Dictionary and JSONPage) and
     decode it into an array of Model objects of the same class. The class has to implement the
     JSONDecodable protocol.
     
     - parameter element: A JSONParsable instance.
     
     - returns: A JSONDecodable array.
     */
    public func decode<T : JSONDecodable>(_ array: JSONParsable) -> Action<[T]> {
        return Action(result: decodeJSON(array.content()))
    }
    
}

#if os(iOS)
    
//========================================
// MARK: Snapshot Methods
//========================================
    
/// Default delay before taking snapshots
private let DefaultSnapshotDelay = 0.1
    
extension WKZombie {
    
    /**
     The returned WKZombie Action will make a snapshot of the current page.
     Note: This method only works under iOS. Also, a snapshotHandler must be registered.
     
     - returns: A snapshot class.
     */
    public func snap<T>(_ element: T) -> Action<T> {
        return Action<T>(operation: { [unowned self] completion in
            delay(DefaultSnapshotDelay, completion: {
                if let snapshotHandler = self.snapshotHandler, let snapshot = self._renderer.snapshot() {
                    snapshotHandler(snapshot)
                    completion(Result.success(element))
                } else {
                    completion(Result.error(.snapshotFailure))
                }
            })
        })
    }
}
    
#endif

//========================================
// MARK: Debug Methods
//========================================

extension WKZombie {
    /**
     Prints the current state of the WKZombie browser to the console.
     */
    public func dump() {
        _renderer.currentContent { (result, response, error) in
            if let output = (result as? Data)?.toString() {
                Logger.log(output)
            } else {
                Logger.log("No Output available.")
            }
        }
    }
    
    /**
     Clears the cache/cookie data (such as login data, etc).
     */
    public func clearCache() {
        _renderer.clearCache()
    }
}
