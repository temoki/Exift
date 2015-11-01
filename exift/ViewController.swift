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
    
    struct TableRowData {
        var filePath = ""
        var dateTimeOriginal = ""
        var dateTimeDigitized = ""
    }
    private var tableRowDataArray = [TableRowData]()

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
        guard let tableColumn = tableColumn else {
            return nil
        }

        let tableRowData = tableRowDataArray[row]
        
        switch tableColumn.identifier {
        case "FilePath":
            return tableRowData.filePath
        case "DateTimeOriginal":
            return tableRowData.dateTimeOriginal
        case "DateTimeDigitized":
            return tableRowData.dateTimeDigitized
        default:
            return nil
        }
    }
    
    
    // MARK: NSTableViewDelegate
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        applyButton.enabled = tableView.selectedRowIndexes.count > 0
    }
    
    
    // MARK: - FileDragAndDropViewDelegate
    
    func filesDropped(filePaths: [String]) {
        tableRowDataArray.removeAll()
        
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
            
            var tableRowData = TableRowData()
            tableRowData.filePath = filePath
            tableRowDataArray.append(tableRowData)
        }
        
        self.reloadExifData()
        self.tableView.reloadData()
    }
    
    
    // MARK: - Action
    
    @IBAction func applyButtonAction(sender: NSButton) {
        NSLog("applyButtonAction")
    }
    
    
    // MARK: - Private
    
    func reloadExifData() {
        for var i = 0; i < tableRowDataArray.count; i++ {
            guard let exifDict = ExifIO.readImageExif(tableRowDataArray[i].filePath) else {
                continue
            }
            
            if let dateTimeOriginal = exifDict[kCGImagePropertyExifDateTimeOriginal as String] as? String {
                tableRowDataArray[i].dateTimeOriginal = dateTimeOriginal
            }
            
            if let dateTimeDigitized = exifDict[kCGImagePropertyExifDateTimeDigitized as String] as? String {
                tableRowDataArray[i].dateTimeDigitized = dateTimeDigitized
            }
        }
    }

}

