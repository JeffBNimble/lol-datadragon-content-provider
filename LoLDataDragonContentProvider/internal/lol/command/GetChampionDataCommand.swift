//
//  GetChampionDataCommand.swift
//  LoLDataDragonContentProvider
//
//  Created by Jeff Roberts on 7/31/15.
//  Copyright © 2015 nimbleNoggin.io. All rights reserved.
//

import Foundation
import Alamofire

public class GetChampionDataCommand {
    private static let CHAMPION_PATH = "/api/lol/static-data/\(LoLApiRequestManager.PLACEHOLDER_REGION)/\(LoLApiRequestManager.PLACEHOLDER_API_VERSION)/champion"
    
    private let completionQueue : dispatch_queue_t
    private let httpManager : Alamofire.Manager
    
    public init(httpManager : Alamofire.Manager, completionQueue: dispatch_queue_t) {
        self.httpManager = httpManager
        self.completionQueue = completionQueue
    }
    
    public func execute(success: (result:[String : AnyObject]?) -> (), error: (error: ErrorType?) -> ()) {
        self.httpManager.request(Alamofire.Method.GET, GetChampionDataCommand.CHAMPION_PATH)
            .response(queue: self.completionQueue, responseSerializer: Request.JSONResponseSerializer()) { _, _, result in
                guard result.isSuccess else {
                    error(error: result.error)
                    return
                }
                
                success(result: result.value as? [String : AnyObject])
            }
        }
}
