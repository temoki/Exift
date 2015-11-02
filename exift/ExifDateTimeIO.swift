//
//  Created by temoki on 2015/11/01.
//  Copyright (c) 2015 temoki. All rights reserved.
//

import Cocoa

class ExifDateTimeIO {
    
    class func readImageExifDateTime(filePath: String) -> (String, String)? {
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
        
        var dateTimePair = ("", "")
        if let dateTimeOriginal = exifDictionary.objectForKey(kCGImagePropertyExifDateTimeOriginal) as? String {
            dateTimePair.0 = dateTimeOriginal
        }
        if let dateTimeDigitized = exifDictionary.objectForKey(kCGImagePropertyExifDateTimeDigitized) as? String {
            dateTimePair.1 = dateTimeDigitized
        }
        
        return dateTimePair
    }
    
    class func writeImageExifDateTime(filePath:String, dateTimeOriginal: String, dateTimeDigitized: String) -> Bool {
        let fileURL = NSURL(fileURLWithPath: filePath)
        
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURLRef, nil) else {
            return false
        }
        
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as NSDictionary? else {
            return false
        }
        
        guard let exifDictionary = properties.objectForKey(kCGImagePropertyExifDictionary) as? NSDictionary else {
            return false
        }
        
        exifDictionary.setValue(dateTimeOriginal, forKey: kCGImagePropertyExifDateTimeOriginal as String)
        exifDictionary.setValue(dateTimeDigitized, forKey: kCGImagePropertyExifDateTimeDigitized as String)
        
        guard let sourceType = CGImageSourceGetType(source) else {
            return false
        }
        
        let imageData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(imageData, sourceType, 1, nil) else {
            return false
        }

        CGImageDestinationAddImageFromSource(destination, source, 0, exifDictionary)
        CGImageDestinationFinalize(destination)
        return imageData.writeToFile(filePath, atomically: true)
    }

}
