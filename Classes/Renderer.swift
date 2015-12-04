//
//  Renderer.swift
//  HeadlessDemo
//
//  Created by Mathias Köhnke on 01/12/15.
//  Copyright © 2015 Mathias Köhnke. All rights reserved.
//

import Foundation
import WebKit

internal class Renderer : NSObject, WKScriptMessageHandler, WKNavigationDelegate {
    
    typealias Completion = (result : AnyObject?, response: NSURLResponse?, error: NSError?) -> Void
    //typealias JavaScriptCompletion = (data : AnyObject?, error: NSError?) -> Void
    
    private var renderCompletion : Completion?
    private var renderResponse : NSURLResponse?
    private var renderError : NSError?
    
    private lazy var webView : WKWebView = {
        let jsScrapingString = "window.webkit.messageHandlers.doneLoading.postMessage(document.documentElement.outerHTML);"
        
        //Make the script be injected when the main document is done loading
        let userScript = WKUserScript(source: jsScrapingString, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)
        
        //Create a content controller and add the script and message handler
        let contentController = WKUserContentController()
        contentController.addUserScript(userScript)
        contentController.addScriptMessageHandler(self, name: "doneLoading")
        
        //Create a configuration for the web view
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        //Re-initialize the web view and load the page
        let instance = WKWebView(frame: CGRectZero, configuration: config)
        instance.navigationDelegate = self
        return instance
    }()
    
    
    
    internal func renderPageWithRequest(request: NSURLRequest, completionHandler: Completion) {
        if let _ = renderCompletion {
            NSLog("Rendering already in progress ...")
            return
        }
        
        renderCompletion = completionHandler
        webView.loadRequest(request)
    }
    
    internal func renderPageWithRequest(request: NSURLRequest, condition: String, completionHandler: Completion) {
        // TODO: implement
    }
    
    internal func renderPageWithRequest(request: NSURLRequest, wait: NSTimeInterval, completionHandler: Completion) {
        // TODO: implement
    }
    
    
    internal func executeScript(script: String, waitForReload: Bool? = false, completionHandler: Completion?) {
        if let waitForReload = waitForReload where waitForReload == true {
            renderCompletion = completionHandler
            webView.evaluateJavaScript(script, completionHandler: nil)
        } else {
            let javaScriptCompletionHandler = { (result : AnyObject?, error : NSError?) -> Void in
                completionHandler?(result: result, response: nil, error: error)
            }
            webView.evaluateJavaScript(script, completionHandler: javaScriptCompletionHandler)
        }
    }
    
    internal func executeScript(script: String, waitForReload: Bool? = false, condition: String, completionHandler: Completion?) {
        // TODO: implement
    }
    
    internal func executeScript(script: String, waitForReload: Bool, waitAfterReload: NSTimeInterval, completionHandler: Completion?) {
        // TODO: implement
    }
    
    //
    // MARK: Delegates
    //
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        //None of the content loaded after this point is necessary (images, videos, etc.)
        //webView.stopLoading()
        
        //if let _ = renderCompletion {
        //    print("Received script message: \(message.body)")
        //    renderResult = message.body as? String
        //}
    }
    
    func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
        if let _ = renderCompletion {
            renderResponse = navigationResponse.response
        }
        decisionHandler(.Allow)
    }
    
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        if let _ = renderCompletion {
            renderError = error
        }
        callRenderCompletion(nil)
    }
    
    private func callRenderCompletion(renderResult: String?) {
        let data = renderResult?.dataUsingEncoding(NSUTF8StringEncoding)
        let completion = renderCompletion
        renderCompletion = nil
        completion?(result: data, response: renderResponse, error: renderError)
        renderResponse = nil
        renderError = nil
    }
    
    
    // TODO: Observe webview.loading for getting a more reliable finished state
    // also check document.readyState == 'complete';
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        print("Finish loading")
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(3 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            webView.evaluateJavaScript("document.documentElement.outerHTML;") { [weak self] result, error in
                print(result)
                print("isLoading: \(webView.loading)")
                self?.callRenderCompletion(result as? String)
            }
        }
    }
}