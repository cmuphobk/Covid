//
//  ViewController.swift
//  Covid
//
//  Created by ksmirnov on 03.04.2020.
//  Copyright © 2020 ksmirnov. All rights reserved.
//

import UIKit

final class ViewController: UIViewController {
    
    private enum Constants {
        static let deseaseCellIdentifier: String = "deseaseCellIdentifier"
        static let downloadButtonHeight: CGFloat = 80.0
    }
    
    private let dataSetDownloader = DataSetDownloader()
    private var models: [DeseaseModel] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private lazy var downloadButton: UIButton = {
        let button = UIButton()
        button.setTitle("Download DataSet", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(buttonDidTapped(_:)), for: .touchDown)
        return button
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.hidesWhenStopped = true
        activityIndicator.stopAnimating()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.addSubview(tableView)
        view.addSubview(downloadButton)
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Constants.downloadButtonHeight),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])
        NSLayoutConstraint.activate([
            downloadButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            downloadButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            downloadButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            downloadButton.heightAnchor.constraint(equalToConstant: Constants.downloadButtonHeight)
        ])
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])

    }
    
    @objc
    private func buttonDidTapped(_ sender: UIButton) {
        activityIndicator.startAnimating()
        dataSetDownloader?.execute { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let models):
                    self?.models = models
                case .failure(let error):
                    print("\(#function), dataSetDownloader?.execute failure with error: \(error.localizedDescription)")
                }
                self?.activityIndicator.stopAnimating()
            }
        }
    }

}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell!
        if let reusableCell = tableView.dequeueReusableCell(withIdentifier: Constants.deseaseCellIdentifier) {
            cell = reusableCell
        } else {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: Constants.deseaseCellIdentifier)
        }
        let model: DeseaseModel = models[indexPath.row]
        cell.textLabel?.text = "#\(indexPath.row)"
        cell.detailTextLabel?.text = "patientId: \(model.patientId) - finding: \(model.finding.map { $0.rawValue })"
        
        if let imageURL = model.imageURLs.first {
            cell.imageView?.image = UIImage(contentsOfFile: imageURL.path)
        } else {
            cell.imageView?.image = nil
        }
        return cell
    }
    
}

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
}
