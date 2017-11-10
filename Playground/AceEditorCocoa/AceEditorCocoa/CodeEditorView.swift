//
//  CodeEditorView.swift
//  AceEditorCocoa
//
//  Created by Hicham Bouabdallah on 7/23/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa
import WebKit

@objc(SRCodeEditorView)
class CodeEditorView: NSView {
    
    private let webView = WebView()
    
    
    private func setup() {
        
        addSubview(webView)
//        webView.translatesAutoresizingMaskIntoConstraints = false
//        webView.leftAnchor.constraintEqualToAnchor(leftAnchor).active = true
//        webView.rightAnchor.constraintEqualToAnchor(rightAnchor).active = true
//        webView.topAnchor.constraintEqualToAnchor(topAnchor).active = true
//        webView.bottomAnchor.constraintEqualToAnchor(bottomAnchor).active = true
        webView.policyDelegate = self
        webView.frameLoadDelegate = self
        
//        if let context = webView.valueForKeyPath("documentView.webView.mainFrame.javaScriptContext") as? JSContext {
//
//        }
//        
        guard let editorHtmlPath = NSBundle.mainBundle().pathForResource("editor", ofType: "html") else { fatalError() }
        do {
            let editorHtmlContent = try NSString(contentsOfFile: editorHtmlPath, encoding: NSUTF8StringEncoding)
            let baseURL = NSBundle.mainBundle().bundleURL.URLByAppendingPathComponent("Contents").URLByAppendingPathComponent("Resources").URLByAppendingPathComponent("ace")
            NSLog("baseURL -> \(baseURL) \n \(editorHtmlContent)")
            webView.mainFrame .loadHTMLString(editorHtmlContent as String, baseURL: baseURL)
        } catch {
            NSLog("CodeEditorView.error \(error)")
        }
        
//self.webView.mainFrame.loadHTMLString("hello", baseURL: NSURL(string: "http://cnn.com"))
        //[self.webView.mainFrame loadHTMLString:styledHTML baseURL:nil];
        //self.webView.drawsBackground = false;
        
//        guard let editorHtmlPath = NSBundle.mainBundle().pathForResource("editor", ofType: "html"), editorURL = NSURL(string: editorHtmlPath) else { fatalError() }
//
//        let request = NSURLRequest(URL: editorURL)
//        webView.mainFrame.loadRequest(request)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.wantsLayer = true
        self.layer?.borderWidth = 1
        self.layer?.borderColor = NSColor.greenColor().CGColor
        
        setup()
    }
    
    
    override func layout() {
        webView.frame = self.bounds
        super.layout()
    }
}

extension CodeEditorView: WebPolicyDelegate {
//    func webView(webView: WebView!, decidePolicyForNavigationAction actionInformation: [NSObject : AnyObject]!, request: NSURLRequest!, frame: WebFrame!, decisionListener listener: WebPolicyDecisionListener!) {
//        
//        if let url = request.URL {
//            NSWorkspace.sharedWorkspace().openURL(url)
//        } else {
//            listener.use()
//        }
//    }
}


extension CodeEditorView: WebFrameLoadDelegate {
    func webView(webView: WebView!, didCreateJavaScriptContext context: JSContext!, forFrame frame: WebFrame!) {
        context.exceptionHandler =  { (context, value) in
            NSLog("web error: \(value)")
        }
    }
}
//
//extension CodeEditorView: WKUIDelegate {
//    
//}