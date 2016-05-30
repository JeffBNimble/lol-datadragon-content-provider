//
//  GetChampionDataCommand.swift
//  LoLDataDragonContentProvider
//
//  Created by Jeff Roberts on 7/31/15.
//  Copyright © 2015 nimbleNoggin.io. All rights reserved.
//

import Foundation
import Alamofire
import SwiftProtocolsCore
import SwiftyBeaver

class GetChampionDataCommand : AsyncCommand {
    private static let CHAMPION_PATH = "/api/lol/static-data/\(LoLApiRequestManager.PLACEHOLDER_REGION)/\(LoLApiRequestManager.PLACEHOLDER_API_VERSION)/champion"
    
    private let logger = SwiftyBeaver.self
    private let completionQueue : dispatch_queue_t
    private let httpManager : Alamofire.Manager
    
    init(httpManager : Alamofire.Manager, completionQueue: dispatch_queue_t) {
        self.httpManager = httpManager
        self.completionQueue = completionQueue
    }
    
    func execute(result: ([String : AnyObject]?) -> (), error: (ErrorType?) -> ()) {
        self.httpManager.request(Alamofire.Method.GET, GetChampionDataCommand.CHAMPION_PATH, parameters: ["champData" : "blurb,skins"])
            .responseJSON(queue: self.completionQueue, options: .AllowFragments, completionHandler: {
                response in
                
                self.logger.logHTTPResponse(response)
                result(response.result.value as? [String : AnyObject])
            })
        }
}
