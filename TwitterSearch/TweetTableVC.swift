//
//  TweetTableVC.swift
//  TwitterSearch
//
//  Created by Mohak Shah on 03/02/17.
//  Copyright © 2017 Mohak Shah. All rights reserved.
//

import UIKit

class TweetTableVC: UITableViewController, UISearchBarDelegate {
    
    // constants that will be used throughout this class
    struct Constants {
        static let SearchCount = UInt(100)
        static let MaxResultsOnDisplay = 500
        static let SecondsInADay: Double = 60 * 60 * 24
        static let RefreshInterval = 5.0
        
        static let MessageDuringSearch = " Searching... "
        static let MessageDuringRefresh = " Refreshing... "
    }

    @IBOutlet weak var searchBox: UISearchBar! {
        didSet {
            searchBox.delegate = self
        }
    }
    
    
    // MARK: - UISearchBarDelegate methods
    
    // The function only searches when the string in the searchbar 
    // is not empty. It also prepends a "#" to the search term 
    // if it's missing
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        if let searchText = searchBar.text {
            if !searchText.isEmpty {
                if searchText.characters.first != "#" {
                    searchString = "#" + searchText
                } else {
                    searchString = searchText
                }
            }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    
    // MARK: - Search
    var timer: Timer?
    
    // setting this initiates the twitter search as well as
    // triggering the "refresh timer"
    var searchString: String? {
        didSet {
            timer?.invalidate()
            tweets.removeAll()
            if let ss = searchString {
                navigationItem.title = ss
                twitterRequest = Request(searchString: ss, count: Constants.SearchCount)
                timer = newTimer()
                search()
            }
        }
    }
    
    // Returns a new timer initialized to repeatedly call refresh()
    // at Constants.RefreshInterval seconds
    func newTimer() -> Timer {
        return Timer.scheduledTimer(timeInterval: Constants.RefreshInterval,
                                    target: self,
                                    selector: #selector(refresh),
                                    userInfo: nil,
                                    repeats: true)
    }
    
    var twitterRequest: Request?
    
    // call when new search is started
    func search() {
        statusLabel.text = Constants.MessageDuringSearch
        statusLabel.isHidden = false
        updateResults()
    }
    
    // call when the tweets only need to be updated
    func refresh() {
        statusLabel.text = Constants.MessageDuringRefresh
        statusLabel.isHidden = false
        updateResults()
    }
    
    // This function fetches the results of the twitter request
    // and calls insertTweets if it receives a positive no. of tweets
    func updateResults() {
        twitterRequest?.fetchResults { [weak weakSelf = self, lastSearch = searchString] (tweets) in
            DispatchQueue.main.async {
                
                // make sure the search string hasn't changed
                if lastSearch == weakSelf?.searchString {
                    if !tweets.isEmpty {
                        weakSelf?.insertTweets(newTweets: tweets)
                    }
                    
                    weakSelf?.statusLabel.isHidden = true
                }
            }
        }
    }
    
    // This function inserts tweets into the model and decides
    // when to animate this action and when not to
    func insertTweets(newTweets: [Tweet]) {
        tweets.insert(contentsOf: newTweets, at: 0)
        
        // only animate if there were previous tweets
        if tweets.count > newTweets.count {
            // create an [IndexPath] for newTweets
            var insertIndexPaths = [IndexPath]()
            for i in 0..<newTweets.count {
                insertIndexPaths.append(IndexPath(row: i, section: 0))
            }
            
            // also check if there is need for deletion
            var deletedIndexPaths = [IndexPath]()
            if tweets.count > Constants.MaxResultsOnDisplay {
                // create an [IndexPath] for the deletedTweets
                for i in Constants.MaxResultsOnDisplay..<tweets.count {
                    deletedIndexPaths.append(IndexPath(row: i - newTweets.count, section: 0))
                }
                
                tweets.removeLast(tweets.count - Constants.MaxResultsOnDisplay)
            }
            
            // update the table with animation
            tableView.beginUpdates()
            tableView.deleteRows(at: deletedIndexPaths, with: UITableViewRowAnimation.automatic)
            tableView.insertRows(at: insertIndexPaths, with: UITableViewRowAnimation.automatic)
            tableView.endUpdates()
        } else {
            tableView.reloadData()
        }
    }
    
    // MARK: - Model
    
    // Do not add tweets directly. Use insertTweets()
    // although, it's ok to remove all it's tweets.
    // This will reload the table to an empty state.
    var tweets = [Tweet]() {
        didSet {
            if tweets.isEmpty {
                tableView.reloadData()
            }
            
            print("Tweet count: \(tweets.count)")
        }
    }
    
    // MARK: - Table view
    let statusLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set row height to be dynamic
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        
        if let navController = navigationController {
            // make the toolbar transparent
            navController.toolbar.isTranslucent = true
            navController.toolbar.setShadowImage(UIImage(), forToolbarPosition: .bottom)
            navController.toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .bottom, barMetrics: .default)
            
            setupStatusLabel()
            
            // calculate the status label's position w.r.t. the toolbar
            let toolbarFrame = navController.toolbar.frame
            
            statusLabel.text = Constants.MessageDuringRefresh
            let statusRect = statusLabel.textRect(forBounds: toolbarFrame, limitedToNumberOfLines: 1)
            statusLabel.frame = CGRect(x: (toolbarFrame.width - statusRect.width) / 2,
                                       y: (toolbarFrame.height - statusRect.height) / 2,
                                       width: statusRect.width,
                                       height: statusRect.height)
            
            
            // add the status label to the toolbar
            let statusIndicator = UIBarButtonItem(customView: statusLabel)
            let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            toolbarItems = [flexibleSpace, statusIndicator, flexibleSpace]
            navController.isToolbarHidden = false
        }
    }
    
    // Sets up the status label's properties like the
    // font, color, et. al.
    func setupStatusLabel() {
        statusLabel.isHidden = true
        statusLabel.isHighlighted = true
        
        statusLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        statusLabel.backgroundColor = UIColor.darkGray.withAlphaComponent(0.8)
        statusLabel.textColor = UIColor.white
        
        // make the corners of the label rounded
        statusLabel.layer.cornerRadius = 5.0
        statusLabel.layer.masksToBounds = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        TweetCell.dpCache.removeAllObjects()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweets.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TweetCell", for: indexPath)

        // Configure the cell...
        if let tweetCell = cell as? TweetCell {
            let tweet = tweets[indexPath.row]
            tweetCell.body.text = tweet.text
            tweetCell.username.text = "\(tweet.user.name) (@\(tweet.user.screenName))"
            tweetCell.time.text = formatTweetTime(tweetDate: tweet.date)
            tweetCell.dpURL = tweet.user.dpURL
        }
        
        return cell
    }
    
    // MARK: - Miscellaneous
    
    // Returns a short string appropriate to represent
    // a tweet's date. If the date is less than an day
    // old, only the time is returned. If it's more than
    // a day old, only the date is returned.
    func formatTweetTime(tweetDate td: Date) -> String {
        let df = DateFormatter()
        
        let secondsPassed = Double(td.timeIntervalSinceNow) * -1.0

        if (secondsPassed < Constants.SecondsInADay) {
            df.dateFormat = "h:mm a"
        } else {
            df.dateFormat = "dd/MM/yy"
        }
        
        return df.string(from: td)
    }

}
