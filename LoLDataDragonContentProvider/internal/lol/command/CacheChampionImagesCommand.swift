//
//  CacheChampionImagesCommand.swift
//  LoLDataDragonContentProvider
//
//  Created by Jeff Roberts on 8/15/15.
//  Copyright © 2015 nimbleNoggin.io. All rights reserved.
//

import Foundation
import Alamofire
import SwiftProtocolsCore
import SwiftyBeaver

class CacheChampionImagesCommand : Command {
    private static let BATCH_SIZE = 200

    private let logger = SwiftyBeaver.self
    private let completionQueue : dispatch_queue_t
    private let imageUrls : [String]
    
    init(imageUrls: [String], completionQueue : dispatch_queue_t) {
        self.imageUrls = imageUrls
        self.completionQueue = completionQueue
    }
    
    func execute() throws {
        let iterations = self.imageUrls.count / CacheChampionImagesCommand.BATCH_SIZE
        let remainder = self.imageUrls.count % CacheChampionImagesCommand.BATCH_SIZE
        let before = NSDate()
        
        for i in 0..<iterations {
            self.cacheImages(i * CacheChampionImagesCommand.BATCH_SIZE, to: (i * CacheChampionImagesCommand.BATCH_SIZE) + CacheChampionImagesCommand.BATCH_SIZE - 1)
        }
        
        if remainder > 0 {
            self.cacheImages(iterations * CacheChampionImagesCommand.BATCH_SIZE, to: self.imageUrls.count - 1)
        }
        
        logger.debug("It took \(NSDate().timeIntervalSinceDate(before)) to cache \(self.imageUrls.count) images")
    }
    
    private func cacheImages(from: Int, to: Int) {
        var count = Int32(to - from)
        let cacheSemaphore : dispatch_semaphore_t = dispatch_semaphore_create(0)
        
        for index in from...to {
            let url = self.imageUrls[index]
            logger.debug("Caching image \(url)")
            Alamofire.request(Alamofire.Method.GET, url)
                .response(queue: self.completionQueue, completionHandler: {(_, response, _, error) in
                    self.logger.debug("Got response code \(response?.statusCode) for \(url)")
                    if error != nil {
                        self.logger.error("An error occurred caching image at \(url): \(error)")
                    }
                    OSAtomicDecrement32(&count)
                    dispatch_semaphore_signal(cacheSemaphore)
                })
        }
        
        while count > 0 {
            dispatch_semaphore_wait(cacheSemaphore, DISPATCH_TIME_FOREVER)
        }

    }
}

