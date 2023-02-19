//
//  SharedContainer.swift
//  ADEduKitContentApp
//
//  Created by Schwarze on 25.01.22.
//

import Foundation

final class Observer {
    static var counter = 0
    let observeQueue = DispatchQueue(label: "fs_obs_q_\(counter)")
    let url: URL
    var descriptor: Int32 = -1
    let ds: DispatchSourceFileSystemObject
    var block: (() -> ())?
    var closeBlock: (() -> ())?

    init(url: URL) throws {
        // Log.log("\(#function): queue = \(observeQueue)")
        // Log.log("\(#function): url = \(url)")
        self.url = url
        if !FileManager.default.fileExists(atPath: url.path) {
            let d = Data()
            try? d.write(to: url)
        }
        descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else {
            let err = errno
            Log.log("\(#function): could not open \(url) for event tracking")
            throw NSError(domain: POSIXError.errorDomain, code: Int(err), userInfo: nil)
        }
        Log.log("\(#function): opened url = \(url)")
        Log.log("\(#function): descriptor = \(descriptor)")
        ds = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor, eventMask: [.write], queue: observeQueue)
        Log.log("\(#function): ds = \(ds)")
        ds.setEventHandler(handler: {
            Log.log("\(#function): write event handler triggered")
            if let b = self.block {
                b()
            }
        })
        ds.setCancelHandler(handler: {
            Log.log("\(#function): cancel event handler triggered")
            if self.descriptor >= 0 {
                close(self.descriptor)
                self.descriptor = -1
            }
            if let b = self.closeBlock {
                self.closeBlock = nil
                b()
            }
        })
    }

    func start() {
        Log.log("\(#function): ds.start()")
        ds.resume()
    }

    func stop() {
        Log.log("\(#function): ds.cancel()")
        ds.cancel()
    }

    deinit {
        Log.log("\(#function): deinit")
        if descriptor >= 0 {
            ds.cancel()
        } else {
            closeBlock = nil
        }
        block = nil
    }
}

final class SharedContainer {
    static let sharedInstance = SharedContainer()
    static let groupId = "group.com.admadic.adedukit.shared.store"
    static let contentProviderLogName = "contentProvider.log"

    private var _contentProviderLogURL: URL?
    var contentProviderLogURL: URL? {
        get {
            if let u = _contentProviderLogURL {
                return u
            }
            if let u = directory() {
                let u2 = u.appendingPathComponent(Self.contentProviderLogName)
                _contentProviderLogURL = u2
                return u2
            }
            return nil
        }
    }

    var lastLogReadPos : UInt64 = 0
    var lastLogTime: Int = 0

    func directory() -> URL? {
        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.groupId)
        return url
    }

    func writeContentProviderLog(msg: String) {
        guard let url = contentProviderLogURL else { return }
        guard let fh = try? FileHandle.init(forWritingTo: url) else { return }
        defer {
            try? fh.close()
        }
        let _ = try? fh.seekToEnd()
        guard let d = (msg + "\n").data(using: .utf8) else { return }
        try? fh.write(contentsOf: d)
    }

    func getNextContentProviderLogString() -> String? {
        guard let url = contentProviderLogURL else { return nil }
        guard let fh = try? FileHandle.init(forReadingFrom: url) else { return nil }
        defer {
            try? fh.close()
        }
        try? fh.seek(toOffset: lastLogReadPos)
        guard let d = try? fh.readToEnd() else { return nil }
        if let p = try? fh.offset() {
            // FIXME: when offset() fails, stop future read process?
            lastLogReadPos = p
        }
        let s = String(data: d, encoding: .utf8)
        return s
    }
}
