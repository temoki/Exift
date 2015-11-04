//
//  Created by temoki on 2015/11/01.
//  Copyright (c) 2015 temoki. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, FileDragAndDropViewDelegate {
    
    @IBOutlet private var dateTimePicker: NSDatePicker!
    @IBOutlet private var applyButton: NSButton!
    @IBOutlet private var fileDandDView: FileDragAndDropView!
    @IBOutlet private var tableView: NSTableView!
    
    private let kFilePath = "FilePath"
    private let kDateTimeOriginal = "DateTimeOriginal"
    private let kDateTimeDigitized = "DateTimeDigitized"
    private var tableRowDataArray = NSMutableArray() // NSMutableArray<NSMutableDictionary<String, String>>

    override func viewDidLoad() {
        super.viewDidLoad()
        fileDandDView.delegate = self
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    
    // MARK: - NSTableViewDataSource

    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return tableRowDataArray.count
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        if let tableColumn = tableColumn {
            return tableRowDataArray.objectAtIndex(row).objectForKey(tableColumn.identifier)
        }
        return nil

    }
    
    func tableView(tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        tableRowDataArray.sortUsingDescriptors(tableView.sortDescriptors)
        tableView.reloadData()
    }
    
    
    // MARK: NSTableViewDelegate
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        applyButton.enabled = tableView.selectedRowIndexes.count > 0
    }
    
    
    // MARK: - FileDragAndDropViewDelegate
    
    func filesDropped(filePaths: [String]) {
        tableView.deselectAll(self)
        tableRowDataArray.removeAllObjects()
        
        let fileManager = NSFileManager.defaultManager()
        for filePath in filePaths {
            
            var isDirectory = ObjCBool(true)
            let fileExists = fileManager.fileExistsAtPath(filePath, isDirectory: &isDirectory)
            if !fileExists || isDirectory.boolValue {
                continue
            }
            
            let ext = (filePath as NSString).pathExtension.lowercaseString
            if !(ext == "jpg" || ext == "jpeg" || ext == "tif" || ext == "tiff") {
                continue
            }
            
            let tableRowData = NSMutableDictionary()
            tableRowData.setObject(filePath, forKey: kFilePath)
            tableRowData.setObject("", forKey: kDateTimeOriginal)
            tableRowData.setObject("", forKey: kDateTimeDigitized)
            tableRowDataArray.addObject(tableRowData)
        }
        
        reloadExifData()
    }
    
    
    // MARK: - Action
    
    @IBAction func applyButtonAction(sender: NSButton) {
        saveExifData()
    }
    
    
    // MARK: - Private
    
    private func reloadExifData() {
        for tableRowData in tableRowDataArray {
            tableRowData.setObject("", forKey: kDateTimeOriginal)
            tableRowData.setObject("", forKey: kDateTimeDigitized)
            
            guard let filePath = tableRowData.objectForKey(kFilePath) as? String else {
                continue
            }
            
            guard let exifDateTime = ExifDateTimeIO.readImageExifDateTime(filePath) else {
                continue
            }
            
            tableRowData.setObject(exifDateTime.0, forKey: kDateTimeOriginal)
            tableRowData.setObject(exifDateTime.1, forKey: kDateTimeDigitized)
        }
        tableView.reloadData()
    }
    
    private func saveExifData() {
        let formatter = NSDateFormatter()
        formatter.locale = dateTimePicker.locale
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        let dateTime = formatter.stringFromDate(dateTimePicker.dateValue)
        for rowIndex in tableView.selectedRowIndexes {
            guard let tableRowData = tableRowDataArray.objectAtIndex(rowIndex) as? NSDictionary else {
                continue
            }
            
            guard let filePath = tableRowData.objectForKey(kFilePath) as? String else {
                continue
            }
            ExifDateTimeIO.writeImageExifDateTime(filePath,
                dateTimeOriginal: dateTime, dateTimeDigitized: dateTime)
        }
        reloadExifData()
    }

}

