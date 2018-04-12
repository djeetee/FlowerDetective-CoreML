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


struct WikipediaData: Codable {
    let batchComplete: String
    let query: Query

    enum CodingKeys : String, CodingKey {
        case batchComplete = "batchcomplete"
        case query
    }
}

struct Query: Codable {
    let pageIds: [String]
    let pages: [String : Page]
    
    enum CodingKeys : String, CodingKey {
        case pageIds = "pageids"
        case pages
    }
}
    
struct Page: Codable {
    let pageId: Int
    let ns: Int
    let title: String
    let extract: String
    
    enum CodingKeys : String, CodingKey {
        case pageId = "pageid"
        case ns
        case title
        case extract
    }
}

/*
 Sample JSON returned by Wikipedia
 
{
    "batchcomplete": "",
    "query": {
        "pageids": [
        "143540"
        ],
        "pages": {
            "143540": {
                "pageid": 143540,
                "ns": 0,
                "title": "Poinsettia",
                "extract": "The poinsettia ( or ) (Euphorbia pulcherrima) is a commercially important plant species of the diverse spurge family (Euphorbiaceae). The species is indigenous to Mexico. It is particularly well known for its red and green foliage and is widely used in Christmas floral displays. It derives its common English name from Joel Roberts Poinsett, the first United States Minister to Mexico, who introduced the plant to the US in 1825."
            }
        }
    }
}

*/
 
class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var pickedImageView: UIImageView!
    @IBOutlet weak var flowerLabel: UILabel!
    @IBOutlet weak var flowerDescription: UILabel!
    
   
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
    
    func uiUpdateLabels(label: String, extract: String) {
        self.flowerLabel.text = label
        self.flowerDescription.text  = extract
    }
    
    
    // called with the image to classify
    func classifyImage(image: CIImage) {
        // Init the model
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Unable to intialize the CoreML model")
        }
        
        // create a request and the completion handler
        let classRequest = VNCoreMLRequest(model: model) { (request, error) in
            // CoreML model completion handler
            let flowerClassification = request.results?.first as? VNClassificationObservation
            
            let flowerName = (flowerClassification?.identifier.capitalized)!
            
            // set the title bar to the classification result
            self.flowerLabel.text = flowerName
            
            let extract = self.getWikipediaInfo(flowerName: flowerName)
            self.flowerDescription.text = extract
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
    
    func getWikipediaInfo(flowerName: String) -> String {
        var extract: String = "N/A"
        
        let wikipediaURl = "https://en.wikipedia.org/w/api.php?"
        let urlParameters = "format=json&" +
                            "action=query&" +
                            "prop=extracts&" +
                            "exintro=&" +
                            "explaintext=&" +
                            "titles=" + flowerName.replacingOccurrences(of: " ", with: "%20") + "&" +
                            "indexpageids=&" +
                            "redirects=1"
  
        guard let url = URL(string: wikipediaURl + urlParameters) else {
            return extract
        }
        
        // calling Wikipedia... (synchronously using semaphores to simplify things)
        let semaphore = DispatchSemaphore(value: 0)

        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            // network call completetion handler
            
            // was there an error?
            if error != nil {
                print("Response: \(error!)")
                return
            }
            
            // got data?
            guard let data = data else {
                return
            }
            
            // decode the data
            do {
                let decoder = JSONDecoder()
                let wikipediaData = try decoder.decode(WikipediaData.self, from: data)
                
                // key to the first (only) page that contains the desciption
                let pageID = wikipediaData.query.pageIds.first!
                let wikiDesc = (wikipediaData.query.pages[pageID]?.extract)!

                extract = wikiDesc
                
                // release
                semaphore.signal()


            } catch {
                print("Decoding: \(error)")     // something went wrong while decoding
            }
        }

        // run the task
        task.resume()
        
        // wait for the network call and data parsing to be completed
        semaphore.wait()
        
        return extract
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func cameraButtonTapped(_ sender: Any) {
        present(imagePicker, animated: true, completion: nil)
    }
    
}

