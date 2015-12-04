//
//  Headless.swift
//  HeadlessDemo
//
//  Created by Mathias Köhnke on 23/11/15.
//  Copyright © 2015 Mathias Köhnke. All rights reserved.
//

import Foundation


public class Headless : NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate {
    
    private var renderer : Renderer!
    public private(set) var name : String!
    public var allowRedirects : Bool = true
    
    
    public init(name: String? = "Headless") {
        super.init()
        self.name = name
        self.renderer = Renderer()
    }
 
    public func get(url: NSURL) -> Future<Page, Error> {
        return Future() { [unowned self] completion in
            let request = NSURLRequest(URL: url)
            self.renderer.renderPageWithRequest(request, completionHandler: { data, response, error in
                completion(self.handleResponse(data as? NSData, response: response, error: error))
            })
        }
    }

    public func get(url: NSURL, condition: String) -> Future<Page, Error> {
        return Future(error: Error.NetworkRequestFailure)
    }
    
    public func get(url: NSURL, wait: NSTimeInterval) -> Future<Page, Error> {
        return Future(error: Error.NetworkRequestFailure)
    }
    
    public func submit(form: Form) -> Future<Page, Error> {
        return Future() { [unowned self] completion in
            if let name = form.name {
                let script = self.formSubmitScript(name, values: form.inputs)
                self.renderer.executeScript(script, waitForReload: true, completionHandler: { result, response, error in
                    completion(self.handleResponse(result as? NSData, response: response, error: error))
                })
            } else {
                completion(Result.Error(.NetworkRequestFailure))
            }
        }
    }
    
    public func click(link : Link) -> Future<Page, Error> {
        return Future() { [unowned self] completion in
            if let url = link.href {
                let script = self.clickLinkScript(url)
                self.renderer.executeScript(script, waitForReload: true, completionHandler: { result, response, error in
                    completion(self.handleResponse(result as? NSData, response: response, error: error))
                })
                //let task = self.session.dataTaskWithRequest(NSURLRequest(URL: url)) { [unowned self] data, response, error in
                //    completion(self.handleResponse(data, response: response, error: error))
                //}
                //task.resume()
            } else {
                completion(Result.Error(.NetworkRequestFailure))
            }
        }
    }
    
    //
    // MARK: Private
    //
    private func handleResponse(data: NSData?, response: NSURLResponse?, error: NSError?) -> Result<Page, Error> {
        guard let response = response else {
            return decodeResult(nil)(data: nil)
        }
        let errorDomain : Error? = (error == nil) ? nil : .NetworkRequestFailure
        let responseResult: Result<Response, Error> = Result(errorDomain, Response(data: data, urlResponse: response))
        return responseResult >>> parseResponse >>> decodeResult(response.URL)
    }
    
    
    // MARK : Scripts
    
    private func formSubmitScript(name: String, values: [String: String]?) -> String {
        var script = String()
        for (key, value) in values! {
            script += "document.\(name).\(key).value='\(value)';\n"
        }
        script += "document.\(name).submit();"
        return script
    }
    
    private func clickLinkScript(href: String) -> String {
        return "window.location.href='\(href)';"
    }
}