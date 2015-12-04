//
//  Form.swift
//  HeadlessDemo
//
//  Created by Mathias Köhnke on 23/11/15.
//  Copyright © 2015 Mathias Köhnke. All rights reserved.
//

import Foundation

public class Form : Element {

    var inputs = [String : String]()
    
    required public init?(element: AnyObject, pageURL: NSURL? = nil) {
        super.init(element: element, pageURL: pageURL)
        if let element = Element(element: element) {
            self.collectInputs(element)
        }
    }
    
    public var action : String? {
        return objectForKey("action")
    }
    
    private var onSubmit : String? {
        return objectForKey("onSubmit")
    }
    
    public var name : String? {
        return objectForKey("name")
    }
    
    public func actionRequest(customURL: NSURL? = nil) -> NSURLRequest? {
        if let customURL = customURL {
            return createURLRequest(customURL, parameters: inputs)
        } else {
            if hasJavascriptAction() {
                NSLog("Javascript in HTTP form actions is not supported.")
                return nil
            }
            
            if let action = action where action.characters.count > 0 {
                var url : NSURL?
                if action.lowercaseString.hasPrefix("/") {
                    url = NSURL(string: action, relativeToURL: pageURL?.baseURL ?? pageURL)
                } else if action.lowercaseString.hasPrefix("http://") {
                    url = NSURL(string: action)
                } else {
                    url = pageURL?.URLByDeletingLastPathComponent?.URLByAppendingPathComponent(action)
                }
                return createURLRequest(url, parameters: inputs)
            } else {
                return (pageURL == nil) ? nil : createURLRequest(pageURL!, parameters: inputs)
            }
        }
    }
 
    subscript(input: String) -> String? {
        get {
            return inputs[input]
        }
        set (newValue) {
            inputs[input] = newValue
        }
    }
    
    func collectInputs(element: Element) {
        if let tagName = element.tagName as String? where tagName == "input" {
            if let name = element.objectForKey("name") {
                inputs[name] = element.objectForKey("value")
            }
        }
        if let children = element.children where children.count > 0 {
            for child in children {
                collectInputs(child)
            }
        }
    }

    private func createURLRequest(url: NSURL?, parameters: [String : String]) -> NSURLRequest? {
        if let url = url {
            let request = NSMutableURLRequest(URL: url)
            request.encodeParameters(parameters)
            return request
        }
        return nil
    }
    
    private func hasJavascriptAction() -> Bool {
        if let _ = onSubmit {
            return true
        }
        if let action = action where action.lowercaseString.beginsWith("javascript") {
            return true
        }
        return false
    }
}