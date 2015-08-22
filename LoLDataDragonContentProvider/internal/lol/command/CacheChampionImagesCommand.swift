//
//  CacheChampionImagesCommand.swift
//  LoLDataDragonContentProvider
//
//  Created by Jeff Roberts on 8/15/15.
//  Copyright © 2015 nimbleNoggin.io. All rights reserved.
//

import Foundation
import Alamofire
import CocoaLumberjackSwift
import SwiftProtocolsCore

class CacheChampionImagesCommand : Command {
    private let completionQueue : dispatch_queue_t
    private let imageUrls : [String]
    
    init(imageUrls: [String], completionQueue : dispatch_queue_t) {
        self.imageUrls = imageUrls
        self.completionQueue = completionQueue
    }
    
    func execute() throws {
        var count = Int32(self.imageUrls.count)
        let cacheSemaphore : dispatch_semaphore_t = dispatch_semaphore_create(0)
        let before = NSDate()
        
        self.imageUrls.forEach() { url in
                DDLogVerbose("Caching image \(url)")
                Alamofire.request(Alamofire.Method.GET, url)
                    .response(queue: self.completionQueue, completionHandler: {(_, response, _, _) in
                        DDLogVerbose("Got response code \(response?.statusCode) for \(url)")
                        OSAtomicDecrement32(&count)
                        dispatch_semaphore_signal(cacheSemaphore)
                    })
        }
    
        while count > 0 {
            DDLogVerbose("Caching images, \(count) images remain")
            dispatch_semaphore_wait(cacheSemaphore, DISPATCH_TIME_FOREVER)
        }

        DDLogVerbose("It took \(NSDate().timeIntervalSinceDate(before)) to cache images")
    }
}

