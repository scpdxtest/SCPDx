//
//  ViewController.swift
//  desktopWallet
//
//  Created on 08/11/2022.
//

import Cocoa
import EosioSwiftVault
import EosioSwift
import LocalAuthentication

class ViewController: NSViewController {
    var accountViewData = [["acc":""]]
    var tokenViewData = [["token":"", "ammount":""]]
    
    var accArr = [""]
    var accMeta = [Dictionary<String,Any>]()
    
    var vcc = NSViewController()

    func getWalletKeys() -> String {
        let id = Bundle.bundleIDFor(appNamed: "desktopWallet.app")
        let vault = EosioVault(accessGroup: "XXXXXXXXXXX." + id!)


        accArr.removeAll()
        accMeta.removeAll()
        let keys = try? vault.getAllVaultKeys()
        if keys != nil && keys!.count > 0 {
            accountViewData.removeAll()
            for k in keys! {
                if k.accessGroup == "XXXXXXXXXXX." + id! {
                    var md = try? vault.getKeyMetadata(eosioPublicKey: k.eosioPublicKey)
                    if k.label != nil || md?["label"] != nil {
                        var acc = ""
                        if k.label != nil {
                            accountViewData.append(["acc":k.label!])
                            acc = k.label!
                        } else {
                            accountViewData.append(["acc":md?["label"] as! String])
                            acc = md?["label"] as! String
                        }
                        md!["label"] = acc
                        accArr.append(acc)
                        accMeta.append(md!)
                        
                    } else {
                        print("trace nil", k.label, k.eosioPrivateKey, k.eosioPublicKey, try? vault.getKeyMetadata(eosioPublicKey: k.eosioPublicKey))
                    }
                }
            }
        }
        accTableView.reloadData()
        return("")
    }
    
    @IBAction func refreshAccounts(_ sender: Any) {
        let id = Bundle.bundleIDFor(appNamed: "desktopWallet.app")
        let vault = EosioVault(accessGroup: "XXXXXXXXXXX." + id!)
        accArr.removeAll()
        accMeta.removeAll()
        let keys = try? vault.getAllVaultKeys()
        if keys != nil && keys!.count > 0 {
            accountViewData.removeAll()
            for k in keys! {
                if k.accessGroup == "XXXXXXXXXXX." + id! {
                    var md = try? vault.getKeyMetadata(eosioPublicKey: k.eosioPublicKey)
                    if k.label != nil || md?["label"] != nil {
                        var acc = ""
                        if k.label != nil {
                            accountViewData.append(["acc":k.label!])
                            acc = k.label!
                        } else {
                            accountViewData.append(["acc":md?["label"] as! String])
                            acc = md?["label"] as! String
                        }
                        md!["label"] = acc
                        accArr.append(acc)
                        accMeta.append(md!)
                    } else {
                    }
                }
            }
        }
        accTableView.reloadData()
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            var context = LAContext()
            var error: NSError?
            
// Check for biometric authentication permissions
            var permissions = context.canEvaluatePolicy(
                .deviceOwnerAuthentication,
                error: &error
            )
                
            if permissions {
// Proceed to authentication
                print("ok")
            }
            else {
// Handle permission denied or error
                mylib.errorDialog(question: "Permission error -> " + (error?.localizedFailureReason ?? "There is no user authentication method available!\nIn order the application is working, there must be at least one user authentication method available, i.e., login password, biometry, apple watch etc.!"))
                NSApplication.shared.terminate(self)
            }
            
            tokenViewData.removeAll()
            accountViewData.removeAll()
            accTableView.delegate = self
            accTableView.dataSource = self
            accTableView.sizeLastColumnToFit()
            tokenTableView.delegate = self
            tokenTableView.dataSource = self
            tokenTableView.sizeLastColumnToFit()
            
            getWalletKeys()
            NotificationCenter.default.addObserver(self, selector: #selector(reloadAccount), name: NSNotification.Name(rawValue: "accReload"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(reloadAllData), name: NSNotification.Name(rawValue: "allReload"), object: nil)
        }
    }

    @IBAction func addExternalAccount(_ sender: Any) {
        let a = NSAlert()
        a.messageText = "Add external account"
        a.addButton(withTitle: "Confirm")
        a.addButton(withTitle: "Cancel")
// account
        let label1 = NSTextField(frame: NSRect(x: 0, y: 20, width: 150, height: 20))
        label1.font = NSFont(name: "Calibri-Bold", size: 16)
        label1.isEnabled = false
        label1.isBordered = false
        label1.alignment = .center
        label1.drawsBackground = false
        label1.stringValue = "Account"
        let acc = NSTextField(frame: NSRect(x: 0, y: 0, width: 150, height: 22))
        acc.font = NSFont(name: "Calibri", size: 16)
        acc.isEnabled = true
        acc.isBordered = true
        acc.alignment = .left
        acc.drawsBackground = false
        acc.placeholderString = "Account name"
// private key
        let label2 = NSTextField(frame: NSRect(x: 160, y: 20, width: 480, height: 20))
        label2.font = NSFont(name: "Calibri-Bold", size: 16)
        label2.isEnabled = false
        label2.isBordered = false
        label2.alignment = .center
        label2.drawsBackground = false
        label2.stringValue = "Private key"
        let pass = NSTextField(frame: NSRect(x: 160, y: 0, width: 480, height: 22))
        pass.font = NSFont(name: "Calibri", size: 16)
        pass.isEnabled = true
        pass.isBordered = true
        pass.alignment = .left
        pass.drawsBackground = false
        pass.placeholderString = "private key"
// public key
        let label4 = NSTextField(frame: NSRect(x: 160, y: 60, width: 480, height: 20))
        label4.font = NSFont(name: "Calibri-Bold", size: 16)
        label4.isEnabled = false
        label4.isBordered = false
        label4.alignment = .center
        label4.drawsBackground = false
        label4.stringValue = "Private key"
        let pub = NSTextField(frame: NSRect(x: 160, y: 40, width: 480, height: 22))
        pub.font = NSFont(name: "Calibri", size: 16)
        pub.isEnabled = true
        pub.isBordered = true
        pub.alignment = .left
        pub.drawsBackground = false
        pub.placeholderString = "Public key"
// endpoint
        let label3 = NSTextField(frame: NSRect(x: 650, y: 20, width: 350, height: 20))
        label3.font = NSFont(name: "Calibri-Bold", size: 16)
        label3.isEnabled = false
        label3.isBordered = false
        label3.alignment = .center
        label3.drawsBackground = false
        label3.stringValue = "endpoint"
        let mail = NSTextField(frame: NSRect(x: 650, y: 0, width: 350, height: 22))
        mail.font = NSFont(name: "Calibri", size: 16)
        mail.isEnabled = true
        mail.isBordered = true
        mail.alignment = .left
        mail.drawsBackground = false
        mail.placeholderString = "eosio endpoint"

        let stackViewer = NSStackView(frame: NSRect(x: 0, y: 0, width: 1100, height: 80))
        stackViewer.addSubview(acc)
        stackViewer.addSubview(label1)
        stackViewer.addSubview(pass)
        stackViewer.addSubview(label2)
        stackViewer.addSubview(mail)
        stackViewer.addSubview(label3)
        stackViewer.addSubview(pub)
        stackViewer.addSubview(label4)
        a.accessoryView = stackViewer
        
        let response: NSApplication.ModalResponse = a.runModal()

        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            let user_account = acc.stringValue
            let user_mail = mail.stringValue
            let user_pass = pass.stringValue
            _ = pub.stringValue
            
            do {
                _ = try EosioName(user_account)
                if user_account == "" || user_mail == "" || user_pass == "" || !user_mail.isValidURL { mylib.errorDialog(question: "Wrong user's parameters!")
                } else {
                    Task {
                        let res = try? await myEOSIOlib.isValidEOSIOUrl(endpoint: URL(string: user_mail)!)
                        if res!.0 {
                            let id = Bundle.bundleIDFor(appNamed: "desktopWallet.app")
                            let vault = EosioVault(accessGroup: "XXXXXXXXXXX." + id!)
                            
                            do {
                                let md = ["path":user_mail, "label":user_account]
                                let newKey = try vault.addExternal(eosioPrivateKey: user_pass, protection: .whenUnlocked, bioFactor: .flex, metadata: md)
                                
                                print("new key", newKey.eosioPrivateKey, newKey.eosioPublicKey, newKey.privateSecKey.debugDescription, newKey.label, newKey.metadata)
                                print("Eosio add external user creation!")
                                accMeta.append(md)
                                accountViewData.append(["acc":user_account])
                                accTableView.reloadData()
                            } catch (let err) {
                                print("error adding external keys!", err, err.eosioError, err.localizedDescription)
                                mylib.errorDialog(question: "Error adding external keys! \(err.localizedDescription)")
                            }
                        } else {
                            mylib.errorDialog(question: "Invalid EOSIO blockchain url!")
                        }
                    }
                }
            } catch {
                mylib.errorDialog(question: "Wrong EOSIO account name!")
            }
        }
    }
    
    @objc func reloadAccount() {
        let md = accMeta[ViewController.selectedAccount]
        print("acc sel reload", md)
        let md_arr = md.keys
        tokenViewData.removeAll()
        Task {
            for m in md_arr {
                if m != "path" && m != "label" {
                    let b = try await myEOSIOlib.getBallance(account: md["label"] as! String, currency: md[m] as! String, endpoint: URL(string: md["path"] as! String)!)
                    tokenViewData.append(["token":md[m] as! String, "amount":b.1])
                }
            }
            tokenTableView.reloadData()
        }
    }

    @objc func reloadAllData() {
        refreshAccounts(self)
    }

    @IBAction func accSelect (_ Sender:Any) {
        let sel = accTableView.selectedRow
        if sel >= 0 && accMeta.count > 0 {
            let md = accMeta[sel]
            print("acc sel", md)
            let pubKey = readPUBKey(account_name: accountViewData[sel]["acc"]!)
            print("pubkey", pubKey, accMeta[sel])
            infoLabel.stringValue = md["path"] as! String
            let md_arr = md.keys
            tokenViewData.removeAll()
            Task {
                for m in md_arr {
                    if m != "path" && m != "label" {
                        let b = try await myEOSIOlib.getBallance(account: md["label"] as! String, currency: md[m] as! String, endpoint: URL(string: md["path"] as! String)!)
                        tokenViewData.append(["token":md[m] as! String, "amount":b.1])
                    }
                }
                tokenTableView.reloadData()
            }
        }
    }
    
    @IBAction func addCurrencies(_ sender: Any) {
        if accountViewData.count > 0 {
            let sel = accTableView.selectedRow
            if sel >= 0 {
                let acc_name = accountViewData[sel]["acc"]
                var md = accMeta[sel]
                let a = NSAlert()
                a.messageText = "Add new token symbol"
                a.addButton(withTitle: "Confirm")
                a.addButton(withTitle: "Cancel")
// token
                let label1 = NSTextField(frame: NSRect(x: 0, y: 20, width: 100, height: 20))
                label1.font = NSFont(name: "Calibri-Bold", size: 16)
                label1.isEnabled = false
                label1.isBordered = false
                label1.alignment = .center
                label1.drawsBackground = false
                label1.stringValue = "Token"
                let acc = NSTextField(frame: NSRect(x: 0, y: 0, width: 100, height: 22))
                acc.font = NSFont(name: "Calibri", size: 16)
                acc.isEnabled = true
                acc.isBordered = true
                acc.alignment = .left
                acc.drawsBackground = false
                acc.placeholderString = "Symbol"
                
                let stackViewer = NSStackView(frame: NSRect(x: 0, y: 0, width: 200, height: 80))
                stackViewer.addSubview(acc)
                stackViewer.addSubview(label1)
                a.accessoryView = stackViewer
                
                let response: NSApplication.ModalResponse = a.runModal()
                
                if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                    let user_token = acc.stringValue.uppercased()
                    
                    if user_token == "" || user_token.count > 7 { mylib.errorDialog(question: "Wrong token's parameters!")
                    } else {
// add new token symbol
                        let id = Bundle.bundleIDFor(appNamed: "desktopWallet.app")
                        let vault = EosioVault(accessGroup: "XXXXXXXXXXX." + id!)
                        md[user_token] = user_token
                        let keys = try? vault.getAllVaultKeys()
                        var pk = ""
                        if keys != nil && keys!.count > 0 {
                            for k in keys! {
                                if k.accessGroup == "XXXXXXXXXXX." + id! {
                                    let md1 = try? vault.getKeyMetadata(eosioPublicKey: k.eosioPublicKey)
                                    if md1!["label"] as! String == acc_name {
                                        pk = k.eosioPublicKey
                                        break
                                    }
                                }
                            }
                            try vault.saveKeyMetadata(eosioPublicKey: pk, dictionary: md)
                            Task {
                                let b = try await myEOSIOlib.getBallance(account: acc_name!, currency: user_token, endpoint: URL(string: md["path"] as! String)!)
                                accMeta[sel] = md
                                tokenViewData.append(["token":user_token, "amount":b.1])
                                tokenTableView.reloadData()
                            }
                        }
                    }
                }
            } else {
                mylib.errorDialog(question: "There is no account selected!")
            }
        } else {
            mylib.errorDialog(question: "There are no accounts added!")
        }
    }
    
    @IBAction func deleteCurencies(_ sender: Any) {
        let sel = accTableView.selectedRow
        let sel1 = tokenTableView.selectedRow
        if sel >= 0 && sel1 >= 0 {
            let acc_name = accountViewData[sel]["acc"]
            var md = accMeta[sel]
            let token = tokenViewData[sel1]["token"]!
            md.removeValue(forKey: token)
// delete token symbol
            let id = Bundle.bundleIDFor(appNamed: "desktopWallet.app")
            let vault = EosioVault(accessGroup: "XXXXXXXXXXX." + id!)

            let keys = try? vault.getAllVaultKeys()
            var pk = ""
            if keys != nil && keys!.count > 0 {
                for k in keys! {
                    if k.accessGroup == "XXXXXXXXXXX." + id! {
                        let md1 = try? vault.getKeyMetadata(eosioPublicKey: k.eosioPublicKey)
                        if md1!["label"] as! String == acc_name {
                            pk = k.eosioPublicKey
                            break
                        }
                    }
                }
                try vault.saveKeyMetadata(eosioPublicKey: pk, dictionary: md)
                tokenViewData.remove(at: sel1)
                accMeta[sel] = md
                tokenTableView.reloadData()
            }
        }
    }
    
    @IBAction func removeAccount(_ sender: Any) {
        let sel = accTableView.selectedRow
        if sel >= 0 {
            let md = accMeta[sel]
            let acc_name = md["label"]
            let id = Bundle.bundleIDFor(appNamed: "desktopWallet.app")
            let vault = EosioVault(accessGroup: "XXXXXXXXXXX." + id!)

            let keys = try? vault.getAllVaultKeys()
            var pk = ""
            if keys != nil && keys!.count > 0 {
                for k in keys! {
                    if k.accessGroup == "XXXXXXXXXXX." + id! {
                        let md1 = try? vault.getKeyMetadata(eosioPublicKey: k.eosioPublicKey)
                        if md1!["label"] as! String == acc_name as! String {
                            pk = k.eosioPublicKey
                            break
                        }
                    }
                }
                try? vault.deleteKey(eosioPublicKey: pk)
                tokenViewData.removeAll()
                accMeta.remove(at: sel)
                accountViewData.remove(at: sel)
                tokenTableView.reloadData()
                accTableView.reloadData()
            }
        }
    }
    
    func getTokenPrecision(token: String) -> Int {
        let first_parse = token.split(separator: " ")
        if first_parse.count >= 1 {
            let second_parse = first_parse[0].split(separator: ".")
            switch second_parse.count {
            case let a where a != 1 && a != 2:
                return -1
            case 1:
                return 4
            case 2:
                return second_parse[1].count
            default: return -1
            }
        } else {
            return -1
        }
    }
    
    @IBAction func showQRCode(_ sender: Any) {
        let sel = accTableView.selectedRow
        let sel1 = tokenTableView.selectedRow
        if sel >= 0 && sel1 >= 0 {
            let acc_name = accountViewData[sel]["acc"]!
            let token_name = tokenViewData[sel1]["token"]!
            let url_name = accMeta[sel]["path"] as! String
            var qr_string = acc_name + "," + token_name + "," + url_name
            let precision = getTokenPrecision(token: tokenViewData[sel1]["amount"]!)
            if precision >= 0 {
                qr_string += "," + String(precision)
                let qr_image = generateQRCode(from: qr_string)
                QRView.QRImage = qr_image
                QRView.account = acc_name
                QRView.token = token_name
                if (vcc.presentingViewController?.isViewLoaded == true) {
                    vcc.dismiss(vcc)
                }
                
                let sb = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
                if let vc: NSViewController = sb.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("QRView")) as? NSViewController {
                    present(vc, asPopoverRelativeTo: NSRect(x: 300, y: 80, width: 10, height: 10), of: mainView!, preferredEdge: NSRectEdge.maxX, behavior: NSPopover.Behavior.transient)
                    vcc = vc
                }
            } else {
                print("Wrong precision!")
            }
        } else {
            mylib.errorDialog(question: "Not selected account and token!")
        }
    }
    
    func generateQRCode(from string: String) -> NSImage? {
        let data = string.data(using: String.Encoding.ascii)
        if let QRFilter = CIFilter(name: "CIQRCodeGenerator") {
            QRFilter.setValue(data, forKey: "inputMessage")
            guard let QRImage = QRFilter.outputImage else {return nil}
            let transformScale = CGAffineTransform(scaleX: 5.0, y: 5.0)
            let scaledQRImage = QRImage.transformed(by: transformScale)
            let rep = NSCIImageRep(ciImage: scaledQRImage)
            let nsImage = NSImage(size: rep.size)
            nsImage.addRepresentation(rep)
            return nsImage
        }
        return nil
    }
    
    func readPUBKey (account_name: String) -> String {
        let id = Bundle.bundleIDFor(appNamed: "desktopWallet.app")
        let vault = EosioVault(accessGroup: "XXXXXXXXXXX." + id!)
        let keys = try? vault.getAllVaultKeys()
        var pubKey = ""
        if keys != nil && keys!.count > 0 {
            for k in keys! {
                if k.accessGroup == "XXXXXXXXXXX." + id! {
                    var md = try? vault.getKeyMetadata(eosioPublicKey: k.eosioPublicKey)
                    if k.label != nil || md?["label"] != nil {
                        var acc = ""
                        if k.label != nil {
                            acc = k.label!
                        } else {
                            acc = md?["label"] as! String
                        }
                        if acc == account_name {
                            pubKey = k.eosioPublicKey
                            return(pubKey)
                        }
                    } else {
                        print("trace nil", k.label, k.eosioPrivateKey, k.eosioPublicKey, try? vault.getKeyMetadata(eosioPublicKey: k.eosioPublicKey))
                    }
                }
            }
        }
        return(pubKey)
    }
    
    static var selectedAccount = 0
    
    @IBAction func payTo(_ sender: Any) {
        let sel = accTableView.selectedRow
        if sel >= 0 {
            let acc_name = accountViewData[sel]["acc"]!
            payView.payFrom = acc_name
            let pk = readPUBKey(account_name: acc_name)
            if pk != "" {
                payView.pub_key = pk
                let sb = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
                if let vc: NSViewController = sb.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("getQRView")) as? NSViewController {
                    ViewController.selectedAccount = sel
                    self.presentInNewWindow(viewController: vc)
                    vcc = vc
                }
            } else {
                print("error reading public key")
            }
        } else {
            mylib.errorDialog(question: "Not selected account")
        }
    }
    
    @IBAction func viewLedger(_ sender: Any) {
        let sel = accTableView.selectedRow
        let sel1 = tokenTableView.selectedRow
        if sel >= 0 && sel1 >= 0 {
            ledgerView.accountName = accountViewData[sel]["acc"]! as String
            ledgerView.tokenName = tokenViewData[sel1]["token"]! as String
            ledgerView.endpoint = accMeta[sel]["path"] as! String
            let sb = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
            if let vc: NSViewController = sb.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("ledgerView")) as? NSViewController {
                self.presentInNewWindow(viewController: vc)
            }
        } else {
            mylib.errorDialog(question: "Not selected account")
        }
    }
    
    @IBAction func accountLookUp(_ sender: Any) {
        let sel = accTableView.selectedRow
        if sel >= 0 {
            let pubKey = readPUBKey(account_name: accountViewData[sel]["acc"]!)
            let outS = NSMutableAttributedString(string: pubKey, attributes: mylib.globalConst.attrRed18)
            for k in accMeta[sel].keys {
                let s = accMeta[sel][k] as! String
                switch k {
                case "label" : break
                case "path" :
                    outS.append(NSMutableAttributedString(string: "\nEOSIO path: " + s, attributes: mylib.globalConst.attrReg18))
                default:
                    outS.append(NSMutableAttributedString(string: "\nToken symbol: " + s, attributes: mylib.globalConst.attrBlue18))
                }
            }
            lookUpView.outStr = outS
            let sb = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
            if let vc: NSViewController = sb.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("lookUpView")) as? NSViewController {
                self.presentInNewWindow(viewController: vc)
            }
        } else {
            mylib.errorDialog(question: "Not account selected")
        }
    }
    
    @IBAction func createTestAccounts(_ sender: Any) {
    }
    
    @IBOutlet var mainView: NSView!
    @IBOutlet weak var infoLabel: NSTextField!
    @IBOutlet weak var accTableView: NSTableView!
    @IBOutlet weak var tokenTableView: NSTableView!
}

extension ViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        switch tableView.identifier?.rawValue {
        case "acc_table": return (accountViewData.count)
        default: return (tokenViewData.count)
        }
    }
//
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView else { return nil }
        switch tableView.identifier?.rawValue {
        case "acc_table":
            let person = accountViewData[row]
            cell.textField!.lineBreakMode = NSLineBreakMode.byWordWrapping
            cell.textField?.stringValue = person[tableColumn!.identifier.rawValue]!
            cell.textField?.maximumNumberOfLines = 0
        default:
            let person = tokenViewData[row]
            cell.textField!.lineBreakMode = NSLineBreakMode.byWordWrapping
            cell.textField?.stringValue = person[tableColumn!.identifier.rawValue]!
            cell.textField?.maximumNumberOfLines = 0
        }
        return cell
    }

}

extension NSViewController {

   func presentInNewWindow(viewController: NSViewController) {
      let window = NSWindow(contentViewController: viewController)

      var rect = window.contentRect(forFrameRect: window.frame)
// Set your frame width here
      rect.size = .init(width: 220, height: 260)
      let frame = window.frameRect(forContentRect: rect)
      window.setFrame(frame, display: true, animate: true)

      window.makeKeyAndOrderFront(self)
      let windowVC = NSWindowController(window: window)
      windowVC.showWindow(self)
  }
}

extension String {
    var isValidURL: Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
// it is a link, if the match covers the whole string
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }
}
