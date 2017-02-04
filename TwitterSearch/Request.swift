//
//  Request.swift
//  TwitterFW
//
//  Created by Mohak Shah on 01/02/17.
//  Copyright © 2017 Mohak Shah. All rights reserved.
//

import Foundation
import Social
import Accounts

class Request {
    private var searchParameters = [String : String]()
    private var latestTweetId: UInt64?
    
    private let requestURL = URL(string: "https://api.twitter.com/1.1/search/tweets.json")
    
    private let semaphore = DispatchSemaphore(value: 0)
    
    private var results: Data?
    
    init(searchString: String, count: UInt) {
        searchParameters["q"] = searchString
        searchParameters["count"] = "\(count)"
        searchParameters["include_entities"] = "0"
        acType = acStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)
    }
    
    func fetchResults(successClosure: (([Tweet]) -> Void)?) -> Void {
        // everything should happen in the background queue
        DispatchQueue.global(qos: .userInitiated).async { [weak weakSelf = self] in
            // first make sure that the twitter account is available on the device
            guard let twitterAccount = weakSelf?.twitterAccount else {
                print("Could not get a twitter account.")
                return
            }
            
            // initialize an SLRequest object
            guard let requestURL = weakSelf?.requestURL, var searchParameters = weakSelf?.searchParameters else {
                print("The object has been probably released.")
                return
            }
            
            if let sinceId = weakSelf?.latestTweetId {
                searchParameters["since_id"] = "\(sinceId)"
            }
            
            guard let slrequest = SLRequest(forServiceType: SLServiceTypeTwitter,
                                            requestMethod: SLRequestMethod.GET,
                                            url: requestURL,
                                            parameters: searchParameters) else {
                print("There was an error trying to create SLRequest object.")
                return
            }
            
            slrequest.account = twitterAccount
            
            guard let urlRequest = slrequest.preparedURLRequest() else {
                print("SLRequest object could not return a URLRequest")
                return
            }
            
            // start an ephemeral URLSession
            let ephemeralConfig = URLSessionConfiguration.ephemeral
            let ephemeralSession = URLSession(configuration: ephemeralConfig)
            
            // download the results from twitter
            (ephemeralSession.dataTask(with: urlRequest) { (data, response, error) in
                if let error = error {
                    print("Error downloading from twitter: \(error)")
                }
                
                weakSelf?.results = data
                weakSelf?.semaphore.signal()
            }).resume()
            
            // wait for the download to complete
            weakSelf?.semaphore.wait()
            
            
            guard let results = weakSelf?.results, let tweets = Tweet.parseJSONResult(jsonResult: results) else {
                return
            }
            
            if let latestTweet = tweets.first {
                weakSelf?.latestTweetId = latestTweet.id
            }
                
            successClosure?(tweets)
        }
        
        
        
    }
    
    private let acStore = ACAccountStore()
    private let acType: ACAccountType
    
    private var _twitterAccount: ACAccount?
    
    var twitterAccount: ACAccount? {
        get {
            if let ta = _twitterAccount {
                return ta
            } else {
                acStore.requestAccessToAccounts(with: acType, options: nil) { [weak weakSelf = self] (success, error) in
                    if success {
                        weakSelf?._twitterAccount = weakSelf?.acStore.accounts(with: weakSelf?.acType)?.first as! ACAccount?
                    } else {
                        print("Error accessing the twitter account: ")
                        print(error ?? "Unknown error")
                    }
                    
                    weakSelf?.semaphore.signal()
                }
                
                _ = semaphore.wait(timeout: DispatchTime.distantFuture)
                return _twitterAccount
            }
        }
    }
}
