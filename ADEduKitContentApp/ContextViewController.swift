//
//  ContextViewController.swift
//  ADEduKitContentApp
//
//  Created by Schwarze on 11.12.21.
//

import UIKit
import ADEduKit
import ClassKit

final class ContextViewController: UIViewController, ControlViewDelegate {
    var container: Container?
    var model: ModelNode?
    var util: ClassKitUtil?

    var progressState: ProgressState = ProgressState()

    @IBOutlet weak var controlView: ControlView!
    @IBOutlet weak var identifierLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var idPathLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    
    static func createInstance() -> ContextViewController {
        return ContextViewController(nibName: "ContextViewController", bundle: Bundle.main)
    }

    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        progressState = ProgressState(taskIndex: -1, taskCount: 5, taskCorrect: 0)
        util = container?.classKitUtil()

        updateTaskState()

        controlView.controlViewDelegate = self

        // Some preliminary tests for clskit support
        /*
        let util = container?.classKitUtil()
        CLSDataStore.shared.mainAppContext.descendant(matchingIdentifierPath: []) { ctx, error in
            Log.log("\(#function): ctx=\(ctx) error=\(error)")
        }
         */
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !progressState.tasksInitial {
            if let m = model {
                util?.startActivityForModel(model: m)
                // FIXME: implement matching end
            }
            selectNextTask()
        }
    }

    // MARK: - UI Actions
    
    @IBAction func didTapDone(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func didTapStart(_ sender: Any) {
        if let util = util, let model = model {
            util.startActivityForModel(model: model)
        }
    }

    // MARK: - Fine grained task actions

    @IBAction func didTapStop(_ sender: Any) {
        if let util = util, let model = model {
            util.stopActivityForModel(model: model)
        }
    }

    @IBAction func didTapScore(_ sender: Any) {
        if let util = util, let model = model {
            util.updateActivityForModel(model: model, progress: 0.42, score: 85, maxScore: 100)
        }
    }

    // MARK: - Helpers
    
    func updateTaskState() {
        guard let m = model else { return }

        identifierLabel.text = m.identifier()
        titleLabel.text = m.localizedTitle()
        idPathLabel.text = m.identifierPath().joined(separator: ".")
        typeLabel.text = m.type()
        summaryLabel.text = m.summary()

        controlView.updateTask(info: m.localizedSummary())
        controlView.updateTask(progressState: progressState)
    }

    func confirmAction(title: String, confirm: (() -> ())?, cancel: (() -> ())? = nil) {
        let ac = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { ActionHandler in
            confirm?()
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { ActionHandler in
            cancel?()
        }))
        present(ac, animated: true, completion: nil)
    }

    // MARK: - ADEduKit ControlView Delegate
    
    func controlViewDoPrev() {
        confirmAction(title: "Go to previous task?", confirm: { () -> () in
            self.goPrev()
        })
    }

    func controlViewDoNext() {
        confirmAction(title: "Go to next task?", confirm: { () -> () in
            self.goNext()
        })
    }

    func controlViewDoReset() {
        confirmAction(title: "Reset all tasks?", confirm: { () -> () in
            self.goReset()
        })
    }

    func controlViewDoStop() {
        let ctxVc = self
        confirmAction(title: "Stop all tasks?", confirm: { () -> () in
            self.goStop()
            ctxVc.dismiss(animated: true, completion: nil)
        })
    }

    // MARK: - Task Navigation & Actions
    
    func goPrev() {
        if progressState.hasPrev() {
            _ = progressState.selectPrev()
            updateTaskState()
        }
    }

    func goNext() {
        if progressState.hasNext() {
            _ = progressState.selectNext()
            updateTaskState()
        }
    }

    func goReset() {
        // FIXME: implement reset method
    }

    func goStop() {
        // FIXME: implement stop method
    }

    func selectNextTask() {
        let prevTaskIndex = progressState.taskIndex
        if progressState.hasNext() {
            _ = progressState.selectNext()
            controlView.updateTask(progressState: progressState)
        }

        if progressState.isValid(index: prevTaskIndex) {
            // end task for prevTaskIndex
            // just update score
            // util?.stopActivityForModel(model: model)
            util?.updateActivityForModel(model: model!, progress: progressState.progress, score: progressState.score, maxScore: progressState.maxScore)
        }
        if progressState.isValid(index: progressState.taskIndex) {
            // begin task for taskIndex
        }
    }
}
