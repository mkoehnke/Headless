//
// Parser.swift
//
// Copyright (c) 2015 Mathias Koehnke (http://www.mathiaskoehnke.de)
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
import hpple

/// Base class for the HTMLParser and JSONParser.
public class Parser : CustomStringConvertible {
    
    /// The URL of the page.
    public fileprivate(set) var url : URL?
    
    /**
     Returns a (HTML or JSON) parser instance for the specified data.
     
     - parameter data: The encoded data.
     - parameter url:  The URL of the page.
     
     - returns: A HTML or JSON page.
     */
    required public init(data: Data, url: URL? = nil) {
        self.url = url
    }
    
    public var description: String {
        return "\(type(of: self))"
    }
}

//========================================
// MARK: HTML
//========================================

/// A HTML Parser class, which wraps the functionality of the TFHpple class.
public class HTMLParser : Parser {
    
    fileprivate var doc : TFHpple?
    
    required public init(data: Data, url: URL? = nil) {
        super.init(data: data, url: url)
        self.doc = TFHpple(htmlData: data)
    }
    
    public func searchWithXPathQuery(_ xPathOrCSS: String) -> [AnyObject]? {
        return doc?.search(withXPathQuery: xPathOrCSS) as [AnyObject]?
    }
    
    public var data: Data? {
        return doc?.data
    }
    
    override public var description: String {
        return (NSString(data: doc?.data ?? Data(), encoding: String.Encoding.utf8.rawValue) ?? "") as String
    }
}

/// A HTML Parser Element class, which wraps the functionality of the TFHppleElement class.
public class HTMLParserElement : CustomStringConvertible {
    fileprivate var element : TFHppleElement?
    public internal(set) var XPathQuery : String?
    
    required public init?(element: AnyObject, XPathQuery : String? = nil) {
        if let element = element as? TFHppleElement {
            self.element = element
            self.XPathQuery = XPathQuery
        } else {
            return nil
        }
    }
    
    public var innerContent : String? {
        return element?.raw as String?
    }
    
    public var text : String? {
        return element?.text() as String?
    }
    
    public var content : String? {
        return element?.content as String?
    }
    
    public var tagName : String? {
        return element?.tagName as String?
    }
    
    public func objectForKey(_ key: String) -> String? {
        return element?.object(forKey: key.lowercased()) as String?
    }
    
    public func childrenWithTagName<T: HTMLElement>(_ tagName: String) -> [T]? {
        return element?.children(withTagName: tagName).compactMap { T(element: $0 as AnyObject) }
    }
    
    public func children<T: HTMLElement>() -> [T]? {
        return element?.children.compactMap { T(element:$0 as AnyObject) }
    }
    
    public func hasChildren() -> Bool {
        return element?.hasChildren() ?? false
    }
    
    public var description : String {
        return element?.raw ?? ""
    }
}


//========================================
// MARK: JSON
//========================================

/// A JSON Parser class, which represents a JSON document.
public class JSONParser : Parser {
    
    fileprivate var json : JSON?
    
    required public init(data: Data, url: URL? = nil) {
        super.init(data: data, url: url)
        let result : Result<JSON> = parseJSON(data)
        switch result {
        case .success(let json): self.json = json
        case .error: Logger.log("Error parsing JSON!")
        }
    }
    
    public func content() -> JSON? {
        return json
    }
    
    override public var description : String {
        return "\(String(describing: json))"
    }
}



