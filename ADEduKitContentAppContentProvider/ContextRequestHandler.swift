//
//  ContextRequestHandler.swift
//  ADEduKitContentAppContentProvider
//
//  Created by Schwarze on 08.12.21.
//

import ClassKit
import ADEduKit

class ContextRequestHandler: NSObject, NSExtensionRequestHandling, CLSContextProvider {
    // FIXME: The extension shall use the same configuration as the app, but they cannot include each other. Correct that. Maybe use "My"-variant in both targets?
    let appConfig = AppConfig()
    var logConfigDone = false
    let logger = ADLog.sharedInstance.logger(for: ContextRequestHandler.self)

    func beginRequest(with context: NSExtensionContext) {
        // This is a required function defined by the NSExtensionRequestHandling protocol. This function
        // will be called once per connection from a host. Therefore, it may be called several times, if
        // the host disconnects and reconnects several times. This is where you can have code that performs
        // one-time initialization.
        //ADEduLocaleUtil.sharedInstance.activateExtensionMode()
        if (!logConfigDone) {
            logConfigDone = true
            configureLog()
        }
        logger.log("\(#function): (ADEduKitContentAppContentProvider.ContextRequestHandler)")
    }

    func configureLog() {
        let log = ADLog.sharedInstance
        let sc = SharedContainer.sharedInstance
        guard let url = sc.contentProviderLogURL else {
            Log.log("\(#function): could not determine log url")
            return
        }
        Log.log("\(#function): using log directory \(url)")
        let w = ADLogWriterFile(url: url)
        log.add(writer: w)
        let l = log.logger(named: "dummy")
        l.log("ClassKitContentProvider configured log.")
    }

    func updateDescendants(of context: CLSContext, completion: @escaping (Error?) -> Void) {
        logger.log("\(#function): context: identifier=\(context.identifier) path=\(context.identifierPath)")
        guard let container = Facade.sharedInstance.repo().containerForName(name: "adedukitcontentapp") else {
            logger.log("\(#function): error retrieving container for 'adedukitcontentapp'")
            completion(nil)
            return
        }
        let ctxPrv = Facade.sharedInstance.defaultContextProviderFor(container: container)
        logger.log("\(#function): calling updateDescendantsOf for \(context.identifierPath)")
        ctxPrv.updateDescendants(of: context, completion: { (error: Error?) in
            if let e = error {
                self.logger.log("\(#function): completion from ctxPrvImpl.updateDescentantsOf: error=\(e.localizedDescription)")
            } else {
                self.logger.log("\(#function): completion from ctxPrvImpl.updateDescentantsOf: reported no error")
            }
            completion(error)
        })
    }
}
