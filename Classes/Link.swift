//
//  Link.swift
//  HeadlessDemo
//
//  Created by Mathias Köhnke on 23/11/15.
//  Copyright © 2015 Mathias Köhnke. All rights reserved.
//

import Foundation

public class Link : Element {
    
    private var baseURL : NSURL? {
        return pageURL?.baseURL ?? pageURL
    }

    public var href : String? {
        return text
    }
    
    public var linkText : String? {
        return content
    }
    
    public var hrefURL : NSURL? {
        if let href = href, url = NSURL(string: href) {
            if let baseURL = baseURL where url.scheme.characters.count == 0 {
                return NSURL(string: url.relativePath!, relativeToURL: baseURL)
            }
            return url
        }
        return nil
    }
    
    public required init?(element: AnyObject, pageURL: NSURL? = nil) {
        super.init(element: element, pageURL: pageURL)
    }
    
    override public var description : String {
        return href ?? ""
    }
}

// attributes
// href
// text

// click()


    