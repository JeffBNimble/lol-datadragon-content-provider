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
    
    private var httpManager : Alamofire.Manager
    
    public required init(httpManager : Alamofire.Manager) {
        self.httpManager = httpManager
    }
    
    public func execute(success: (result:NSDictionary?) -> (), error: (error: ErrorType?) -> ()) {
        self.httpManager.request(Alamofire.Method.GET, GetChampionDataCommand.CHAMPION_PATH)
            .responseJSON() { (request, response, result) in
                guard result.isSuccess else {
                    error(error: result.error)
                    return
                }
                
                success(result: result.value as? NSDictionary)
        }
    }
}
