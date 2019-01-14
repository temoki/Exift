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
    
    private let kFilePath: NSString = "FilePath"
    private let kDateTimeOriginal: NSString = "DateTimeOriginal"
    private var tableRowDataArray = NSMutableArray() // NSMutableArray<NSMutableDictionary<NSUserInterfaceItemIdentifier, String>>

    override func viewDidLoad() {
        super.viewDidLoad()
        fileDandDView.delegate = self
        datePicker.timeZone = TimeZone(secondsFromGMT: 0)
        timePicker.timeZone = TimeZone(secondsFromGMT: 0)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    
    // MARK: - NSTableViewDataSource

    func numberOfRows(in tableView: NSTableView) -> Int {
        return tableRowDataArray.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if let tableColumn = tableColumn {
            return (tableRowDataArray.object(at: row) as? NSDictionary)?.object(forKey: tableColumn.identifier)
        }
        return nil

    }
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        tableRowDataArray.sort(using: tableView.sortDescriptors)
        tableView.reloadData()
    }
    
    
    // MARK: NSTableViewDelegate
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        applyButton.isEnabled = tableView.selectedRowIndexes.count > 0
    }
    
    
    // MARK: - FileDragAndDropViewDelegate
    
    func filesDropped(_ filePaths: [String]) {
        tableView.deselectAll(self)
        tableRowDataArray.removeAllObjects()
        
        let fileManager = FileManager.default
        for filePath in filePaths {
            
            var isDirectory = ObjCBool(true)
            let fileExists = fileManager.fileExists(atPath: filePath, isDirectory: &isDirectory)
            if !fileExists || isDirectory.boolValue {
                continue
            }
            
            let ext = (filePath as NSString).pathExtension.lowercased()
            if !(ext == "jpg" || ext == "jpeg" || ext == "tif" || ext == "tiff") {
                continue
            }
            
            let tableRowData = NSMutableDictionary()
            tableRowData.setObject(filePath, forKey: kFilePath)
            tableRowData.setObject("", forKey: kDateTimeOriginal)
            tableRowDataArray.add(tableRowData)
        }
        
        reloadExifData()
    }
    
    
    // MARK: - Action
    
    @IBAction func applyButtonAction(_ sender: NSButton) {
        saveExifDataWithDateTime()
        //saveExifDataWithOffset()
    }
    
    @IBAction func dateCheckAction(_ sender: NSButton) {
        self.datePicker.isEnabled = (sender.state == .on)
    }
    
    @IBAction func timeCheckAction(_ sender: NSButton) {
        self.timePicker.isEnabled = (sender.state == .on)
    }
    
    // MARK: - Private
    
    private func reloadExifData() {
        for tableRowData in tableRowDataArray {
            guard let tableRowData = tableRowData as? NSMutableDictionary else {
                continue
            }
            tableRowData.setObject("", forKey: kDateTimeOriginal)
            
            guard let filePath = tableRowData.object(forKey: kFilePath) as? String else {
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
        if dateCheck.state == .on {
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = datePicker.timeZone
            dateFormatter.locale = datePicker.locale
            dateFormatter.dateFormat = "yyyy:MM:dd"
            dateStr = dateFormatter.string(from: datePicker.dateValue)
        }
        
        var timeStr: String? = nil
        if timeCheck.state == .on {
            let timeFormatter = DateFormatter()
            timeFormatter.timeZone = timePicker.timeZone
            timeFormatter.locale = timePicker.locale
            timeFormatter.dateFormat = "HH:mm:ss"
            timeStr = timeFormatter.string(from: timePicker.dateValue)
        }
        
        for rowIndex in tableView.selectedRowIndexes {
            guard let tableRowData = tableRowDataArray.object(at: rowIndex) as? NSDictionary else {
                continue
            }
            
            guard let filePath = tableRowData.object(forKey: kFilePath) as? String else {
                continue
            }
            ExifDateTimeIO.writeImageExifDateTime(filePath, dateStr: dateStr, timeStr: timeStr)
        }
        reloadExifData()
    }
    
    // TODO: 中途半端
    private func saveExifDataWithOffset() {
        let offset = timePicker.dateValue.timeIntervalSince1970

        let dateTimeFormatter = DateFormatter()
        dateTimeFormatter.timeZone = timePicker.timeZone
        dateTimeFormatter.locale = timePicker.locale
        dateTimeFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = timePicker.timeZone
        dateFormatter.locale = timePicker.locale
        dateFormatter.dateFormat = "yyyy:MM:dd"

        let timeFormatter = DateFormatter()
        timeFormatter.timeZone = timePicker.timeZone
        timeFormatter.locale = timePicker.locale
        timeFormatter.dateFormat = "HH:mm:ss"

        for rowIndex in tableView.selectedRowIndexes {
            guard let tableRowData = tableRowDataArray.object(at: rowIndex) as? NSDictionary else {
                continue
            }
            
            guard let dateTimeStr = tableRowData.object(forKey: kDateTimeOriginal) as? String else {
                continue
            }
            
            guard let dateTime = dateTimeFormatter.date(from: dateTimeStr) else {
                continue
            }
            let newDateTime = dateTime.addingTimeInterval(offset)
            let newDateStr = dateFormatter.string(from: newDateTime)
            let newTimeStr = timeFormatter.string(from: newDateTime)

            guard let filePath = tableRowData.object(forKey: kFilePath) as? String else {
                continue
            }
            ExifDateTimeIO.writeImageExifDateTime(filePath, dateStr: newDateStr, timeStr: newTimeStr)
        }
        reloadExifData()
    }

}

