//
//  Created by temoki on 2015/11/01.
//  Copyright (c) 2015 temoki. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSComboBoxDelegate, FileDragAndDropViewDelegate {
    
    @IBOutlet private var dateCheck: NSButton!
    @IBOutlet private var timeCheck: NSButton!
    @IBOutlet private var datePicker: NSDatePicker!
    @IBOutlet private var timePicker: NSDatePicker!
    @IBOutlet private var applyButton: NSButton!
    @IBOutlet private var fileDandDView: FileDragAndDropView!
    @IBOutlet private var tableView: NSTableView!
    
    private let kFilePath = "FilePath"
    private let kDateTimeOriginal = "DateTimeOriginal"
    private var tableRowDataArray = NSMutableArray() // NSMutableArray<NSMutableDictionary<String, String>>

    override func viewDidLoad() {
        super.viewDidLoad()
        fileDandDView.delegate = self
        datePicker.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        timePicker.timeZone = NSTimeZone(forSecondsFromGMT: 0)
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
            tableRowDataArray.addObject(tableRowData)
        }
        
        reloadExifData()
    }
    
    
    // MARK: - Action
    
    @IBAction func applyButtonAction(sender: NSButton) {
        saveExifDataWithDateTime()
    }
    
    @IBAction func dateCheckAction(sender: NSButton) {
        self.datePicker.enabled = (sender.state == NSOnState)
    }
    
    @IBAction func timeCheckAction(sender: NSButton) {
        self.timePicker.enabled = (sender.state == NSOnState)
    }
    
    // MARK: - Private
    
    private func reloadExifData() {
        for tableRowData in tableRowDataArray {
            tableRowData.setObject("", forKey: kDateTimeOriginal)
            
            guard let filePath = tableRowData.objectForKey(kFilePath) as? String else {
                continue
            }
            
            guard let exifDateTime = ExifDateTimeIO.readImageExifDateTime(filePath) else {
                continue
            }
            
            tableRowData.setObject(exifDateTime, forKey: kDateTimeOriginal)
        }
        tableView.reloadData()
    }
    
    private func saveExifDataWithDateTime() {
        var dateStr: String? = nil
        if dateCheck.state == NSOnState {
            let dateFormatter = NSDateFormatter()
            dateFormatter.timeZone = datePicker.timeZone
            dateFormatter.locale = datePicker.locale
            dateFormatter.dateFormat = "yyyy:MM:dd"
            dateStr = dateFormatter.stringFromDate(datePicker.dateValue)
        }
        
        var timeStr: String? = nil
        if timeCheck.state == NSOnState {
            let timeFormatter = NSDateFormatter()
            timeFormatter.timeZone = timePicker.timeZone
            timeFormatter.locale = timePicker.locale
            timeFormatter.dateFormat = "HH:mm:ss"
            timeStr = timeFormatter.stringFromDate(timePicker.dateValue)
        }
        
        for rowIndex in tableView.selectedRowIndexes {
            guard let tableRowData = tableRowDataArray.objectAtIndex(rowIndex) as? NSDictionary else {
                continue
            }
            
            guard let filePath = tableRowData.objectForKey(kFilePath) as? String else {
                continue
            }
            ExifDateTimeIO.writeImageExifDateTime(filePath, dateStr: dateStr, timeStr: timeStr)
        }
        reloadExifData()
    }
    
    /*
    private func saveExifDataWithOffset() {
        let offset = dateTimePicker.dateValue.timeIntervalSince1970
        let formatter = NSDateFormatter()
        formatter.timeZone = dateTimePicker.timeZone
        formatter.locale = dateTimePicker.locale
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        for rowIndex in tableView.selectedRowIndexes {
            guard let tableRowData = tableRowDataArray.objectAtIndex(rowIndex) as? NSDictionary else {
                continue
            }
            
            guard let dateTimeStr = tableRowData.objectForKey(kDateTimeOriginal) as? String else {
                continue
            }
            
            guard let dateTime = formatter.dateFromString(dateTimeStr) else {
                continue
            }
            let newDateTime = dateTime.dateByAddingTimeInterval(offset)
            let newDateTimeStr = formatter.stringFromDate(newDateTime)
            
            guard let filePath = tableRowData.objectForKey(kFilePath) as? String else {
                continue
            }
            ExifDateTimeIO.writeImageExifDateTime(filePath,
                dateTimeOriginal: newDateTimeStr, dateTimeDigitized: newDateTimeStr)
        }
        reloadExifData()
    }*/

}

