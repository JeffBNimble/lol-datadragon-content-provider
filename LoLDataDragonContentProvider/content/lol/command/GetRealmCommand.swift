//
//  GetRealmCommand.swift
//  LoLDataDragonContentProvider
//
//  Created by Jeff Roberts on 7/31/15.
//  Copyright © 2015 nimbleNoggin.io. All rights reserved.
//

import Foundation
import Alamofire

public class GetRealmCommand {
    private static let REALM_PATH = "/api/lol/static-data/\(LoLApiRequestManager.PLACEHOLDER_REGION)/\(LoLApiRequestManager.PLACEHOLDER_API_VERSION)/realm"
    
    private var httpManager : Alamofire.Manager
    
    public required init(httpManager : Alamofire.Manager) {
        self.httpManager = httpManager
    }
    
    public func execute(success: (result:NSDictionary?) -> (), error: (error: ErrorType?) -> ()) {
        self.httpManager.request(Alamofire.Method.GET, GetRealmCommand.REALM_PATH)
            .responseJSON() { (request, response, result) in
                guard result.isSuccess else {
                    error(error: result.error)
                    return
                }
                
                success(result: result.value as? NSDictionary)
        }
    }
}