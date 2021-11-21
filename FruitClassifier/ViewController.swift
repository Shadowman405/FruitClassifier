//
//  ViewController.swift
//  FruitClassifier
//
//  Created by Maxim Mitin on 21.11.21.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var classificationLbl: UILabel!
    
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: FruitClassifier().model)
            let request = VNCoreMLRequest(model: model) { request, error in
                self.processClassifications(for: request, error: error)
            }
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to load coreml model: \(error)")
        }
    }()

    func processClassifications(for reqest: VNRequest, error: Error?) {
        guard let classifications = reqest.results as? [VNClassificationObservation] else {
            self.classificationLbl.text = "Unable to classify image.\n\(error?.localizedDescription ?? "error")"
            return
        }
        
        if classifications.isEmpty {
            self.classificationLbl.text = "Nothing recognized. \nPlease try again"
        } else {
            let topClassifications = classifications.prefix(2)
            let descriptions = topClassifications.map { classification in
                return String(format: "%.2f", classification.confidence * 100) + "% - " + classification.identifier
            }
            
            self.classificationLbl.text = "Classifications:\n" + descriptions.joined(separator: "\n")
        }
    }
    
    func updateClassifications(for image: UIImage) {
        classificationLbl.text = "Classifying....."
        
        guard let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue)),
              let ciImage = CIImage(image: image)  else {
            print("Something went wrong")
            return
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
        do {
            try handler.perform([classificationRequest])
        } catch {
            print("Failed to perform classification")
        }
        
    }

    @IBAction func cameraBtnPressed(_ sender: Any) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            presentPhotoPicker(sourceType: .photoLibrary)
            return
        }
        
        let photoSourcePicker = UIAlertController()
        let takePhotoAction = UIAlertAction(title: "Take photo", style: .default) { _ in
            self.presentPhotoPicker(sourceType: .camera)
        }
        let choosePhotoAction = UIAlertAction(title: "Choose photo", style: .default) { _ in
            self.presentPhotoPicker(sourceType: .photoLibrary)
        }
        
        photoSourcePicker.addAction(takePhotoAction)
        photoSourcePicker.addAction(choosePhotoAction)
        photoSourcePicker.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(photoSourcePicker, animated: true, completion: nil)
    }
    
    func presentPhotoPicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {return}
        imgView.image = image
        updateClassifications(for: image)
    }
    
}

