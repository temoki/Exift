//
//  Created by temoki on 2015/11/01.
//  Copyright (c) 2015 temoki. All rights reserved.
//

import Cocoa

protocol FileDragAndDropViewDelegate: class {
    func filesDropped(filePaths: [String])
}

class FileDragAndDropView: NSView {
    
    weak var delegate: FileDragAndDropViewDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.registerForDraggedTypes([NSFilenamesPboardType])
    }
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
    }
    
    
    // MARK: - NSDraggingDestination Protocol
    
    override func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation {
        return NSDragOperation.Copy
    }
    
    override func performDragOperation(sender: NSDraggingInfo) -> Bool {
        let pasteBoard = sender.draggingPasteboard()
        if let filePaths = pasteBoard.propertyListForType(NSFilenamesPboardType) as? [String] {
            delegate?.filesDropped(filePaths)
        }
        return true
    }
    
}
