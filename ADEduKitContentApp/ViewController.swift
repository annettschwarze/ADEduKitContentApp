//
//  ViewController.swift
//  ADEduKitContentApp
//
//  Created by Schwarze on 08.12.21.
//

import UIKit
import ADEduKit

final class ViewController: UIViewController, SelectContextViewControllerDelegate {
    let appConfig = ADEduKitMyAppConfig()
    var currentContainer: Container?
    var currentSelectVC: SelectContextViewController?
    var logObserver: Observer?

    @IBOutlet weak var logsButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let u = SharedContainer.sharedInstance.contentProviderLogURL else {
            Log.log("\(#function): error determining shared log url")
            return
        }
        if let o = try? Observer(url: u) {
            logObserver = o
            o.block = {
                DispatchQueue.main.async {
                    if let vs = try? u.resourceValues(forKeys: [.contentModificationDateKey]) {
                        let md = vs.contentModificationDate?.description ?? "<unknown>"
                        self.logsButton.setTitle("Log (\(md))", for: .normal)
                    }
                }
            }
            o.start()
        }
    }

    @IBAction func didTapTestOpenURL(_ sender: Any) {
        let vc = SelectContextViewController.createInstance()
        let container = Facade.sharedInstance.repo().containerForName(name: appConfig.standardContainerName())
        currentContainer = container
        let model = container?.rootModelNode()
        vc.update(rootNode: model, container: container)
        vc.selectContextViewControllerDelegate = self
        present(vc, animated: true, completion: nil)
    }

    func selectContextViewControllerDidSelect(node: ModelNode, container: Container) {
        guard let url = node.url(scheme: currentContainer?.metadata()?.scheme() ?? "") else { return }
        let _ = UIApplication.shared.delegate?.application?(UIApplication.shared, open: url, options: [:])
    }

    func selectContextViewControllerWillClose() {
        // nothing to do
    }
    
    @IBAction func didTapLogs(_ sender: Any) {
        let vc = LogViewController(nibName: "LogViewController", bundle: nil)
        present(vc, animated: true, completion: nil)
    }
}
