//: Playground - noun: a place where people can play

import Foundation
import Alamofire
import LoLDataDragonContentProvider
import SwiftProtocolsCore
import fmdbframework
import SwiftProtocolsSQLite
import SwiftAdaptersFMDB
import SwiftContentProvider
import CocoaLumberjackSwift
import XCPlayground

XCPSetExecutionShouldContinueIndefinitely()

//: Initialize the logging mechanism
let consoleLogger = DDTTYLogger()
DDLog.addLogger(consoleLogger, withLevel: .Verbose)

let version = "5.15.1"
//do  {
    let regex = try NSRegularExpression(pattern: "(\\d{1,2})", options: NSRegularExpressionOptions(rawValue: 0))
    let range = NSMakeRange(0, version.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
    let matches = regex.matchesInString(version as String, options: NSMatchingOptions.ReportProgress, range: range)
    let match = (version as NSString).substringWithRange(range)
    
let matched = matches.map() { match in
        return match.range
}.map() { matchRange in
        return (version as NSString).substringWithRange(matchRange)
}

let versioned = (major: matched[0], minor: matched[1], patch: matched[2])
versioned.major

//} catch {
//    print(error)
//}

let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
let baseURL = NSURL(string: "https://global.api.pvp.net")
let apiKey = "b0984714-2747-48eb-8ea7-761af99a8a5f"
let region = "na"
let apiVersion = "v1.2"
let manager = LoLApiRequestManager(sessionConfiguration: configuration, baseURL: baseURL!, apiKey: apiKey, region: region, apiVersion: apiVersion)
let completionQueue = dispatch_queue_create("io.nimblenoggin.datadragon.http", DISPATCH_QUEUE_CONCURRENT)

let getRealmCommand = GetRealmCommand(httpManager: manager, completionQueue: completionQueue)
getRealmCommand.execute({ (json) in
    //print(json)
    }, error: { (error) in
        print(error!)
    }
)

let getChampionDataCommand = GetChampionDataCommand(httpManager: manager, completionQueue: completionQueue)
getChampionDataCommand.execute({ (json) in
    //print(json)
    }, error: { (error) in
        print(error!)
    }
)

class ContentProviderFactory : TypedFactory {
    func create<ContentProvider>(type: NSObject.Type) -> ContentProvider {
        return DataDragonContentProvider(database: FMDBDatabaseWrapper(path: nil)) as! ContentProvider
    }
}

/// W
let backgroundQueue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
let contentResolver = ContentResolver(contentProviderFactory: ContentProviderFactory(), contentAuthorityBase: "io.nimblenoggin.test", contentRegistrations: [String : NSObject.Type]() )
let dataDragon = DataDragon(databaseFactory : FMDBDatabaseFactory(),
    contentResolver: contentResolver,
    apiKey : apiKey,
    contentAuthority : "io.nimblenoggin.test",
    urlCache : NSURLCache.sharedURLCache(),
    databaseName: nil,
    databaseDispatchQueue : nil)
print("Yo")

dispatch_async(backgroundQueue, {
    print("Async")
    dataDragon.sync({
            print("Done!")
        }, error: { error in
            print("Error!")
        })
})
