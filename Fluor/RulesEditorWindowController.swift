//
//  RulesEditorWindowController.swift
//  Fluor
//
//  Created by Pierre TACCHI on 04/09/16.
//  Copyright © 2016 Pyrolyse. All rights reserved.
//

import Cocoa

class RulesEditorWindowController: NSWindowController {
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var rulesArrayController: NSArrayController!
    
    dynamic var rulesArray = [RuleItem]()
    dynamic var rulesCount: Int = 0
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.styleMask.formUnion(.nonactivatingPanel)
        window?.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ruleDidChangeForApp(notification:)), name: Notification.Name.RuleDidChangeForApp, object: nil)
        
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        rulesArrayController.sortDescriptors = [sortDescriptor]
        
        rulesArray = BehaviorManager.default.retrieveRules()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Called when a rule change for an application.
    ///
    /// - parameter notification: The notification.
    @objc private func ruleDidChangeForApp(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any], let appId = userInfo["id"] as? String, let appBehavior = userInfo["behavior"] as? AppBehavior, let appURL = userInfo["url"] as? URL else { return }
        if let index = rulesArray.index(where: { $0.id == appId }) {
            if case .inferred = appBehavior {
                rulesArray.remove(at: index)
            } else {
                rulesArray[index] = RuleItem(fromItem: rulesArray[index], withBehavior: appBehavior.rawValue - 1)
            }
        } else {
            let appPath = appURL.path
            let appIcon = NSWorkspace.shared().icon(forFile: appPath)
            let appName = Bundle(path: appPath)?.localizedInfoDictionary?["CFBundleName"] as? String ?? appURL.deletingPathExtension().lastPathComponent
            let item = RuleItem(id: appId, url: appURL, icon: appIcon, name: appName, behavior: appBehavior.rawValue - 1)
            rulesArray.append(item)
        }
    }
    
    /// Add a rule for a given application.
    ///
    /// - parameter sender: The object that sent the action.
    @IBAction func addRule(_ sender: AnyObject) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = true
        openPanel.allowedFileTypes = ["com.apple.bundle"]
        openPanel.canChooseDirectories = false
        openPanel.directoryURL = URL(fileURLWithPath: "/Applications")
        openPanel.runModal()
        openPanel.urls.forEach { (appURL) in
            let appBundle = Bundle(url: appURL)!
            let appId = appBundle.bundleIdentifier!
            let appPath = appURL.path
            let appIcon = NSWorkspace.shared().icon(forFile: appPath)
            let appName = Bundle(path: appPath)?.localizedInfoDictionary?["CFBundleName"] as? String ?? appURL.deletingPathExtension().lastPathComponent
            BehaviorManager.default.setBehaviorForApp(id: appId, behavior: .apple, url: appURL)
            let item = RuleItem(id: appId, url: appURL, icon: appIcon, name: appName, behavior: AppBehavior.apple.rawValue)
            rulesArray.append(item)
        }
    }
    
    /// Remove a rule for a given application.
    ///
    /// - parameter sender: The object that sent the action.
    @IBAction func removeRule(_ sender: AnyObject) {
        let items = rulesArrayController.selectedObjects as! [RuleItem]
        items.forEach { (item) in
            BehaviorManager.default.setBehaviorForApp(id: item.id, behavior: .inferred, url: item.url)
            let index = rulesArray.index(of: item)!
            rulesArray.remove(at: index)
        }
    }
}
