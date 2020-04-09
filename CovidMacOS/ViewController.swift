//
//  ViewController.swift
//  CovidMacOS
//
//  Created by ksmirnov on 04.04.2020.
//  Copyright © 2020 ksmirnov. All rights reserved.
//

import Cocoa

final class ViewController: NSViewController {
    
    // MARK: - Subtypes
    
    private enum Constants {
        static let deseaseCellIdentifier: String = "deseaseCellIdentifier"
        static let textFieldTag: Int = 1000
        static let buttonHeight: CGFloat = 40.0
        static let buttonWidth: CGFloat = 320.0
    }
    
    // MARK: - Properties
    
    private let dataSetDownloader = DataSetDownloader()
    private var models: [DeseaseModel] = [] {
        didSet {
            modelCreateButton.isEnabled = (dataSetURL != nil || !models.isEmpty)
            pickImageButton.isEnabled = false
            pickTestDataSourceButton.isEnabled = false
            tableView.reloadData()
        }
    }
    
    private var dataModelCreator: DataModelCreator?
    
    private var dataSetURL: URL? {
        didSet {
            modelCreateButton.isEnabled = (dataSetURL != nil || !models.isEmpty)
            pickImageButton.isEnabled = false
            pickTestDataSourceButton.isEnabled = false
            if dataSetURL == nil {
                pickDataSourceButton.title = "Pick data source"
            } else {
                pickDataSourceButton.title = "Remove data source"
            }
        }
    }
    private var testDataSetFoldetURL: URL?
    
    // MARK: - UI Elements
    
    private lazy var downloadButton: NSButton = {
        let button = NSButton(title: "Download DataSet", target: self, action: #selector(buttonDidTapped(_:)))
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var modelCreateButton: NSButton = {
        let button = NSButton(title: "Create Model", target: self, action: #selector(modelCreateButtonDidTapped))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false
        return button
    }()
    
    private lazy var showAppFolderButton: NSButton = {
        let button = NSButton(title: "Show App Folder in Finder", target: self, action: #selector(showAppFolderButtonDidTapped))
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var pickImageButton: NSButton = {
        let button = NSButton(title: "Pick image", target: self, action: #selector(pickImageButtonDidTapped))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false
        return button
    }()
    
    private lazy var pickTestDataSourceButton: NSButton = {
        let button = NSButton(title: "Pick test datasource", target: self, action: #selector(pickTestDataSourceButtonDidTapped))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false
        return button
    }()
    
    private lazy var pickDataSourceButton: NSButton = {
        let button = NSButton(title: "Pick data source insted of download", target: self, action: #selector(pickDataSourceButtonDidTapped))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.bezelColor = .none
        return button
    }()

    private lazy var scrollView: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = true
        return scrollView
    }()
    
    private lazy var tableView: NSTableView = {
        let tableView = NSTableView()
        for columnId in DeseaseModelHeader.allCases {
            let identifier = NSUserInterfaceItemIdentifier(columnId.rawValue)
            let tableColumn = NSTableColumn(identifier: identifier)
            tableColumn.title = columnId.rawValue
            tableView.addTableColumn(tableColumn)
        }
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    private lazy var progressIndicator: NSProgressIndicator = {
        let progressIndicator = NSProgressIndicator()
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        return progressIndicator
    }()
    private var progressIndicatorConstraints: [NSLayoutConstraint] = []
    
    // MARK: - Lifecycle
    
    override func loadView() {
        view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: 1024.0).isActive = true
        view.heightAnchor.constraint(equalToConstant: 512.0).isActive = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(downloadButton)
        view.addSubview(modelCreateButton)
        view.addSubview(showAppFolderButton)
        view.addSubview(scrollView)
        view.addSubview(pickImageButton)
        view.addSubview(pickDataSourceButton)
        view.addSubview(pickTestDataSourceButton)
        
        NSLayoutConstraint.activate([
            downloadButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            downloadButton.topAnchor.constraint(equalTo: view.topAnchor),
            downloadButton.widthAnchor.constraint(equalToConstant: Constants.buttonWidth),
            downloadButton.heightAnchor.constraint(equalToConstant: Constants.buttonHeight),
            
            pickDataSourceButton.leadingAnchor.constraint(equalTo: downloadButton.trailingAnchor, constant: 32.0),
            pickDataSourceButton.topAnchor.constraint(equalTo: view.topAnchor),
            pickDataSourceButton.widthAnchor.constraint(equalToConstant: Constants.buttonWidth),
            pickDataSourceButton.heightAnchor.constraint(equalToConstant: Constants.buttonHeight),
            
            modelCreateButton.leadingAnchor.constraint(equalTo: pickDataSourceButton.trailingAnchor, constant: 32.0),
            modelCreateButton.topAnchor.constraint(equalTo: view.topAnchor),
            modelCreateButton.widthAnchor.constraint(equalToConstant: Constants.buttonWidth),
            modelCreateButton.heightAnchor.constraint(equalToConstant: Constants.buttonHeight),
            
            pickImageButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pickImageButton.topAnchor.constraint(equalTo: downloadButton.bottomAnchor),
            pickImageButton.widthAnchor.constraint(equalToConstant: Constants.buttonWidth),
            pickImageButton.heightAnchor.constraint(equalToConstant: Constants.buttonHeight),
            
            pickTestDataSourceButton.leadingAnchor.constraint(equalTo: pickImageButton.trailingAnchor, constant: 32.0),
            pickTestDataSourceButton.topAnchor.constraint(equalTo: downloadButton.bottomAnchor),
            pickTestDataSourceButton.widthAnchor.constraint(equalToConstant: Constants.buttonWidth),
            pickTestDataSourceButton.heightAnchor.constraint(equalToConstant: Constants.buttonHeight),
            
            showAppFolderButton.leadingAnchor.constraint(equalTo: pickTestDataSourceButton.trailingAnchor, constant: 32.0),
            showAppFolderButton.topAnchor.constraint(equalTo: downloadButton.bottomAnchor),
            showAppFolderButton.widthAnchor.constraint(equalToConstant: Constants.buttonWidth),
            showAppFolderButton.heightAnchor.constraint(equalToConstant: Constants.buttonHeight),
            
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.buttonHeight * 2.0),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        tableView.frame = scrollView.bounds
        scrollView.documentView = tableView
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
}

// MARK: - IBAction's

extension ViewController {
    
    @objc
    private func buttonDidTapped(_ sender: NSButton) {
        models = []
        startProgressIndicator(sender)
        dataSetDownloader?.execute { [weak self, weak sender] result in
            if let sender = sender {
                self?.stopProgressIndicator(sender)
            }
            DispatchQueue.main.async {
                switch result {
                case .success(let models):
                    self?.models = models
                case .failure(let error):
                    let message = "dataSetDownloader?.execute failure with error: \(error.localizedDescription)"
                    self?.alert(with: message)
                    print("\(#function), \(message)")
                }
            }
        }
    }
    
    
    @objc
    private func modelCreateButtonDidTapped(_ sender: NSButton) {
        startProgressIndicator(sender)
        pickImageButton.isEnabled = false
        pickTestDataSourceButton.isEnabled = false
        
        DispatchQueue.global().async { [weak self, weak sender] in
            guard let self = self else { return }
            do {
                if let dataSetURL = self.dataSetURL, let folder = DeseaseModel.folder {
                    self.dataModelCreator = try DataModelCreator(trainingDir: dataSetURL, to: folder.deletingLastPathComponent())
                } else if let folder = DeseaseModel.folder {
                    self.dataModelCreator = try DataModelCreator(trainingDir: folder, to: folder.deletingLastPathComponent())
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    let message = "DataModelCreator creating failure with error: \(error.localizedDescription)"
                    self?.alert(with: message)
                    print("\(#function), \(message)")
                }
            }
            DispatchQueue.main.async { [weak self] in
                let message = self?.dataModelCreator?.description ?? "Model is successfully created"
                self?.alert(with: message)
                if let sender = sender {
                    self?.stopProgressIndicator(sender)
                }
                self?.pickImageButton.isEnabled = true
                self?.pickTestDataSourceButton.isEnabled = true
            }
        }
    }
    
    @objc
    private func showAppFolderButtonDidTapped(_ sender: NSButton) {
        guard let folder = DeseaseModel.folder?.deletingLastPathComponent() else { return }
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: folder.path)
    }
    
    @objc
    private func pickImageButtonDidTapped(_ sender: NSButton) {
        let dialog = NSOpenPanel()
        dialog.title = "Choose an image"
        dialog.showsResizeIndicator = false
        dialog.showsHiddenFiles = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories = false
        dialog.allowedFileTypes = ["png", "jpg", "jpeg"]
        dialog.minSize = CGSize(width: 512.0, height: 512.0)
        
        guard dialog.runModal() == .OK, let imageURL = dialog.url else {
            let message = "Troubles with image picking"
            alert(with: message)
            print("\(#function), \(message)")
            return
        }
        do {
            let prediction = try dataModelCreator?.prediction(from: imageURL) ?? "none"
            let text = "result of prediction: \n \(prediction)"
            alert(with: text)
            print("\(#function), \(text)")
        } catch {
            let message = "DataModelCreator creating failure with error: \(error.localizedDescription)"
            alert(with: message)
            print("\(#function), \(message)")
        }
    }
    
    @objc
    private func pickDataSourceButtonDidTapped(_ sender: NSButton) {
        guard dataSetURL == nil else {
            dataSetURL = nil
            return
        }
        let dialog = NSOpenPanel()
        dialog.title = "Choose an datasource"
        dialog.showsResizeIndicator = false
        dialog.showsHiddenFiles = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseFiles = false
        dialog.canChooseDirectories = true
        dialog.allowedFileTypes = ["mlmodel"]
        dialog.minSize = CGSize(width: 512.0, height: 512.0)
        
        guard dialog.runModal() == .OK, let dataSetURL = dialog.url else {
            let message = "Troubles with model picking"
            alert(with: message)
            print("\(#function), \(message)")
            return
        }
        self.dataSetURL = dataSetURL
    }
    
    @objc
    private func pickTestDataSourceButtonDidTapped(_ sender: NSButton) {
        let dialog = NSOpenPanel()
        dialog.title = "Choose an data source"
        dialog.showsResizeIndicator = false
        dialog.showsHiddenFiles = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories = true
        dialog.canChooseFiles = false
        dialog.minSize = CGSize(width: 512.0, height: 512.0)
        
        guard dialog.runModal() == .OK, let testDataSetFoldetURL = dialog.url else {
            let message = "Troubles with data set picking"
            alert(with: message)
            print("\(#function), \(message)")
            return
        }
        self.testDataSetFoldetURL = testDataSetFoldetURL
        if let metrics = dataModelCreator?.evaluation(with: testDataSetFoldetURL) {
            alert(with: "\(metrics)")
        }
    }
    
}

// MARK: - Alert

extension ViewController {
    
    @discardableResult
    func alert(with text: String) -> Bool {
        let alert: NSAlert = NSAlert()
        alert.messageText = text
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Ok")
        let res = alert.runModal()
        if res == .alertFirstButtonReturn {
            return true
        }
        return false
    }
    
}

// MARK: - Progress Indicator

extension ViewController {
    
    private func startProgressIndicator(_ sender: NSView) {
        NSLayoutConstraint.deactivate(progressIndicatorConstraints)
        progressIndicator.removeFromSuperview()
        sender.addSubview(progressIndicator)
        
        progressIndicatorConstraints = [
            progressIndicator.leadingAnchor.constraint(equalTo: sender.leadingAnchor),
            progressIndicator.trailingAnchor.constraint(equalTo: sender.trailingAnchor),
            progressIndicator.bottomAnchor.constraint(equalTo: sender.bottomAnchor)
        ]
        NSLayoutConstraint.activate(progressIndicatorConstraints)
        progressIndicator.startAnimation(sender)
    }
    
    private func stopProgressIndicator(_ sender: NSView) {
        NSLayoutConstraint.deactivate(progressIndicatorConstraints)
        progressIndicator.removeFromSuperview()
        progressIndicator.stopAnimation(sender)
    }
}

// MARK: - NSTableViewDataSource

extension ViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return models.count
    }
}

// MARK: - NSTableViewDelegate

extension ViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let model = models[row]
        
        let identifier = NSUserInterfaceItemIdentifier(rawValue: Constants.deseaseCellIdentifier)
        let tableCell: NSTableCellView!
        var tableCellTextField: NSTextField!
        if let cell = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView {
            tableCellTextField = cell.viewWithTag(Constants.textFieldTag) as? NSTextField
            tableCell = cell
        } else {
            let cell = NSTableCellView()
            cell.identifier = identifier
            let textField = NSTextField()
            textField.isBezeled = false
            textField.isEditable = false
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.tag = Constants.textFieldTag
            cell.addSubview(textField)
            
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cell.leadingAnchor),
                textField.trailingAnchor.constraint(equalTo: cell.trailingAnchor),
                textField.topAnchor.constraint(equalTo: cell.topAnchor),
                textField.bottomAnchor.constraint(equalTo: cell.bottomAnchor)
            ])
            textField.sizeToFit()
            
            tableCellTextField = textField
            tableCell = cell
        }
        
        if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: DeseaseModelHeader.patientId.rawValue)  {
            tableCellTextField.stringValue = "patientId"
            tableCellTextField.stringValue = "\(model.patientId)"
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: DeseaseModelHeader.offset.rawValue)  {
            tableCellTextField.stringValue = "offset"
            tableCellTextField.stringValue = "\(model.offset ?? -1)"
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: DeseaseModelHeader.sex.rawValue)  {
            tableCellTextField.stringValue = "sex"
            tableCellTextField.stringValue = "\(model.sex?.rawValue ?? "_")"
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: DeseaseModelHeader.age.rawValue)  {
            tableCellTextField.stringValue = "age"
            tableCellTextField.stringValue = "\(model.age ?? -1)"
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: DeseaseModelHeader.finding.rawValue)  {
            tableCellTextField.stringValue = "finding"
            tableCellTextField.stringValue = "\(model.finding.map { $0.rawValue })"
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: DeseaseModelHeader.finding.rawValue)  {
            tableCellTextField.stringValue = "survival"
            tableCellTextField.stringValue = "\(model.survival?.rawValue ?? "_")"
       } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: DeseaseModelHeader.intubated.rawValue)  {
            tableCellTextField.stringValue = "intubated"
            tableCellTextField.stringValue = "\(model.intubated?.rawValue ?? "_")"
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: DeseaseModelHeader.temperature.rawValue)  {
            tableCellTextField.stringValue = "temperature"
            tableCellTextField.stringValue = "\(model.temperature ?? -1)"
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: DeseaseModelHeader.pO2Saturation.rawValue)  {
            tableCellTextField.stringValue = "pO2Saturation"
            tableCellTextField.stringValue = "\(model.pO2Saturation ?? -1)"
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: DeseaseModelHeader.leukocyteCount.rawValue)  {
            tableCellTextField.stringValue = "leukocyteCount"
            tableCellTextField.stringValue = "\(model.leukocyteCount ?? -1)"
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: DeseaseModelHeader.neutrophilCount.rawValue)  {
            tableCellTextField.stringValue = "neutrophilCount"
            tableCellTextField.stringValue = "\(model.neutrophilCount ?? -1)"
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: DeseaseModelHeader.lymphocyteCount.rawValue)  {
            tableCellTextField.stringValue = "lymphocyteCount"
            tableCellTextField.stringValue = "\(model.lymphocyteCount ?? -1)"
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: DeseaseModelHeader.view.rawValue)  {
            tableCellTextField.stringValue = "view"
            tableCellTextField.stringValue = "\(model.view.rawValue)"
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: DeseaseModelHeader.modality.rawValue)  {
            tableCellTextField.stringValue = "modality"
            tableCellTextField.stringValue = "\(model.modality.rawValue)"
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: DeseaseModelHeader.date.rawValue)  {
            tableCellTextField.stringValue = "date"
            tableCellTextField.stringValue = "\(model.date)"
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: DeseaseModelHeader.location.rawValue)  {
            tableCellTextField.stringValue = "location"
            tableCellTextField.stringValue = "\(model.location)"
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: DeseaseModelHeader.folder.rawValue)  {
            tableCellTextField.stringValue = "folder"
            tableCellTextField.stringValue = "\(model.folder)"
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: DeseaseModelHeader.filename.rawValue)  {
            tableCellTextField.stringValue = "filename"
            tableCellTextField.stringValue = "\(model.filename)"
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: DeseaseModelHeader.doi.rawValue)  {
            tableCellTextField.stringValue = "doi"
            tableCellTextField.stringValue = "\(model.doi)"
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: DeseaseModelHeader.url.rawValue)  {
            tableCellTextField.stringValue = "url"
            tableCellTextField.stringValue = "\(model.url)"
        }else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: DeseaseModelHeader.license.rawValue)  {
            tableCellTextField.stringValue = "license"
            tableCellTextField.stringValue = "\(model.license)"
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: DeseaseModelHeader.clinicalNotes.rawValue)  {
            tableCellTextField.stringValue = "clinicalNotes"
            tableCellTextField.stringValue = "\(model.clinicalNotes)"
        }
        return tableCell
    }
    

}
