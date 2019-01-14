//
//  Created by temoki on 2015/11/01.
//  Copyright (c) 2015 temoki. All rights reserved.
//

import Cocoa

class ExifDateTimeIO {
    
    class func readImageExifDateTime(_ filePath: String) -> String? {
        let fileURL = NSURL(fileURLWithPath: filePath)
        
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else {
            return nil
        }
        
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as NSDictionary? else {
            return nil
        }
        
        guard let exifDictionary = properties.object(forKey: kCGImagePropertyExifDictionary) as? NSDictionary else {
            return nil
        }
        
        return exifDictionary.object(forKey: kCGImagePropertyExifDateTimeOriginal) as? String
    }
    
    @discardableResult
    class func writeImageExifDateTime(_ filePath: String, dateStr: String?, timeStr: String?) -> Bool {
        let fileURL = NSURL(fileURLWithPath: filePath)
        
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else {
            return false
        }
        
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as NSDictionary? else {
            return false
        }
        
        guard let exifDictionary = properties.object(forKey: kCGImagePropertyExifDictionary) as? NSDictionary else {
            return false
        }
        
        guard let dateTimeStr = exifDictionary.object(forKey: kCGImagePropertyExifDateTimeOriginal) as? String else {
            return false
        }
        
        let dateTimeStrArray = dateTimeStr.components(separatedBy: " ")
        guard dateTimeStrArray.count == 2 else {
            return false
        }
        let orgDateStr = dateTimeStrArray[0]
        let orgTimeStr = dateTimeStrArray[1]
        
        var dstDateTimeStr = dateStr ?? orgDateStr
        dstDateTimeStr += " "
        dstDateTimeStr += timeStr ?? orgTimeStr
        exifDictionary.setValue(dstDateTimeStr, forKey: kCGImagePropertyExifDateTimeOriginal as String)
        exifDictionary.setValue(dstDateTimeStr, forKey: kCGImagePropertyExifDateTimeDigitized as String)
        
        guard let sourceType = CGImageSourceGetType(source) else {
            return false
        }
        
        let imageData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(imageData, sourceType, 1, nil) else {
            return false
        }

        CGImageDestinationAddImageFromSource(destination, source, 0, exifDictionary)
        CGImageDestinationFinalize(destination)
        return imageData.write(toFile: filePath, atomically: true)
    }

}
