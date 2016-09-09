//
// Functions.swift
//
// Copyright (c) 2016 Mathias Koehnke (http://www.mathiaskoehnke.com)
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


/**
 Convenience functions for accessing the WKZombie shared instance functionality.
 */

//========================================
// MARK: Get Page
//========================================

/**
 The returned WKZombie Action will load and return a HTML or JSON page for the specified URL 
 __using the shared WKZombie instance__.
 - seealso: _open()_ function in _WKZombie_ class for more info.
 */
public func open<T: Page>(_ url: URL) -> Action<T> {
    return WKZombie.sharedInstance.open(url)
}

/**
 The returned WKZombie Action will load and return a HTML or JSON page for the specified URL 
 __using the shared WKZombie instance__.
 - seealso: _open()_ function in _WKZombie_ class for more info.
 */
public func open<T: Page>(then postAction: PostAction) -> (_ url: URL) -> Action<T> {
    return WKZombie.sharedInstance.open(then: postAction)
}

/**
 The returned WKZombie Action will return the current page __using the shared WKZombie instance__.
 - seealso: _inspect()_ function in _WKZombie_ class for more info.
 */
public func inspect<T: Page>() -> Action<T> {
    return WKZombie.sharedInstance.inspect()
}


//========================================
// MARK: Submit Form
//========================================

/**
 Submits the specified HTML form __using the shared WKZombie instance__.
 - seealso: _submit()_ function in _WKZombie_ class for more info.
 */
public func submit<T: Page>(_ form: HTMLForm) -> Action<T> {
    return WKZombie.sharedInstance.submit(form)
}

/**
 Submits the specified HTML form __using the shared WKZombie instance__.
 - seealso: _submit()_ function in _WKZombie_ class for more info.
 */
public func submit<T: Page>(then postAction: PostAction) -> (_ form: HTMLForm) -> Action<T> {
    return WKZombie.sharedInstance.submit(then: postAction)
}


//========================================
// MARK: Click Event
//========================================

/**
 Simulates the click of a HTML link __using the shared WKZombie instance__.
 - seealso: _click()_ function in _WKZombie_ class for more info.
 */
public func click<T: Page>(_ link : HTMLLink) -> Action<T> {
    return WKZombie.sharedInstance.click(link)
}

/**
 Simulates the click of a HTML link __using the shared WKZombie instance__.
 - seealso: _click()_ function in _WKZombie_ class for more info.
 */
public func click<T: Page>(then postAction: PostAction) -> (_ link : HTMLLink) -> Action<T> {
    return WKZombie.sharedInstance.click(then: postAction)
}

/**
 Simulates HTMLButton press __using the shared WKZombie instance__.
 - seealso: _press()_ function in _WKZombie_ class for more info.
 */
public func press<T: Page>(_ button : HTMLButton) -> Action<T> {
    return WKZombie.sharedInstance.press(button)
}

/**
 Simulates HTMLButton press __using the shared WKZombie instance__.
 - seealso: _press()_ function in _WKZombie_ class for more info.
 */
public func press<T: Page>(then postAction: PostAction) -> (_ button : HTMLButton) -> Action<T> {
    return WKZombie.sharedInstance.press(then: postAction)
}

//========================================
// MARK: Swap Page Context
//========================================

/**
 The returned WKZombie Action will swap the current page context with the context of an embedded iframe.
 - seealso: _swap()_ function in _WKZombie_ class for more info.
 */
public func swap<T: Page>(_ iframe : HTMLFrame) -> Action<T> {
    return WKZombie.sharedInstance.swap(iframe)
}

/**
 The returned WKZombie Action will swap the current page context with the context of an embedded iframe.
 - seealso: _swap()_ function in _WKZombie_ class for more info.
 */
public func swap<T: Page>(then postAction: PostAction) -> (_ iframe : HTMLFrame) -> Action<T> {
    return WKZombie.sharedInstance.swap(then: postAction)
}

//========================================
// MARK: DOM Modification Methods
//========================================

/**
 The returned WKZombie Action will set or update a attribute/value pair on the specified HTMLElement
 __using the shared WKZombie instance__.
 - seealso: _setAttribute()_ function in _WKZombie_ class for more info.
 */
public func setAttribute<T: HTMLElement>(_ key: String, value: String?) -> (_ element: T) -> Action<HTMLPage> {
    return WKZombie.sharedInstance.setAttribute(key, value: value)
}


//========================================
// MARK: Find Methods
//========================================


/**
 The returned WKZombie Action will search a page and return all elements matching the generic HTML element type and
 the passed key/value attributes. __The the shared WKZombie instance will be used__.
 - seealso: _getAll()_ function in _WKZombie_ class for more info.
 */
public func getAll<T: HTMLElement>(by searchType: SearchType<T>) -> (_ page: HTMLPage) -> Action<[T]> {
    return WKZombie.sharedInstance.getAll(by: searchType)
}

/**
 The returned WKZombie Action will search a page and return the first element matching the generic HTML element type and
 the passed key/value attributes. __The shared WKZombie instance will be used__.
 - seealso: _get()_ function in _WKZombie_ class for more info.
 */
public func get<T: HTMLElement>(by searchType: SearchType<T>) -> (_ page: HTMLPage) -> Action<T> {
    return WKZombie.sharedInstance.get(by: searchType)
}


//========================================
// MARK: JavaScript Methods
//========================================


/**
 The returned WKZombie Action will execute a JavaScript string __using the shared WKZombie instance__.
 - seealso: _execute()_ function in _WKZombie_ class for more info.
 */
public func execute(_ script: JavaScript) -> Action<JavaScriptResult> {
    return WKZombie.sharedInstance.execute(script)
}

/**
 The returned WKZombie Action will execute a JavaScript string __using the shared WKZombie instance__.
 - seealso: _execute()_ function in _WKZombie_ class for more info.
 */
public func execute<T: HTMLPage>(_ script: JavaScript) -> (_ page: T) -> Action<JavaScriptResult> {
    return WKZombie.sharedInstance.execute(script)
}


//========================================
// MARK: Fetch Actions
//========================================


/**
 The returned WKZombie Action will download the linked data of the passed HTMLFetchable object 
 __using the shared WKZombie instance__.
 - seealso: _fetch()_ function in _WKZombie_ class for more info.
 */
public func fetch<T: HTMLFetchable>(_ fetchable: T) -> Action<T> {
    return WKZombie.sharedInstance.fetch(fetchable)
}


//========================================
// MARK: Transform Actions
//========================================

/**
 The returned WKZombie Action will transform a HTMLElement into another HTMLElement using the specified function.
 __The shared WKZombie instance will be used__.
 - seealso: _map()_ function in _WKZombie_ class for more info.
 */
public func map<T, A>(_ f: @escaping (T) -> A) -> (_ object: T) -> Action<A> {
    return WKZombie.sharedInstance.map(f)
}

/**
 This function transforms an object into another object using the specified closure.
 - seealso: _map()_ function in _WKZombie_ class for more info.
 */
public func map<T, A>(_ f: @escaping (T) -> A) -> (_ object: T) -> A {
    return WKZombie.sharedInstance.map(f)
}

//========================================
// MARK: Advanced Actions
//========================================


/**
 Executes the specified action (with the result of the previous action execution as input parameter) until
 a certain condition is met. Afterwards, it will return the collected action results.
 __The shared WKZombie instance will be used__.
 - seealso: _collect()_ function in _WKZombie_ class for more info.
 */
public func collect<T>(_ f: @escaping (T) -> Action<T>, until: @escaping (T) -> Bool) -> (_ initial: T) -> Action<[T]> {
    return WKZombie.sharedInstance.collect(f, until: until)
}

/**
 Makes a bulk execution of the specified action with the provided input values. Once all actions have
 finished, the collected results will be returned.
 __The shared WKZombie instance will be used__.
 - seealso: _batch()_ function in _WKZombie_ class for more info.
 */
public func batch<T, U>(_ f: @escaping (T) -> Action<U>) -> (_ elements: [T]) -> Action<[U]> {
    return WKZombie.sharedInstance.batch(f)
}


//========================================
// MARK: JSON Actions
//========================================


/**
 The returned WKZombie Action will parse NSData and create a JSON object.
 __The shared WKZombie instance will be used__.
 - seealso: _parse()_ function in _WKZombie_ class for more info.
 */
public func parse<T: JSON>(_ data: Data) -> Action<T> {
    return WKZombie.sharedInstance.parse(data)
}

/**
 The returned WKZombie Action will take a JSONParsable (Array, Dictionary and JSONPage) and
 decode it into a Model object. This particular Model class has to implement the
 JSONDecodable protocol.
 __The shared WKZombie instance will be used__.
 - seealso: _decode()_ function in _WKZombie_ class for more info.
 */
public func decode<T : JSONDecodable>(_ element: JSONParsable) -> Action<T> {
    return WKZombie.sharedInstance.decode(element)
}

/**
 The returned WKZombie Action will take a JSONParsable (Array, Dictionary and JSONPage) and
 decode it into an array of Model objects of the same class. The class has to implement the
 JSONDecodable protocol.
 __The shared WKZombie instance will be used__.
 - seealso: _decode()_ function in _WKZombie_ class for more info.
 */
public func decode<T : JSONDecodable>(_ array: JSONParsable) -> Action<[T]> {
    return WKZombie.sharedInstance.decode(array)
}


#if os(iOS)
    
    //========================================
    // MARK: Snapshot Methods
    //========================================
    
    /**
     This is a convenience operator for the _snap()_ command. It is equal to the __>>>__ operator with the difference
     that a snapshot will be taken after the left Action has been finished.
     */
    infix operator >>*: AdditionPrecedence
    
    private func assertIfNotSharedInstance() {
        assert(WKZombie.Static.instance != nil, "The >>* operator can only be used with the WKZombie shared instance.")
    }
    
    public func >>*<T, U>(a: Action<T>, f: @escaping ((T) -> Action<U>)) -> Action<U> {
        assertIfNotSharedInstance()
        return a >>> snap >>> f
    }
    
    public func >>*<T, U>(a: Action<T>, b: Action<U>) -> Action<U> {
        assertIfNotSharedInstance()
        return a >>> snap >>> b
    }
    
    public func >>*<T, U: Page>(a: Action<T>, f: () -> Action<U>) -> Action<U> {
        assertIfNotSharedInstance()
        return a >>> snap >>> f
    }
    
    public func >>*<T:Page, U>(a: () -> Action<T>, f: @escaping ((T) -> Action<U>)) -> Action<U> {
        assertIfNotSharedInstance()
        return a >>> snap >>> f
    }
    
    /**
     The returned WKZombie Action will make a snapshot of the current page.
     Note: This method only works under iOS. Also, a snapshotHandler must be registered.
     __The shared WKZombie instance will be used__.
     - seealso: _snap()_ function in _WKZombie_ class for more info.
     */
    public func snap<T>(_ element: T) -> Action<T> {
        return WKZombie.sharedInstance.snap(element)
    }
    
#endif


//========================================
// MARK: Debug Methods
//========================================


/**
 Prints the current state of the WKZombie browser to the console.
 */
public func dump() {
    WKZombie.sharedInstance.dump()
}

/**
 Clears the cache/cookie data (such as login data, etc).
 */
public func clearCache() {
    WKZombie.sharedInstance.clearCache()
}

