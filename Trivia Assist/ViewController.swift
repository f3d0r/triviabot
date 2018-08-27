//
//  ViewController.swift
//  Trivia Assist
//
//  Created by Fedor Paretsky on 4/2/18.
//  Copyright © 2018 f3d0r. All rights reserved.
//

import Cocoa
import Alamofire
import SwiftyJSON
import AppKit

let API_KEY = "SOME_API_KEY"
let SEARCH_API_KEY = "SOME_OTHER_API_KEY"

//Coordinates of parts of screen in format [x, y, width, height]
let questionCoords = [40, 170, 305, 150]
let optionOneCoords = [35, 325, 330, 57]
let optionTwoCoords = [35, 385, 330, 57]
let optionThreeCoords = [35, 443, 330, 57]

class ViewController: NSViewController {
    @IBOutlet weak var questionField: NSTextField!
    @IBOutlet weak var optionOneField: NSTextField!
    @IBOutlet weak var optionOneResultText: NSTextField!
    @IBOutlet weak var optionTwoField: NSTextField!
    @IBOutlet weak var optionTwoResultText: NSTextField!
    @IBOutlet weak var optionThreeField: NSTextField!
    @IBOutlet weak var optionThreeResultText: NSTextField!
    
    @IBOutlet weak var clearButton: NSButton!
    @IBOutlet weak var testConnectionButton: NSButton!
    @IBOutlet weak var saveCurrentButton: NSButton!
    
    @IBOutlet weak var statusLabel: NSTextField!
    
    @IBOutlet weak var justScanButton: NSButton!
    @IBOutlet weak var justAnalyzeButton: NSButton!
    @IBOutlet weak var scanAndAnalyzeButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        optionOneResultText.stringValue = "----"
        optionTwoResultText.stringValue = "----"
        optionThreeResultText.stringValue = "----"
    }
    
    override var representedObject: Any? {
        didSet {
        }
    }
    @IBAction func clearFields(_ sender: Any) {
        clearAll()
    }
    
    func clearAll() {
        questionField.stringValue = ""
        optionOneField.stringValue = ""
        optionTwoField.stringValue = ""
        optionThreeField.stringValue = ""
        optionOneResultText.stringValue = "----"
        optionTwoResultText.stringValue = "----"
        optionThreeResultText.stringValue = "----"
        optionOneResultText.textColor = NSColor.gray
        optionTwoResultText.textColor = NSColor.gray
        optionThreeResultText.textColor = NSColor.gray
    }
    
    @IBAction func testConnection(_ sender: Any) {
        Alamofire.request("https://httpbin.org/get").validate().responseJSON { response in
            switch response.result {
            case .success:
                self.testConnectionButton.title = "Status: OK"
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
                    self.testConnectionButton.title = "Test Connection (OK)"
                })
            case .failure:
                self.testConnectionButton.title = "Status: ERROR"
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
                    self.testConnectionButton.title = "Test Connection (ERROR)"
                })
            }
        }
    }
    
    @IBAction func saveCurrent(_ sender: Any) {
        
    }
    
    @IBAction func justScan(_ sender: Any) {
        clearAll()
        fillFields()
    }
    
    @IBAction func scanAndAnalyze(_ sender: Any) {
        findQuestion(formattedQuestion: questionField.stringValue, optionOne: optionOneField.stringValue, optionTwo: optionTwoField.stringValue, optionThree: optionThreeField.stringValue) { (optionOneCount, optionTwoCount, optionThreeCount) in
            let one = Int(optionOneCount)
            let two = Int(optionTwoCount)
            let three = Int(optionThreeCount)
            
            self.optionOneResultText.stringValue = String(one)
            self.optionTwoResultText.stringValue = String(two)
            self.optionThreeResultText.stringValue = String(three)
            
            var oneGreen = false
            var twoGreen = false
            var threeGreen = false
            if (one < two) {
                if (one < three) {
                    if (two < three) {
                        threeGreen = true
                    } else {
                        twoGreen = true
                        threeGreen = true
                    }
                } else {
                    twoGreen = true
                }
            } else {
                if (two < three) {
                    if (one < three) {
                        threeGreen = true
                    } else {
                        oneGreen = true
                        threeGreen = true
                    }
                } else {
                }
            }
            if (oneGreen) {
                self.optionOneResultText.textColor = NSColor.green
            } else {
                self.optionOneResultText.textColor = NSColor.red
            }
            
            if (twoGreen) {
                self.optionTwoResultText.textColor = NSColor.green
            } else {
                self.optionTwoResultText.textColor = NSColor.red
            }
            
            if (threeGreen) {
                self.optionThreeResultText.textColor = NSColor.green
            } else {
                self.optionThreeResultText.textColor = NSColor.red
            }
        }
    }
    
    func findQuestion(formattedQuestion: String, optionOne: String, optionTwo: String, optionThree: String, completionHandler: @escaping (Int, Int, Int) -> ()) {
        let url = "https://www.google.com/search?q=" + formattedQuestion.replacingOccurrences(of: " ", with: "+")
        
        if let finalURL = URL(string: url), NSWorkspace.shared.open(finalURL) {
            print("default browser was successfully opened")
        }
        Alamofire.request(url).responseString { response in
            let parsedString = (response.result.value!).replacingOccurrences(of: "<[^>]+>", with: "", options: String.CompareOptions.regularExpression, range: nil)
            completionHandler(self.substringCount(searchString: parsedString, searchTerm: optionOne), self.substringCount(searchString: parsedString, searchTerm: optionTwo), self.substringCount(searchString: parsedString, searchTerm: optionThree))
        }
    }
    
    
    func saveScreenShot(coords: [Int]) -> String {
        var displayCount: UInt32 = 0;
        let result = CGGetActiveDisplayList(0, nil, &displayCount)
        if (result != CGError.success) {
            print("error: \(result)")
        }
        let allocated = Int(displayCount)
        let activeDisplays = UnsafeMutablePointer<CGDirectDisplayID>.allocate(capacity: allocated)
        
        if (result != CGError.success) {
            print("error: \(result)")
        }
        
        let questionRect = CGRect(x: coords[0], y: coords[1], width: coords[2], height: coords[3])
        let questionScreenshot:CGImage = CGDisplayCreateImage(activeDisplays[Int(0)],rect: questionRect)!
        let questionBitmap = NSBitmapImageRep(cgImage: questionScreenshot)
        
        let data = questionBitmap.representation(using: NSBitmapImageRep.FileType.png, properties: [:])!
        return data.base64EncodedString();
    }
    
    func ocrImage(bitmap: String, completionHandler: @escaping (Bool, String?) -> ()) {
        var ocrText = String()
        let url = "https://vision.googleapis.com/v1/images:annotate?key=" + API_KEY
        let parameters: Parameters = [
            "requests": [
                "image": [
                    "content": bitmap
                ],
                "features": [
                    "type": "TEXT_DETECTION",
                ]
            ]
        ]
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
            switch response.result {
            case .success(let value):
                var json = JSON(value)
                ocrText = json["responses"][0]["fullTextAnnotation"]["text"].stringValue
                ocrText = ocrText.replacingOccurrences(of: "\n", with: " ")
                ocrText = ocrText.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
                completionHandler(true, ocrText)
            case .failure:
                completionHandler(false, nil)
            }
        }
    }
    
    func fillFields() {
        let questionBitmap = saveScreenShot(coords: questionCoords)
        ocrImage(bitmap: questionBitmap) { (success, ocrText) in
            if success {
                self.questionField.stringValue = self.phraseQuestion(question: String(ocrText!))
            } else {
                self.questionField.stringValue = "error"
            }
        }
        
        let optionOneBitmap = saveScreenShot(coords: optionOneCoords)
        ocrImage(bitmap: optionOneBitmap) { (success, ocrText) in
            if success {
                self.optionOneField.stringValue = String(ocrText!)
            } else {
                self.optionOneField.stringValue = "error"
            }
        }
        
        let optionTwoBitmap = saveScreenShot(coords: optionTwoCoords)
        ocrImage(bitmap: optionTwoBitmap) { (success, ocrText) in
            if success {
                self.optionTwoField.stringValue = String(ocrText!)
            } else {
                self.optionTwoField.stringValue = "error"
            }
        }
        
        let optionThreeBitmap = saveScreenShot(coords: optionThreeCoords)
        ocrImage(bitmap: optionThreeBitmap) { (success, ocrText) in
            if success {
                self.optionThreeField.stringValue = String(ocrText!)
            } else {
                self.optionThreeField.stringValue = "error"
            }
        }
    }
    
    func phraseQuestion(question: String) -> String {
        let stringToArray = question.components(separatedBy: " ")
        let wordsToRemove = ["what", "which", "is", "the", "a", "of", "these", "has", "are", "in", "for"]
        var finalString = ""
        for currentWord in stringToArray {
            var removed = false
            for removedWord in wordsToRemove {
                if(currentWord.caseInsensitiveCompare(removedWord) == ComparisonResult.orderedSame){
                    removed = true
                }
            }
            if (!removed) {
                finalString += (currentWord + " ")
            }
        }
        finalString = finalString.replacingOccurrences(of: "\"", with: "")
        finalString = finalString.replacingOccurrences(of: "?", with: "")
        return finalString.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
    }
    
    func substringCount(searchString: String, searchTerm: String) -> Int {
        let searchStringMutable = searchString.lowercased()
        let searchTermMutable = searchTerm.lowercased()
        
        let tok =  searchStringMutable.components(separatedBy:searchTermMutable)
        print(tok.count - 1)
        return tok.count - 1
    }
}

