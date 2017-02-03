//
//  TwitterUser.swift
//  TwitterFW
//
//  Created by Mohak Shah on 01/02/17.
//  Copyright © 2017 Mohak Shah. All rights reserved.
//

import Foundation

class TwitterUser {
    let id: UInt64
    let name: String
    let screenName: String
    let dpURL: URL
    
    init(id: UInt64, name: String, screenName: String, dpURL: URL) {
        self.id = id
        self.name = name
        self.screenName = screenName
        self.dpURL = dpURL
    }
}
