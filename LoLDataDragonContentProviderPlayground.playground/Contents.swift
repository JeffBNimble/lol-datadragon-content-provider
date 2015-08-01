//: Playground - noun: a place where people can play

import UIKit
import Alamofire
import LoLDataDragonContentProvider
import XCPlayground

XCPSetExecutionShouldContinueIndefinitely()

var str = "Hello, playground"

let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
let baseURL = NSURL(string: "https://global.api.pvp.net")
let apiKey = "b0984714-2747-48eb-8ea7-761af99a8a5f"
let region = "na"
let apiVersion = "v1.2"
let manager = LoLApiRequestManager(sessionConfiguration: configuration, baseURL: baseURL!, apiKey: apiKey, region: region, apiVersion: apiVersion)

let getRealmCommand = GetRealmCommand(httpManager: manager)
getRealmCommand.execute( { (json) in
    print(json!.objectForKey("cdn"))
        print(json)
    }, error: { (error) in
        print(error!)
    }
)

let getChampionDataCommand = GetChampionDataCommand(httpManager: manager)
getChampionDataCommand.execute( { (json) in
    print(json)
    }, error: { (error) in
        print(error!)
    }
)
