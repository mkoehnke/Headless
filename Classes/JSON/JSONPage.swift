//
// JSONPage.swift
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

/**
 *  Protocol, which must be implemented by JSON models in order to get decoded.
 */
public protocol JSONDecodable {
    /**
     Returns the decoded JSON data represented as an model object.
     
     - parameter json: The JSON data.
     
     - returns: The model object.
     */
    static func decode(_ json: JSONElement) -> Self?
}

/**
 *  Protocol, which must be implemented by objects in order to get parsed as JSON.
 */
public protocol JSONParsable {
    /**
     Returns the parsable JSON data.
     
     - returns: The JSON data.
     */
    func content() -> JSON?
}


/// JSONPage class, which represents the entire JSON document.
open class JSONPage : JSONParser, Page, JSONParsable {
    
    /**
     Returns a JSON page instance for the specified JSON data.
     
     - parameter data: The JSON data.
     - parameter url:  The URL of the page.
     
     - returns: A JSON page.
     */
    open static func pageWithData(_ data: Data?, url: URL?) -> Page? {
        if let data = data {
            return JSONPage(data: data, url: url)
        }
        return nil
    }
}
