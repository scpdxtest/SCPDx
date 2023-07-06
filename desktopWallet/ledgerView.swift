//
//  ledgerView.swift
//  desktopWallet
//
//  Created on 04/12/2022.
//

import Cocoa
import EosioSwift
import EosioSwiftAbieosSerializationProvider
import EosioSwiftSoftkeySignatureProvider

class ledgerView: NSViewController {
    static var accountName = ""
    static var tokenName = ""
    
    var viewData = [["date":NSMutableAttributedString(), "token":NSMutableAttributedString(), "amount":NSMutableAttributedString(), "contragent":NSMutableAttributedString(), "op":NSMutableAttributedString(), "memo":NSMutableAttributedString()]]
    struct actualData {
        var date:Date
        var token: String
        var amount: String
        var contragent: String
        var op: String
        var memo: String
    }

    var tbl_key = ""
    var more = true
    static var endpoint = ""
    static var store_table_name = ""
    var rpcProvider: EosioRpcProvider?
    var actData = [actualData]()

    func readRows (key: String) async -> (Int, Bool, String) {
        rpcProvider = EosioRpcProvider(endpoint: URL(string: ledgerView.endpoint)!)
        let rpcProvider = rpcProvider
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return await withUnsafeContinuation { continuation in
            var myS =  EosioRpcTableRowsRequest(scope: ledgerView.accountName, code: ledgerView.accountName, table: "accledger", json: true, limit: UInt32(10000), tableKey: "", lowerBound: key, upperBound: key, indexPosition: "6", keyType: "i64", encodeType: .hex, reverse: false, showPayer: false)

            rpcProvider!.getTableRows(requestParameters: myS, completion: { (r) in
                switch r {
                case .failure(let err):
                    print("error reading", err.reason)
                    continuation.resume(returning: false)
                case .success(let results):
                    self.more = results.more
                    let resp = results._rawResponse as! Dictionary<String,Any>
                    self.tbl_key = resp["next_key"] as! String
                    for r in results.rows {
                        let dict = r as! Dictionary<String,Any>
                        let from = dict["from"] as? String ?? ""
                        let to = dict["to"]! as? String ?? ""
                        let memo = dict["memo"]! as? String ?? ""
                        let token = dict["token"]! as? String ?? ""
                        let qty = dict["qty"] as? String ?? ""
                        let tmS = dict["time"] as! String
                        let tm = dateFormatter.date(from: tmS)
                        var contragent = to
                        var opt = "Dt"
                        if to == ledgerView.accountName {
                            contragent = from
                            opt = "Ct"
                        }
                        let tempRec = actualData(date: tm!, token: token, amount: qty, contragent: contragent, op: opt, memo: memo)
                        self.actData.append(tempRec)
                    }
                    continuation.resume(returning: (results.rows.count, self.more, self.tbl_key))
                }
            })
        }
    }
    
    func importBCtable() async -> Bool {
        viewData.removeAll()
        actData.removeAll()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        tbl_key = ledgerView.tokenName.lowercased()
        while self.more {
            let res = try? await readRows(key: tbl_key)
            self.more = res!.1
            self.tbl_key = res!.2
        }
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        accountBox.attributedStringValue = NSMutableAttributedString(string: ledgerView.accountName, attributes: mylib.globalConst.attrReg18)
        tokenBox.attributedStringValue = NSMutableAttributedString(string: ledgerView.tokenName, attributes: mylib.globalConst.attrReg18)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.sizeLastColumnToFit()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        Task {
            let res = try await importBCtable()
            let a = actData.sorted(by: {$1.date >= $0.date})
            for aa in a {
                var myA = mylib.globalConst.attrReg18
                if aa.op == "Dt" { myA = mylib.globalConst.attrRed18 }
                viewData.append(["date":NSMutableAttributedString(string: dateFormatter.string(from: aa.date), attributes: myA), "token":NSMutableAttributedString(string: aa.token, attributes: myA), "amount":NSMutableAttributedString(string: aa.amount, attributes: myA), "memo":NSMutableAttributedString(string: aa.memo, attributes: myA), "contragent":NSMutableAttributedString(string: aa.contragent, attributes: myA), "op":NSMutableAttributedString(string: aa.op, attributes: myA)])
                                       
            }
            tableView.reloadData()
        }
    }
    
    @IBOutlet weak var tokenBox: NSTextField!
    @IBOutlet weak var accountBox: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
}

extension ledgerView: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return (viewData.count)
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView else { return nil }
        let person = viewData[row]
        cell.textField!.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.textField?.attributedStringValue = person[tableColumn!.identifier.rawValue]!
        cell.textField?.maximumNumberOfLines = 0
        return cell
    }

}
