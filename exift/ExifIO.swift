//
//  Created by temoki on 2015/11/01.
//  Copyright (c) 2015 temoki. All rights reserved.
//

import Cocoa

class ExifIO {
    
    class func readImageExif(filePath: String) -> NSDictionary? {
        let fileURL = NSURL(fileURLWithPath: filePath)
        
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURLRef, nil) else {
            return nil
        }
        
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as NSDictionary? else {
            return nil
        }
        
        guard let exifDictionary = properties.objectForKey(kCGImagePropertyExifDictionary) as? NSDictionary else {
            return nil
        }
        
        return exifDictionary
    }
    
    class func writeImageExif(filePath:String, exifDictionary: NSDictionary) -> Bool {
        return false
    }

}
