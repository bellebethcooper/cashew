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

        webView.drawsBackground = false
        webView.policyDelegate = self
        webView.frameLoadDelegate = self
        code = ""
    }
    
    private var _code: String = ""
    var code: String {
        set(newValue) {
            if _code == newValue {
                return
            }
            _code = newValue
            guard let editorHtmlPath = NSBundle.mainBundle().pathForResource("editor", ofType: "html") else { fatalError() }
            do {
                let editorHtmlContent = try NSString(contentsOfFile: editorHtmlPath, encoding: NSUTF8StringEncoding).stringByReplacingOccurrencesOfString("__SOURCECODE__", withString: _code)
                let baseURL = NSBundle.mainBundle().bundleURL.URLByAppendingPathComponent("Contents")!.URLByAppendingPathComponent("Resources")!.URLByAppendingPathComponent("ace")
                
                webView.mainFrame.loadHTMLString(editorHtmlContent as String, baseURL: baseURL)
            } catch {
                DDLogDebug("CodeEditorView.error \(error)")
            }
        }
        
        get {
            return _code
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.wantsLayer = true
//        self.layer?.borderWidth = 1
//        self.layer?.borderColor = NSColor.greenColor().CGColor
        
        setup()
    }
    
    
    override func layout() {
        webView.frame = self.bounds
        super.layout()
    }
    
    override class func isSelectorExcludedFromWebScript(selector: Selector) -> Bool {
        if NSStringFromSelector(selector) == "aceTextDidChange:" {
            return false
        }
        return super.isSelectorExcludedFromWebScript(selector)
    }
    
    override class func webScriptNameForSelector(selector: Selector) -> String {
        if NSStringFromSelector(selector) == "aceTextDidChange:" {
            return "aceTextDidChange"
        }
        return super.webScriptNameForSelector(selector)
    }
    
    @objc
    func aceTextDidChange(text: String) {
        //DDLogDebug("text did change \(text)")
        _code = text
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
            DDLogDebug("web error: \(value)")
        }
    }
    
    func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!) {
        webView.windowScriptObject.callWebScriptMethod("updateEditorValue", withArguments: [_code])
        webView.windowScriptObject.setValue(self, forKey: "ACEView")
    }
}
