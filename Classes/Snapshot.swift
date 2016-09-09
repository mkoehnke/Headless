//
// Snapshot.swift
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

#if os(iOS)
import UIKit
public typealias SnapshotImage = UIImage
#elseif os(OSX)
import Cocoa
public typealias SnapshotImage = NSImage
#endif
    
public typealias SnapshotHandler = (Snapshot) -> Void

/// WKZombie Snapshot Helper Class
open class Snapshot {
    open let page : URL?
    open let file : URL
    open lazy var image : SnapshotImage? = {
        let path = self.file.path
        #if os(iOS)
            return UIImage(contentsOfFile: path)
        #elseif os(OSX)
            return NSImage(contentsOfFile: path)
        #endif
    }()
    
    internal init?(data: Data, page: URL? = nil) {
        do {
            self.file = try Snapshot.store(data)
            self.page = page
        } catch let error as NSError {
            Logger.log("Could not take snapshot: \(error.localizedDescription)")
            return nil
        }
    }
    
    fileprivate static func store(_ data: Data) throws -> URL {
        let identifier = ProcessInfo.processInfo.globallyUniqueString
        
        let fileName = String(format: "wkzombie-snapshot-%@", identifier)
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        try data.write(to: fileURL, options: .atomicWrite)
        
        return fileURL
    }
    
    /**
     Moves the snapshot file into the specified directory.
     
     - parameter directory: A Directory URL.
     
     - throws: Exception if the moving operation fails.
     
     - returns: The URL with the new file location.
     */
    open func moveTo(_ directory: URL) throws -> URL? {
        let fileManager = FileManager.default
        let fileName = file.lastPathComponent
        let destination = directory.appendingPathComponent(fileName)
        try fileManager.moveItem(at: file, to: destination)
        return destination
    }
}
