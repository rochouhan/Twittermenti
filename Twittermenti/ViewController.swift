//
//  ViewController.swift
//  Twittermenti
//
//  Created by Angela Yu on 17/07/2018.
//  Copyright © 2018 London App Brewery. All rights reserved.
//

import UIKit
import SwifteriOS
import CoreML
import SwiftyJSON

class ViewController: UIViewController {
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sentimentLabel: UILabel!
    
    let sentimentClassifier = TweetSentimentClassifier()
    let tweetCount = 100
    // Instantiation using Twitter's OAuth Consumer Key and secret
    
    var swifter: Swifter?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let secrets = getPlist(withName: "Secrets") else {fatalError("There was an error with reading the API Keys")}
        
        swifter = Swifter(consumerKey: secrets["API Key"]!, consumerSecret: secrets["API Secret"]!)
        
    }

    @IBAction func predictPressed(_ sender: Any) {
        fetchTweets()
    
    }
    
    func getPlist(withName name: String) -> [String : String]? {
        if  let path = Bundle.main.path(forResource: name, ofType: "plist"),
            let xml = FileManager.default.contents(atPath: path)
        {
            return (try? PropertyListSerialization.propertyList(from: xml, options: .mutableContainersAndLeaves, format: nil)) as? [String : String]
        }
        
        return nil
    }
    
    func fetchTweets() {
        if let searchText = textField.text {
            swifter?.searchTweet(using: searchText, lang: "en", count: tweetCount, tweetMode: .extended, success: { (results, metadata) in
                var tweets = [TweetSentimentClassifierInput]()
                for i in 0..<self.tweetCount {
                    if let tweet = results[i]["full_text"].string {
                        let tweetForClassification = TweetSentimentClassifierInput(text: tweet)
                        tweets.append(tweetForClassification)
                    }
                }
                
                self.makePrediction(on: tweets)
                
                //            print(results)
            }, failure: { (error) in
                print("There was an error with Twitter API request, \(error)")
            })
        }
    }
    
    func makePrediction(on tweets: [TweetSentimentClassifierInput]) {
        do {
            let sentiments = try self.sentimentClassifier.predictions(inputs: tweets)
            var sentimentScore = 0
            for sent in sentiments {
                let sentiment = sent.label
                if sentiment == "Pos" {
                    sentimentScore += 1
                } else if sentiment == "Neg" {
                    sentimentScore -= 1
                }
            }
            print(sentimentScore)
            updateUI(sentimentScore)
        } catch {
            print(error)
        }
    }
    
    func updateUI(_ sentimentScore: Int) {
        if sentimentScore > 20 {
            self.sentimentLabel.text = "😍"
        } else if sentimentScore > 10 {
            self.sentimentLabel.text = "😀"
        } else if sentimentScore < -10 {
            self.sentimentLabel.text = "😒"
        } else if sentimentScore < -20 {
            self.sentimentLabel.text = "😡"
        } else {
            self.sentimentLabel.text = "😐"
        }
    }
    
}

