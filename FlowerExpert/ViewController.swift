//
//  ViewController.swift
//  FlowerExpert
//
//  Created by djeetee on 2018-04-11.
//  Copyright © 2018 Crash Test Apps Inc. All rights reserved.
//

import UIKit
import CoreML
import Vision


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var pickedImageView: UIImageView!
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true    // allow the user to edit the photo
        imagePicker.sourceType = .camera
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // grab what the snapped pic
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {

            // convert the image to CIImage format
            guard let ciImage = CIImage(image: pickedImage) else {
                fatalError("Error while converting the image to CIImage")
            }
            
            // find out what it is
            classifyImage(image: ciImage)
            
            // load it into the image view
            pickedImageView.image = pickedImage

        }
        
        // bye bye picker
        imagePicker.dismiss(animated: true, completion: nil)

    }
    
    // called with the image to classify
    func classifyImage(image: CIImage) {
        // Init the model
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Unable to intialize the CoreML model")
        }
        
        // create a request and the completion handler
        let classRequest = VNCoreMLRequest(model: model) { (request, error) in
            // Completion handler
            let flowerClassification = request.results?.first as? VNClassificationObservation
            
            // set the title bar to the classification result
            self.navigationItem.title = flowerClassification?.identifier.capitalized
        }
        
        // create the request handler
        let handler = VNImageRequestHandler(ciImage: image)
        
        // classify and catch errors
        do {
            try handler.perform([classRequest])
        } catch {
            print(error)
        }
        
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func cameraButtonTapped(_ sender: Any) {
        present(imagePicker, animated: true, completion: nil)
    }
    
}

