//
//  GetRealmCommand.swift
//  LoLDataDragonContentProvider
//
//  Created by Jeff Roberts on 7/31/15.
//  Copyright © 2015 nimbleNoggin.io. All rights reserved.
//

import Foundation
import Alamofire
import SwiftProtocolsCore

class GetRealmCommand : AsyncCommand {
    private static let REALM_PATH = "/api/lol/static-data/\(LoLApiRequestManager.PLACEHOLDER_REGION)/\(LoLApiRequestManager.PLACEHOLDER_API_VERSION)/realm"
    
    private let completionQueue : dispatch_queue_t
    private var httpManager : Alamofire.Manager
    
    required init(httpManager : Alamofire.Manager, completionQueue : dispatch_queue_t) {
        self.httpManager = httpManager
        self.completionQueue = completionQueue
    }
    
    func execute(result: ([String : AnyObject]?) -> (), error: (ErrorType?) -> ()) {
        self.httpManager.request(Alamofire.Method.GET, GetRealmCommand.REALM_PATH)
            .responseJSON(queue: self.completionQueue, options: .AllowFragments, completionHandler: {
                response in
                result(response.result.value as? [String : AnyObject])
            })
        }
}