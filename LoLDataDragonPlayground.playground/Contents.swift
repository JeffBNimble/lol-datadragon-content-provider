
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

let consoleLogger = DDTTYLogger()
DDLog.addLogger(consoleLogger, withLevel: .Verbose)

let version = "5.15.1"

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

class CPFactory : ContentProviderFactory {
    override func create(type: NSObject.Type) throws -> ContentProvider {
        return DataDragonContentProvider(database: FMDBDatabaseWrapper(path: nil))
    }
}

let backgroundQueue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
let cache = NSURLCache(memoryCapacity: (1 * 1024 * 1024), diskCapacity: (500 * 1024 * 1024), diskPath: "champImageCache")
NSURLCache.setSharedURLCache(cache)

let apiKey = "b0984714-2747-48eb-8ea7-761af99a8a5f"
let contentAuthorityBase = "io.nimblenoggin.test"
let dbFactory = FMDBDatabaseFactory()
dbFactory is DatabaseFactory
let contentResolver = ContentResolver(contentProviderFactory: CPFactory(), contentAuthorityBase: contentAuthorityBase, contentRegistrations: [String : NSObject.Type]() )
let dataDragon = DataDragon(databaseFactory: dbFactory, contentResolver: contentResolver, apiKey: apiKey, contentAuthority: contentAuthorityBase, urlCache : NSURLCache.sharedURLCache(), databaseName: nil, databaseDispatchQueue: nil)
print("Yo")

dispatch_async(backgroundQueue, {
    print("Async")
    do {
        try dataDragon.sync()
    } catch {
        print("Oh no \(error)")
    }
})

