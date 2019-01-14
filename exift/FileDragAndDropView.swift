//
//  Created by temoki on 2015/11/01.
//  Copyright (c) 2015 temoki. All rights reserved.
//

import Cocoa

protocol FileDragAndDropViewDelegate: class {
    func filesDropped(_ filePaths: [String])
}

class FileDragAndDropView: NSView {
    
    weak var delegate: FileDragAndDropViewDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.registerForDraggedTypes([pasteBoardType])
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    
    // MARK: - NSDraggingDestination Protocol
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return NSDragOperation.copy
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteBoard = sender.draggingPasteboard
        if let filePaths = pasteBoard.propertyList(forType: pasteBoardType) as? [String] {
            delegate?.filesDropped(filePaths)
        }
        return true
    }
    
    // MARK: - Private
    
    //private let pasteBoardType = NSPasteboard.PasteboardType.fileURL
    //↑これだと動作しないのでワークアラウンド
    private let pasteBoardType = NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")

}
