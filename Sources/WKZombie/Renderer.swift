//
// Renderer.swift
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
import WebKit


typealias RenderCompletion = (_ result : Any?, _ response: URLResponse?, _ error: Error?) -> Void

internal class Renderer {
    
    var loadMediaContent : Bool = true

    @available(OSX 10.11, *)
    var userAgent : String? {
        get {
            return self.webView.customUserAgent
        }
        set {
            self.webView.customUserAgent = newValue
        }
    }
    
    var timeoutInSeconds : TimeInterval = 30.0
    
    var showNetworkActivity : Bool = true
    
    internal static let scrapingCommand = "document.documentElement.outerHTML"
    
    internal var authenticationHandler : AuthenticationHandler?
    
    fileprivate var renderQueue : OperationQueue = {
        let instance = OperationQueue()
        instance.maxConcurrentOperationCount = 1
        instance.qualityOfService = .userInitiated
       return instance
    }()
    
    fileprivate var webView : WKWebView!
    
    
    init(processPool: WKProcessPool? = nil) {
        let doneLoadingWithoutMediaContentScript = "window.webkit.messageHandlers.doneLoading.postMessage(\(Renderer.scrapingCommand));"
        let doneLoadingUserScript = WKUserScript(source: doneLoadingWithoutMediaContentScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        
        let getElementByXPathScript = "function getElementByXpath(path) { " +
                                      "   return document.evaluate(path, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue; " +
                                      "}"
        let getElementUserScript = WKUserScript(source: getElementByXPathScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        
        let contentController = WKUserContentController()
        contentController.addUserScript(doneLoadingUserScript)
        contentController.addUserScript(getElementUserScript)

        let config = WKWebViewConfiguration()
        config.processPool = processPool ?? WKProcessPool()
        config.userContentController = contentController
        
        /// Note: The WKWebView behaves very unreliable when rendering offscreen
        /// on a device. This is especially true with JavaScript, which simply 
        /// won't be executed sometimes.
        /// Therefore, I decided to add this very ugly hack where the rendering
        /// webview will be added to the view hierarchy (between the 
        /// rootViewController's view and the key window.
        /// Until there's no better solution, we'll have to roll with this.
        dispatch_sync_on_main_thread {
            let warning = "The keyWindow or contentView is missing."
            #if os(iOS)
                let bounds = UIScreen.main.bounds
                self.webView = WKWebView(frame: bounds, configuration: config)
                if let window = UIApplication.shared.keyWindow {
                    self.webView.alpha = 0.01
                    window.insertSubview(self.webView, at: 0)
                } else {
                    Logger.log(warning)
                }
            #elseif os(OSX)
                self.webView = WKWebView(frame: CGRect.zero, configuration: config)
                if let window = NSApplication.shared.keyWindow, let view = window.contentView {
                    self.webView.frame = CGRect(origin: CGPoint.zero, size: view.frame.size)
                    self.webView.alphaValue = 0.01
                    view.addSubview(self.webView)
                } else {
                    Logger.log(warning)
                }
            #endif
        }
    }
    
    deinit {
        dispatch_sync_on_main_thread {
            self.webView.removeFromSuperview()
        }
    }
        
    //========================================
    // MARK: Render Page
    //========================================
    
    internal func renderPageWithRequest(_ request: URLRequest, postAction: PostAction = .none, completionHandler: @escaping RenderCompletion) {
        let requestBlock : (_ operation: RenderOperation?) -> Void = { operation in
            DispatchQueue.main.async {
                if let url = request.url , url.isFileURL {
                    if #available(OSX 10.11, *) {
                        _ = operation?.webView?.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
                    } else {
                        preconditionFailure("OSX version lower 10.11 not supported.")
                    }
                } else {
                    _ = operation?.webView?.load(request)
                }
            }
        }
        let operation = operationWithRequestBlock(requestBlock, postAction: postAction, completionHandler: completionHandler)
        operation.name = "Request".uppercased() + "\n\(request.url?.absoluteString ?? String())"
        renderQueue.addOperation(operation)
    }
    
    
    //========================================
    // MARK: Execute JavaScript
    //========================================
    
    internal func executeScript(_ script: String, willLoadPage: Bool? = false, postAction: PostAction = .none, completionHandler: RenderCompletion?) {
        var requestBlock : RequestBlock
        if let willLoadPage = willLoadPage , willLoadPage == true {
            requestBlock = { operation in
                DispatchQueue.main.async {
                    operation.webView?.evaluateJavaScript(script, completionHandler: nil)
                }
            }
        } else {
            requestBlock = { operation in
                DispatchQueue.main.async {
                    operation.webView?.evaluateJavaScript(script, completionHandler: { result, error in
                        var data : Data?
                        if let result = result {
                            data = "\(result)".data(using: String.Encoding.utf8)
                        }
                        operation.completeRendering(operation.webView, result: data, error: error)
                    })
                }
            }
        }
        let operation = operationWithRequestBlock(requestBlock, postAction: postAction, completionHandler: completionHandler)
        operation.name = "Script".uppercased() + "\n\(script )"
        renderQueue.addOperation(operation)
    }
    
    //========================================
    // MARK: Helper Methods
    //========================================
    
    fileprivate func operationWithRequestBlock(_ requestBlock: @escaping (_ operation: RenderOperation) -> Void, postAction: PostAction = .none, completionHandler: RenderCompletion?) -> Operation {
        let operation = RenderOperation(webView: webView, timeoutInSeconds: timeoutInSeconds)
        operation.loadMediaContent = loadMediaContent
        operation.showNetworkActivity = showNetworkActivity
        operation.postAction = postAction
        operation.completionBlock = { [weak operation] in
            completionHandler?(operation?.result, operation?.response, operation?.error)
        }
        operation.requestBlock = requestBlock
        operation.authenticationBlock = authenticationHandler
        return operation
    }
    
    internal func currentContent(_ completionHandler: @escaping RenderCompletion) {
        webView.evaluateJavaScript(Renderer.scrapingCommand.terminate()) { result, error in
            var data : Data?
            if let result = result {
                data = "\(result)".data(using: String.Encoding.utf8)
            }
            completionHandler(data as AnyObject?, nil, error as Error?)
        }
    }
    
}

//========================================
// MARK: Cache
//========================================

extension Renderer {
    @available(OSX 10.11, *)
    internal func clearCache() {
        let distantPast = Date.distantPast
        HTTPCookieStorage.shared.removeCookies(since: distantPast)
        let websiteDataTypes = Set([WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes, modifiedSince: distantPast, completionHandler:{ })
    }
}


//========================================
// MARK: Snapshot
//========================================

#if os(iOS)
extension Renderer {
    internal func snapshot() -> Snapshot? {
        precondition(webView.superview != nil, "WKWebView has no superview. Cannot take snapshot.")
        UIGraphicsBeginImageContextWithOptions(webView.bounds.size, true, 0)
        webView.scrollView.drawHierarchy(in: webView.bounds, afterScreenUpdates: false)
        let snapshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if let data = snapshot!.pngData() {
            return Snapshot(data: data, page: webView.url)
        }
        return nil
    }
}
#endif
