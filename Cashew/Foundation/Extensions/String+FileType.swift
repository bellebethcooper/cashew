//
//  String+FileType.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/22/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Foundation


extension String {
    
    func isImage() -> Bool {
        let fileExtension = (self as NSString).pathExtension
        if let fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil) {
            return UTTypeConformsTo(fileUTI.takeRetainedValue(), kUTTypeImage)
        }
        return false
    }
    
    func isPDF() -> Bool {
        let fileExtension = (self as NSString).pathExtension
        if let fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil) {
            return UTTypeConformsTo(fileUTI.takeRetainedValue(), kUTTypePDF)
        }
        return false
    }
    
    func isZIP() -> Bool {
        let fileExtension = (self as NSString).pathExtension
        if let fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil) {
            return UTTypeConformsTo(fileUTI.takeRetainedValue(), kUTTypeZipArchive)
        }
        return false
    }
    
    func isGZIP() -> Bool {
        let fileExtension = (self as NSString).pathExtension
        if let fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil) {
            return UTTypeConformsTo(fileUTI.takeRetainedValue(), kUTTypeGNUZipArchive)
        }
        return false
    }
    
    func isText() -> Bool {
        let fileExtension = (self as NSString).pathExtension
        if let fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil) {
            return UTTypeConformsTo(fileUTI.takeRetainedValue(), kUTTypeText)
        }
        return false
    }
    
    func isOfficeDocument() -> Bool {
        let fileExtension = (self as NSString).pathExtension
        return fileExtension.lowercased() == "docx" || fileExtension.lowercased() == "doc" || fileExtension.lowercased() == "xlsx" || fileExtension.lowercased() == "xls" || fileExtension.lowercased() == "pptx" || fileExtension.lowercased() == "ppt"
    }

}
