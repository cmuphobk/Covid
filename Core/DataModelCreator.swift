//
//  DataModelCreator.swift
//  CovidMacOS
//
//  Created by ksmirnov on 04.04.2020.
//  Copyright © 2020 ksmirnov. All rights reserved.
//

import Foundation
import CreateML

final class DataModelCreator {
    
    private let imageClassifier: MLImageClassifier
    // let customFeatureExtractor = MLImageClassifier.CustomFeatureExtractor(modelPath: )
    
    init(models: [DeseaseModel], to url: URL, pretrainedModelURL: URL? = nil) throws {
        
        var groupedDeseases: [DeseaseModel.Desease: [DeseaseModel]] = [:]
        var groupedImageURLs: [String: [URL]] = [:]
        
        for desease in DeseaseModel.Desease.allCases {
            let modelsWithDesease = models.filter { $0.finding == desease }
            groupedDeseases[desease] = modelsWithDesease
        }
        for (key, value) in groupedDeseases {
            groupedImageURLs[key.rawValue] = value.compactMap { $0.imageURL }
        }
        
        let featureExtractorType: MLImageClassifier.FeatureExtractorType!
        if let pretrainedModelURL = pretrainedModelURL {
            let featureExtractor: MLImageClassifier.CustomFeatureExtractor = MLImageClassifier.CustomFeatureExtractor(modelPath: pretrainedModelURL)
            featureExtractorType = .custom(featureExtractor)
        } else {
            featureExtractorType = .scenePrint(revision: nil)
        }
        
        let parameters = MLImageClassifier.ModelParameters(
            featureExtractor: featureExtractorType,
            validation: .none,
            maxIterations: 10,
            augmentationOptions: []
        )
        
        imageClassifier = try MLImageClassifier(trainingData: groupedImageURLs, parameters: parameters)
        try imageClassifier.write(to: url)
    }
    
    init(trainingDir: URL, to url: URL, pretrainedModelURL: URL? = nil) throws {
        let featureExtractorType: MLImageClassifier.FeatureExtractorType!
        if let pretrainedModelURL = pretrainedModelURL {
            let featureExtractor: MLImageClassifier.CustomFeatureExtractor = MLImageClassifier.CustomFeatureExtractor(modelPath: pretrainedModelURL)
            featureExtractorType = .custom(featureExtractor)
        } else {
            featureExtractorType = .scenePrint(revision: nil)
        }
        
        let parameters = MLImageClassifier.ModelParameters(
            featureExtractor: featureExtractorType,
            validation: .none,
            maxIterations: 10,
            augmentationOptions: []
        )
        
        imageClassifier = try MLImageClassifier(trainingData: .labeledDirectories(at: trainingDir), parameters: parameters)
        try imageClassifier.write(to: url)
        
    }
    
    func evaluation(with folder: URL) -> MLClassifierMetrics {
        let dataSource: MLImageClassifier.DataSource = .labeledDirectories(at: folder)
        return imageClassifier.evaluation(on: dataSource)
    }
    
    func prediction(from url: URL) throws -> String {
        return try imageClassifier.prediction(from: url)
    }
}

extension DataModelCreator: CustomStringConvertible {
    
    var description: String {
        var message = imageClassifier.description
        message += "\n\(imageClassifier.trainingMetrics.description)"
        message += "\n\(imageClassifier.validationMetrics.description)"
        return message
    }
    
}

