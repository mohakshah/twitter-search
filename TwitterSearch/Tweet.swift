//
//  Tweet.swift
//  TwitterFW
//
//  Created by Mohak Shah on 01/02/17.
//  Copyright © 2017 Mohak Shah. All rights reserved.
//

import Foundation

class Tweet {
    let text: String
    let id: UInt64
    let date: Date
    let user: TwitterUser
    
    init(text: String, id: UInt64, date: Date, user: TwitterUser) {
        self.id = id
        self.text = text
        self.date = date
        self.user = user
    }
    
    static let twitterDateStringFormat = "EEE MMM dd HH:mm:ss xx yyyy"
    
    static func parseJSONResult(jsonResult: Data) -> [Tweet]? {
        // do something
        if let baseArray = (try? JSONSerialization.jsonObject(with: jsonResult,
                                                              options: [])) as? NSDictionary {
            if let statuses = baseArray["statuses"] as? NSArray {
                var tweets = [Tweet]()
                let df = DateFormatter()
                df.dateFormat = twitterDateStringFormat
                
                for status in statuses {
                    if let status = status as? NSDictionary {
                        
                        // extract info about each post
                        if let id = status["id"] as? NSNumber,
                            let text = status["text"] as? NSString,
                            let dateString = status["created_at"] as? NSString,
                            let date = df.date(from: String(dateString)),
                            let user = status["user"] as? NSDictionary
                        {
                            
                            // extract info about the user
                            if let uid = user["id"] as? NSNumber,
                                let name = user["name"] as? NSString,
                                let screenName = user["screen_name"] as? NSString,
                                let urlString = user["profile_image_url_https"] as? NSString,
                                let dpURL = URL(string: String(urlString))
                            {
                                let tUser = TwitterUser(id: UInt64(uid), name: String(name), screenName: String(screenName), dpURL: dpURL)
                                tweets.append(Tweet(text: String(text), id: UInt64(id), date: date, user: tUser))
                            } else {
                                print("Error extracting from the user object")
                                print(user)
                            }
                        } else {
                            print ("Error extracting from the status object: ")
                            print(status)
                        }
                    }
                }
                
                return tweets
            }
        }
        
        return nil
    }
}
