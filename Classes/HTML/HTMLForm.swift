//
// HTMLForm.swift
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

/// HTML Form class, which represents the <form> element in the DOM.
open class HTMLForm : HTMLElement {

    /// All inputs fields (keys and values) of this form.
    open fileprivate(set) var inputElements = [String : String]()
    
    required public init?(element: AnyObject, XPathQuery: String? = nil) {
        super.init(element: element, XPathQuery: XPathQuery)
        if let element = HTMLElement(element: element, XPathQuery: XPathQuery) {
            retrieveAllInputs(element)
        }
    }
    
    /// Returns the value for the name attribute.
    open var name : String? {
        return objectForKey("name")
    }
    
    /// Returns the value for the id attribute.
    open var id : String? {
        return objectForKey("id")
    }
    
    /// Returns the value for the action attribute.
    open var action : String? {
        return objectForKey("action")
    }
    
    /**
     Enables subscripting for modifying the input field values.
     
     - parameter input: The Input field attribute name.
     
     - returns: The Input field attribute value.
     */
    open subscript(key: String) -> String? {
        return inputElements[key]
    }
    
    //========================================
    // MARK: Form Submit Script
    //========================================
    
    internal func actionScript() -> String? {
        if let name = name {
            return "document.\(name).submit();"
        } else if let id = id {
            return "document.getElementById('\(id)').submit();"
        }
        return nil
    }
    
    //========================================
    // MARK: Overrides
    //========================================
    
    internal override class func createXPathQuery(_ parameters: String) -> String {
        return "//form\(parameters)"
    }
    
    //========================================
    // MARK: Private Methods
    //========================================
    
    fileprivate func retrieveAllInputs(_ element: HTMLElement) {
        if let tagName = element.tagName as String? , tagName == "input" {
            if let name = element.objectForKey("name") {
                inputElements[name] = element.objectForKey("value")
            }
        }
        if let children = element.children() as [HTMLElement]? , children.count > 0 {
            for child in children {
                retrieveAllInputs(child)
            }
        }
    }
}
