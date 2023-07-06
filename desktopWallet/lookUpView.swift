//
//  lookUpView.swift
//  desktopWallet
//
//  Created on 18/12/2022.
//

import Cocoa

class lookUpView: NSViewController {
    static var outStr = NSMutableAttributedString()

    override func viewDidLoad() {
        super.viewDidLoad()
        outView.documentView?.insertText(lookUpView.outStr)
    }
    
    @IBOutlet weak var outView: NSScrollView!
    
    @IBAction func closeAction(_ sender: Any) {
        self.view.window?.close()
    }
}
