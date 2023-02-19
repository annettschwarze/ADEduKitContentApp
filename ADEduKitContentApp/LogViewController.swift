//
//  LogViewController.swift
//  ADEduKitContentApp
//
//  Created by Schwarze on 07.03.22.
//

import UIKit
import ADEduKit

final class LogViewController: UIViewController {
    @IBOutlet weak var logTextView: UITextView!

    var logObserver: Observer?
    var readCount: UInt64 = 0
    var fh: FileHandle?

    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        attach()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - Log Access Methods
    
    func attach() {
        guard let u = SharedContainer.sharedInstance.contentProviderLogURL else {
            Log.log("\(#function): error determining shared log url")
            return
        }
        do {
            let o = try Observer(url: u)
            Log.log("\(#function): will observe \(u)")
            logObserver = o
            o.block = {
                DispatchQueue.main.async {
                    guard let vs = try? u.resourceValues(forKeys: [.fileSizeKey]), let fs = vs.fileSize else {
                        Log.log("\(#function): cannot determine current file size")
                        return
                    }
                    self.readUntil(UInt64(fs))
                }
            }
            if let fh = try? FileHandle(forReadingFrom: u) {
                self.fh = fh
            }
            o.start()
        } catch {
            Log.log("\(error)")
        }

    }

    func readUntil(_ len: UInt64) {
        guard let fh = fh else { return }
        do {
            try fh.seek(toOffset: readCount)
            if let d = try fh.readToEnd() {
                readCount += UInt64(d.count)
                let s = String(data: d, encoding: .utf8) ?? "(conversion error)"
                logTextView.textStorage.append(NSAttributedString(string: s))
                logTextView.textStorage.append(NSAttributedString(string: "\n"))
            }
        } catch {
            Log.log("read failed")
        }
    }

    // MARK: - User Actions
    
    @IBAction func doClose(_ sender: Any) {
        logObserver?.stop()
        try? fh?.close()
        dismiss(animated: true)
    }
    
    @IBAction func doWriteCheck(_ sender: Any) {
        guard let u = SharedContainer.sharedInstance.contentProviderLogURL else {
            Log.log("\(#function): error determining shared log url")
            return
        }
        do {
            let fh = try FileHandle(forWritingTo: u)
            defer { try? fh.close() }
            try fh.seekToEnd()
            let d = "ping\n".data(using: .utf8)!
            fh.write(d)
            Log.log("\(#function): wrote ping to \(u)")
        } catch {
            Log.log("error: \(error)")
        }

        do {
            let l2 = ADLog.create()
            let w = ADLogWriterFile(url: u)
            l2.add(writer: w)
            let l = l2.logger(named: "dummy")
            l.log("ping from secondary adlog instance")
        }
    }
}
