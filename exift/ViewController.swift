//
//  Created by temoki on 2015/11/01.
//  Copyright (c) 2015 temoki. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSComboBoxDelegate, FileDragAndDropViewDelegate {
    
    @IBOutlet private var actionComboBox: NSComboBox!
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
        dateTimePicker.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        actionComboBox.setDelegate(self)
        actionComboBox.selectItemAtIndex(0)
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
    
    
    // MARK: NSComboBoxDelegate
    
    func comboBoxSelectionDidChange(notification: NSNotification) {
        dateTimePicker.dateValue = NSDate(timeIntervalSince1970: 0)
        switch actionComboBox.indexOfSelectedItem {
        case 0:
            dateTimePicker.datePickerElements =
                [NSDatePickerElementFlags.YearMonthDayDatePickerElementFlag,
                NSDatePickerElementFlags.HourMinuteSecondDatePickerElementFlag]
            break
        case 1:
            dateTimePicker.datePickerElements =
                [NSDatePickerElementFlags.HourMinuteSecondDatePickerElementFlag]
            break
        default:
            break
        }
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
        switch actionComboBox.indexOfSelectedItem {
        case 0:
            saveExifDataWithDateTime()
            break
        case 1:
            saveExifDataWithOffset()
            break
        default:
            break
        }
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
    
    private func saveExifDataWithDateTime() {
        let formatter = NSDateFormatter()
        formatter.timeZone = dateTimePicker.timeZone
        formatter.locale = dateTimePicker.locale
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        let dateTimeStr = formatter.stringFromDate(dateTimePicker.dateValue)
        for rowIndex in tableView.selectedRowIndexes {
            guard let tableRowData = tableRowDataArray.objectAtIndex(rowIndex) as? NSDictionary else {
                continue
            }
            
            guard let filePath = tableRowData.objectForKey(kFilePath) as? String else {
                continue
            }
            ExifDateTimeIO.writeImageExifDateTime(filePath,
                dateTimeOriginal: dateTimeStr, dateTimeDigitized: dateTimeStr)
        }
        reloadExifData()
    }
    
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
    }

}

