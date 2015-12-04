//
//  Parser.swift
//  HeadlessDemo
//
//  Created by Mathias Köhnke on 28/11/15.
//  Copyright © 2015 Mathias Köhnke. All rights reserved.
//

import Foundation
import hpple

public class Parser : NSObject {
    
    private var doc : TFHpple?
    public private(set) var url : NSURL?
    
    init(data: NSData, url: NSURL? = nil) {
        super.init()
        self.doc = TFHpple(HTMLData: data)
        self.url = url
    }
    
    public func searchWithXPathQuery(xPathOrCSS: String) -> [AnyObject]? {
        return doc?.searchWithXPathQuery(xPathOrCSS)
    }
    
    public var data: NSData? {
        return doc?.data
    }
    
    override public var description : String {
        return (NSString(data: doc?.data ?? NSData(), encoding: NSUTF8StringEncoding) ?? "") as String
    }
}



public class ParserElement : NSObject {
    private var element : TFHppleElement?
    public internal(set) var pageURL : NSURL?
    
    required public init?(element: AnyObject, pageURL: NSURL? = nil) {
        super.init()
        if let element = element as? TFHppleElement {
            self.element = element
            self.pageURL = pageURL
        } else {
            return nil
        }
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
    
    public func objectForKey(key: String) -> String? {
        return element?.objectForKey(key) as String?
    }
    
    public var children: [Element]? {
        return element?.children.flatMap { Element(element:$0, pageURL: pageURL) }
    }
    
    public func childrenWithTagName(tagName: String) -> [Element]? {
        return element?.childrenWithTagName(tagName).flatMap { Element(element: $0, pageURL: pageURL) }
    }
    
    override public var description : String {
        return element?.raw ?? ""
    }
}
