//
//  DataSetDownloader.swift
//  Covid
//
//  Created by ksmirnov on 03.04.2020.
//  Copyright © 2020 ksmirnov. All rights reserved.
//

import Foundation
import SwiftCSV

struct FileRequest: NetworkRequest {
    var path: String
    var method: HTTPMethod = .get
    var parameters: Parameters? = [:]
    var headers: [String : String]? = [:]
    var encoding: ParameterEncoding = URLEncoding.default
    
    init(path: String) {
        self.path = path
    }
}

struct File: Codable {
    let data: Data
}

enum DeseaseModelHeader: String, CaseIterable {
    case patientId = "patientid"
    case offset = "offset"
    case sex = "sex"
    case age = "age"
    case finding = "finding"
    case survival = "survival"
    case intubated = "intubated"
    case wentIcu = "went_icu"
    case neededSupplementalO2 = "needed_supplemental_O2"
    case extubated = "extubated"
    case temperature = "temperature"
    case pO2Saturation = "pO2_saturation"
    case leukocyteCount = "leukocyte_count"
    case neutrophilCount = "neutrophil_count"
    case lymphocyteCount = "lymphocyte_count"
    case view = "view"
    case modality = "modality"
    case date = "date"
    case location = "location"
    case folder = "folder"
    case filename = "filename"
    case doi = "doi"
    case url = "url"
    case license = "license"
    case clinicalNotes = "clinical_notes"
    case otherNotes = "other_notes"
}

struct DeseaseModel {
    
    enum YesOrNo: String {
        case yes = "Y"
        case no = "N"
    }
    
    enum Sex: String {
        case male = "M"
        case female = "F"
    }
    
    enum Desease: String, CaseIterable, Equatable {
        case covid19 = "COVID-19"
        case noFinding = "No Finding"
        case other = "Other"

        init(findingValue: String) {
            switch findingValue {
            case "Pneumonia/Viral/COVID-19":
                self = .covid19
            case "No Finding":
                self = .noFinding
            default:
                self = .other
            }
        }
    }
    
    enum View: String {
        case posteroanterior = "PA"
        case anteroposterior = "AP"
        case apSupine = "AP Supine"
        case lateral = "L"
        
        case axial = "Axial"
        case coronal = "Coronal"
    }
    
    enum Modality: String {
        case ct = "CT"
        case xRay = "X-ray"
    }
    
    let patientId: String
    let offset: Int?
    let sex: Sex?
    let age: Int?
    let finding: Desease
    let survival: YesOrNo?
    let intubated: YesOrNo?
    let temperature: Double?
    let pO2Saturation: Double?
    let leukocyteCount: Double?
    let neutrophilCount: Double?
    let lymphocyteCount: Double?
    let view: View
    let modality: Modality
    let date: String
    let location: String
    let folder: String
    let filename: String
    let doi: String
    let url: String
    let license: String
    let clinicalNotes: String
    
}

extension DeseaseModel: CustomStringConvertible {
    
    var description: String {
        var description: String = "patientId: [\(patientId)] \n"
        description += "offset: [\(offset ?? -1)] \n"
        description += "sex: [\(sex?.rawValue ?? "_")] \n"
        description += "age: [\(age ?? -1)] \n"
        description += "finding: [\(finding.rawValue)] \n"
        description += "survival: [\(survival?.rawValue ?? "_")] \n"
        description += "intubated: [\(intubated?.rawValue ?? "_")] \n"
        description += "temperature: [\(temperature ?? -1)] \n"
        description += "pO2Saturation: [\(pO2Saturation ?? -1)] \n"
        description += "leukocyteCount: [\(leukocyteCount ?? -1)] \n"
        description += "neutrophilCount: [\(neutrophilCount ?? -1)] \n"
        description += "lymphocyteCount: [\(lymphocyteCount ?? -1)] \n"
        description += "view: [\(view.rawValue)] \n"
        description += "modality: [\(modality.rawValue)] \n"
        description += "date: [\(date)] \n"
        description += "location: [\(location)]\n"
        description += "folder: [\(folder)] \n"
        description += "filename: [\(filename)] \n"
        description += "doi: [\(doi)] \n"
        description += "url: [\(url)] \n"
        description += "license: [\(license)] \n"
        description += "clinicalNotes: [\(clinicalNotes)] \n"
        return description
    }
    
}

extension DeseaseModel {
    
    static var folder: URL? {
        guard let documentsURL = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
            return nil
        }
        return documentsURL.appendingPathComponent("DataSet")
    }
    
    static func folderName(for desease: Desease) -> String {
        let folderName: String!
        if desease == .covid19 || desease == .noFinding {
            folderName = desease.rawValue
        } else {
            folderName = "others"
        }
        return folderName
    }
    
    var imageURL: URL? {
        return DeseaseModel.folder?.appendingPathComponent(DeseaseModel.folderName(for: finding)).appendingPathComponent(filename)
    }
}

final class DataSetDownloader {
    
    enum DataSetDownloaderError: Error {
        case unknown
    }
    
    enum Constants {
        static let basePath = "https://raw.githubusercontent.com/ieee8023/covid-chestxray-dataset/master/"
        static let csvName = "metadata.csv"
    }
    
    private let baseURL: URL
    private let networkService: NetworkService
    private let fileManager: FileManager = FileManager.default
    
    init?() {
        guard let baseURL: URL = URL(string: Constants.basePath) else { return nil }
        self.baseURL = baseURL
        self.networkService = NetworkService(baseURL: baseURL)
    }

    func execute(_ completion: @escaping (Result<[DeseaseModel], Error>) -> Void) {
        let fileRequest = FileRequest(path: Constants.csvName)
        let documentURL: URL?
        do {
            documentURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(Constants.csvName)
        } catch {
            completion(.failure(error))
            return
        }
        guard let documentURLUnwrapped = documentURL else {
            completion(.failure(DataSetDownloaderError.unknown))
            return
        }
        networkService.download(fileRequest, to: documentURLUnwrapped) { result in
            switch result {
            case .success(let url):
                var csv: CSV!
                do {
                    csv = try CSV(url: url)
                } catch {
                    completion(.failure(error))
                    return
                }
                let models = csv.namedRows.compactMap { el in
                    return self.makeDeseaseModel(from: el)
                }
                let dispatchQueue = DispatchQueue(label: "image_downloading_queue", qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
                let queue = OperationQueue()
                queue.underlyingQueue = dispatchQueue
                queue.maxConcurrentOperationCount = 10
                let filtered = models.filter { $0.folder == "images" }
                for model in filtered  {
                    let op = BlockOperation(block: {
                        let mutex = DispatchSemaphore(value: 0)
                        self.downloadImage(for: model) { _ in
                            mutex.signal()
                        }
                        mutex.wait()
                    })
                    op.completionBlock = {
                        if queue.operations.isEmpty {
                            DispatchQueue.main.async {
                                completion(.success(models))
                            }
                        }
                    }
                    queue.addOperation(op)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func makeDeseaseModel(from dictionary: [String: String]) -> DeseaseModel? {
        let patientId: String = dictionary[DeseaseModelHeader.patientId.rawValue] ?? ""
        guard let offsetValue: String = dictionary[DeseaseModelHeader.offset.rawValue] else { return nil }
        let offset: Int? = Int(offsetValue)
        guard let sexValue: String = dictionary[DeseaseModelHeader.sex.rawValue] else { return nil }
        let sex: DeseaseModel.Sex? = DeseaseModel.Sex(rawValue: sexValue)
        guard let ageValue: String = dictionary[DeseaseModelHeader.age.rawValue] else { return nil }
        let age: Int? = Int(ageValue)
        guard let findingValue: String = dictionary[DeseaseModelHeader.finding.rawValue] else { return nil }
        let finding: DeseaseModel.Desease = DeseaseModel.Desease(findingValue: findingValue)
        guard let survivalValue: String = dictionary[DeseaseModelHeader.survival.rawValue] else { return nil }
        let survival: DeseaseModel.YesOrNo? = DeseaseModel.YesOrNo(rawValue: survivalValue)
        guard let intubatedValue: String = dictionary[DeseaseModelHeader.intubated.rawValue] else { return nil }
        let intubated: DeseaseModel.YesOrNo? = DeseaseModel.YesOrNo(rawValue: intubatedValue)
        guard let temperatureValue: String = dictionary[DeseaseModelHeader.temperature.rawValue] else { return nil }
        let temperature: Double? = Double(temperatureValue)
        guard let pO2SaturationValue: String = dictionary[DeseaseModelHeader.pO2Saturation.rawValue] else { return nil }
        let pO2Saturation: Double? = Double(pO2SaturationValue)
        guard let leukocyteCountValue: String = dictionary[DeseaseModelHeader.leukocyteCount.rawValue] else { return nil }
        let leukocyteCount: Double? = Double(leukocyteCountValue)
        guard let neutrophilCountValue: String = dictionary[DeseaseModelHeader.neutrophilCount.rawValue] else { return nil }
        let neutrophilCount: Double? = Double(neutrophilCountValue)
        guard let lymphocyteCountValue: String = dictionary[DeseaseModelHeader.lymphocyteCount.rawValue] else { return nil }
        let lymphocyteCount: Double? = Double(lymphocyteCountValue)
        guard let viewValue: String = dictionary[DeseaseModelHeader.view.rawValue] else { return nil }
        guard let view: DeseaseModel.View = DeseaseModel.View(rawValue: viewValue) else { return nil }
        guard let modalityValue: String = dictionary[DeseaseModelHeader.modality.rawValue] else { return nil }
        guard let modality: DeseaseModel.Modality = DeseaseModel.Modality(rawValue: modalityValue) else { return nil }
        let date: String = dictionary[DeseaseModelHeader.date.rawValue] ?? ""
        let location: String = dictionary[DeseaseModelHeader.location.rawValue] ?? ""
        let folder: String = dictionary[DeseaseModelHeader.folder.rawValue] ?? ""
        let filename: String = (dictionary[DeseaseModelHeader.filename.rawValue] ?? "").trimmingCharacters(in: .whitespaces)
        let doi: String = dictionary[DeseaseModelHeader.doi.rawValue] ?? ""
        let url: String = dictionary[DeseaseModelHeader.url.rawValue] ?? ""
        let license: String = dictionary[DeseaseModelHeader.license.rawValue] ?? ""
        let clinicalNotes: String = dictionary[DeseaseModelHeader.clinicalNotes.rawValue] ?? ""
        
        let model = DeseaseModel(
            patientId: patientId,
            offset: offset,
            sex: sex,
            age: age,
            finding: finding,
            survival: survival,
            intubated: intubated,
            temperature: temperature,
            pO2Saturation: pO2Saturation,
            leukocyteCount: leukocyteCount,
            neutrophilCount: neutrophilCount,
            lymphocyteCount: lymphocyteCount,
            view: view,
            modality: modality,
            date: date,
            location: location,
            folder: folder,
            filename: filename,
            doi: doi,
            url: url,
            license: license,
            clinicalNotes: clinicalNotes
        )
        return model
    }
    
    private func downloadImage(for model: DeseaseModel, completion: @escaping (Bool) -> Void) {
        let fileRequest = FileRequest(path: "\(model.folder)/\(model.filename)")

        guard let imageURL = model.imageURL else {
            completion(true)
            return
        }
        
        networkService.download(fileRequest, to: imageURL) { result in
            switch result {
            case .success:
                completion(true)
            case .failure(let error):
                print("\(#function), networkService.download failure with error: \n \(error.localizedDescription)")
                completion(false)
            }
        }
    }
}
