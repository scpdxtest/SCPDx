//
//  payView.swift
//  desktopWallet
//
//  Created on 26/11/2022.
//

import Cocoa
import AppKit
import EosioSwift
import EosioSwiftAbieosSerializationProvider
import EosioSwiftSoftkeySignatureProvider
import EosioSwiftVaultSignatureProvider
import EosioSwiftVault

class payView: NSViewController {

    static var myImage: NSImage?
    static var payFrom: String?
    static var pub_key = ""
    var amount = ""
    var memo = ""
    var rpcProvider: EosioRpcProvider?
    var precision = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(putImage), name: NSNotification.Name(rawValue: "reload"), object: nil)
    }
    
    @IBAction func importQR(_ sender: Any) {
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseFiles = true;
        dialog.canChooseDirectories = true;
        dialog.allowedFileTypes = ["png"];
        var path = ""
        
        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            let result = dialog.url
            if (result != nil) {
                path = result!.path
            }
            let mI = try? Data(NSData(contentsOfFile: path))
            payView.myImage = NSImage(data: mI!)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reload"), object: nil)
        }
    }
    
    @objc func putImage () {
        imageView.image = payView.myImage
        let readInfo = payView.myImage?.parseQR()
        if readInfo?.count != 1 {
            mylib.errorDialog(question: "Unsupported QR file!")
        } else {
            let payArr = readInfo![0].split(separator: ",")
// 0 - account name, 1 - token symbol, 2 - endpoint, 3 - precisiom
            print("QR Info", readInfo, payArr)
            toBox.stringValue = String(payArr[0])
            tokenBox.stringValue = String(payArr[1])
            endpointBox.stringValue = String(payArr[2])
            fromBox.stringValue = payView.payFrom!
            publicKeyBox.stringValue = payView.pub_key
            precision = Int(payArr[3])!
        }
    }
    
    func payToVault (from: String, to: String, amount: String, currency: String, memo: String, endpoint: URL, pubKey: String) async -> Bool {
        return await withUnsafeContinuation { continuation in

            let data = myEOSIOlib.globalConst.refundS(from: try! EosioName(from), to: try! EosioName(to), quantity: amount + " " + currency, memo: memo)
            let rpcProvider = EosioRpcProvider(endpoint: endpoint)

            let id = Bundle.bundleIDFor(appNamed: "desktopWallet.app")
            let vault = EosioVault(accessGroup: "XXXXXXXXXXX." + id!)

            
            var transaction = EosioTransaction()
            
            let action = try! EosioTransaction.Action(
                account: try! EosioName("eosio.token"),
                name: EosioName("transfer"),
                authorization: [EosioTransaction.Action.Authorization(
                    actor: try! EosioName(from),
                    permission: EosioName("active"))
                ],
                data: data
            )

            transaction.rpcProvider = rpcProvider
            transaction.serializationProvider = EosioAbieosSerializationProvider()
            transaction.serializationProvider = EosioAbieosSerializationProvider()
            transaction.signatureProvider = try? EosioVaultSignatureProvider(accessGroup: "XXXXXXXXXXX." + id!)
            let sProv = try? EosioVaultSignatureProvider(accessGroup: "XXXXXXXXXXX." + id!)

            transaction.add(action: action)

            var signRequest = EosioTransactionSignatureRequest()
            let sTr = try? transaction.serializeTransaction(completion: {ser in
                switch ser {
                case .success(let sTr):
                    signRequest.serializedTransaction = sTr
                    signRequest.publicKeys = [payView.pub_key]
                    signRequest.chainId = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
                    sProv!.signTransaction(request: signRequest, completion: {resp in
                        let serializedTransaction = sTr.hexEncodedString()
                        let signatures = resp.signedTransaction?.signatures
                        let requestParameters = EosioRpcSendTransactionRequest(signatures: signatures!,
                                                                               compression: 0,
                                                                               packedContextFreeData: "",
                                                                               packedTrx: serializedTransaction)
                        
                        rpcProvider.sendTransactionBase(requestParameters: requestParameters) { response in
                            print("transaction rec: ", try! transaction.toJson(prettyPrinted: true))
                            
                            switch response {
                            case .failure (let error):
                                print("*** TRANSACTION ERROR")
                                print("---- ERROR SIGNING OR BROADCASTING TRANSACTION")
                                print(error)
                                print(error.reason)
                                print("err 2")
                                mylib.errorDialog(question: error.reason)
                                continuation.resume(returning: false)
                            case .success (let sendResponse):
                                print("enter 2")
                                let transactionId = sendResponse.transactionId
                                print("Success!\nTransaction ID \(transactionId)")
                                mylib.errorDialog(question: "Success!\nTransaction ID \(transactionId)")
                                continuation.resume(returning: true)
                            }
                        }
                    })
                case .failure(let err):
                    print("error ser", err)
                    continuation.resume(returning: false)
                }
            })
        }
    }

    @IBAction func sendPayment(_ sender: Any) {
        if amountBox.stringValue != "" && fromBox.stringValue != toBox.stringValue {
// eosio payment action here
            Task {
                if try await payToVault(from: payView.payFrom!, to: toBox.stringValue, amount: amountBox.stringValue, currency: tokenBox.stringValue, memo: memoBox.stringValue, endpoint: URL(string: endpointBox.stringValue)!, pubKey: payView.pub_key) {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "accReload"), object: nil)
                    self.view.window?.close()
                } else {
                    print("Error!")
                    self.view.window?.close()
                }
            }
        } else {
            mylib.errorDialog(question: "No amount value or sender is equal to receiver!")
            self.view.window?.close()
        }
    }
    
    func precisionParse (amaount : String) -> String {
        let midS = amount.split(separator: ".")
        if midS.count == 2 {
            var secPart = midS[1]
            if secPart.count < precision {
                for _ in 0 ... precision - secPart.count - 1 { secPart += "0" }
            }
            let outStr = midS[0] + "." + String(secPart)
            return outStr
        } else {
            print("Wrong format")
            return ""
        }
    }
    
    @IBAction func enterAmount(_ sender: Any) {
        if amountBox.stringValue != "" {
            amount = amountBox.stringValue
            let parseAmount = precisionParse(amaount: amount)
            if parseAmount != "" {
                amount = parseAmount
            }
            amountBox.stringValue = parseAmount
        }
    }
    
    @IBAction func enterMemo(_ sender: Any) {
        memo = memoBox.stringValue
    }
    
    @IBOutlet weak var memoBox: NSTextField!
    @IBOutlet weak var amountBox: NSTextField!
    @IBOutlet weak var tokenBox: NSTextField!
    
    @IBOutlet weak var toBox: NSTextField!
    @IBOutlet weak var fromBox: NSTextField!
    @IBOutlet weak var endpointBox: NSTextField!
    @IBOutlet weak var publicKeyBox: NSTextField!
    @IBOutlet weak var imageView: NSImageView!
    
}

extension NSImage {
    func parseQR() -> [String] {
        let imageData = self.tiffRepresentation!

        let ciImage = CIImage(data: imageData)
        guard let image = ciImage else {
            return []
        }

        let detector = CIDetector(ofType: CIDetectorTypeQRCode,
                                  context: nil,
                                  options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])

        let features = detector?.features(in: image) ?? []

        return features.compactMap { feature in
            return (feature as? CIQRCodeFeature)?.messageString
        }
    }
}
