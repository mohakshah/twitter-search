//
//  TweetCell.swift
//  TwitterSearch
//
//  Created by Mohak Shah on 03/02/17.
//  Copyright © 2017 Mohak Shah. All rights reserved.
//

import UIKit
import Foundation

class TweetCell: UITableViewCell {
    
    static let dpCache = NSCache<AnyObject, AnyObject>()

    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var body: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var dp: UIImageView!
    
    // set this to the URL of the dp to asynchronously download and display the dp
    var dpURL: URL? {
        didSet {
            dp.image = nil
            if let url = dpURL {
                 DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async { [weak weakSelf = self] in
                    if let image = TweetCell.dpCache.object(forKey: url as AnyObject) as? UIImage {
                        weakSelf?.dp.image = image
                    } else if let imageData = try? Data(contentsOf: url) {
                        if let image = UIImage(data: imageData) {
                            
                            DispatchQueue.main.async {
                                weakSelf?.dp.image = image
                            }
                            
                            TweetCell.dpCache.setObject(image, forKey: url as AnyObject, cost: imageData.count)
                        }
                    } else {
                        print("Couldn't Download \(url)")
                    }
                }
            }
        }
    }
    
    
    
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        // Initialization code
//    }
//
//    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//
//        // Configure the view for the selected state
//    }

}
