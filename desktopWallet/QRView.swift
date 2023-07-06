//
//  QRView.swift
//  desktopWallet
//
//  Created on 25/11/2022.
//

import Cocoa

class QRView: NSViewController {
    static var QRImage: NSImage?
    static var account = ""
    static var token = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        let outImage = QRView.QRImage
        imageView.image = outImage
    }
    
    @IBAction func saveQRCode(_ sender: Any) {
        let qr_file_name = "myDesktopWalletQR\(QRView.account)\(QRView.token).png"
        let dialog = NSOpenPanel();
        dialog.title                   = "Choose where to save QR code";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseFiles = false;
        dialog.canChooseDirectories = true;
        var path = ""
        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            let result = dialog.url
            if (result != nil) {
                path = result!.path
            }
            let directory = NSURL(fileURLWithPath: path)
            let fileurl =  directory.appendingPathComponent(qr_file_name)
            if ((QRView.QRImage?.pngWrite(to: fileurl!)) != nil) { print("saved") }
        }
    }
    
    @IBOutlet weak var imageView: NSImageView!
}

extension NSImage {
    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }
    func pngWrite(to url: URL, options: Data.WritingOptions = .atomic) -> Bool {
        do {
            try pngData?.write(to: url, options: options)
            return true
        } catch {
            print(error)
            return false
        }
    }
}
