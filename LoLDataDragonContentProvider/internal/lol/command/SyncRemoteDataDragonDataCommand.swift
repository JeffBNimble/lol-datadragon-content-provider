//
//  SyncRemoteDataDragonDataCommand.swift
//  LoLDataDragonContentProvider
//
//  The SyncRemoteDataDragonDataCommand is responsible for controlling and directing the process of
//  determining whether a sync is required by comparing the local and remote data dragon versions.
//  If there is no local version or the remote version is newer than the local version, a sync occurs.
//  A sync clears the local cache and database, retrieves the latest data dragon data (realms, champions)
//  from the Riot static data API, inserts it into the local database and then requests and caches locally
//  all of appropriate images.
//
//  Created by Jeff Roberts on 8/5/15.
//  Copyright © 2015 nimbleNoggin.io. All rights reserved.
//

import Foundation
import CocoaLumberjackSwift
import SwiftContentProvider
import SwiftProtocolsCore
import SwiftProtocolsSQLite

class SyncRemoteDataDragonDataCommand : Command {
    private typealias ParsedVersion = (major: Int, minor: Int, patch: Int)
    private let apiRequestManager : LoLApiRequestManager
    private let contentResolver : ContentResolver
    private let database : SQLiteDatabase
    private let databaseQueue : dispatch_queue_t
    private let httpQueue : dispatch_queue_t
    private let urlCache : NSURLCache
    
    init(apiRequestManager : LoLApiRequestManager,
        contentResolver: ContentResolver,
        database: SQLiteDatabase,
        databaseQueue: dispatch_queue_t,
        httpQueue: dispatch_queue_t,
        urlCache: NSURLCache) {
        self.apiRequestManager = apiRequestManager
        self.contentResolver = contentResolver
        self.database = database
        self.databaseQueue = databaseQueue
        self.httpQueue = httpQueue
        self.urlCache = urlCache
    }
    
    func execute() throws {
        // Step 1: retrieve the local and remote realm versions and compare
        let versions = try self.getLocalAndRemoteRealmVersions()
        let parsedRemoteVersion = try self.parseVersion(versions.remoteRealmVersion)
        let parsedLocalVersion = try self.parseVersion(versions.localRealmVersion)
            
        // If the local and remote major and minor versions are the same, no need to re-sync
        guard self.compareVersions(parsedLocalVersion, remoteVersion: parsedRemoteVersion) == false else {
            return
        }
            
        // Step 2: Clear the local database and NSURLCache
        try self.resetLocalStorage()
            
        // Step 3: Retrieve the champion and skin data from the Riot API
        let championJSON = try self.getChampionJSONData()
            
        // Step 4: Insert the realm
        try self.insertRealm(versions.remoteRealm!)
            
        // Step 5: Insert the champion and champion skins and notify on the content resolver
        let cdn = versions.remoteRealm!["cdn"] as! String
        let apiVersions = versions.remoteRealm!["n"] as! [String : AnyObject]
        let championVersion = apiVersions["champion"] as! String
        let imageUrls = try self.insertChampionsAndSkins(championJSON, cdn: cdn, championRealmVersion: championVersion)
        self.contentResolver.notifyChange(DataDragonDatabase.Champion.uri, operation: .Insert)
            
        // Step 6: Cache all of the images
        try CacheChampionImagesCommand(imageUrls: imageUrls.squareUrls, completionQueue: self.httpQueue).execute()
        try CacheChampionImagesCommand(imageUrls: imageUrls.portraitUrls + imageUrls.landscapeUrls, completionQueue: self.httpQueue).execute()
    }
    
    /// compareVersions: Compare the local and remote realm versions
    /// Returns: Bool True if the local and remote realm versions are equal
    private func compareVersions(localVersion: ParsedVersion?, remoteVersion: ParsedVersion?) -> Bool {
        guard let localVersion = localVersion, let remoteVersion = remoteVersion else {
            return false
        }
        
        return localVersion.major == remoteVersion.major && localVersion.minor == remoteVersion.minor
    }
    
    /// getChampionJSONData: Retrieve the champion JSON data from the Riot API
    /// Throws: An HTTP Error if the request fails
    /// Returns: An NSDictionary JSON result
    private func getChampionJSONData() throws -> [String : AnyObject] {
        let getDataSemaphore = dispatch_semaphore_create(0)
        var championJSONData : [String : AnyObject]?
        var httpError : ErrorType?
        
        // Issue an HTTP get request to get the latest remote champion data
        GetChampionDataCommand(httpManager: self.apiRequestManager, completionQueue: self.httpQueue)
            .execute({ championJSON in
                
                championJSONData = championJSON
                
                dispatch_semaphore_signal(getDataSemaphore)
                }, error: { error in
                    httpError = error
                    dispatch_semaphore_signal(getDataSemaphore)
                }
        )
        
        // Wait for the data
        dispatch_semaphore_wait(getDataSemaphore, DISPATCH_TIME_FOREVER)
        
        guard httpError == nil else {
            throw httpError!
        }
        
        return championJSONData!
    }
    
    private func getLocalAndRemoteRealmVersions() throws -> (localRealmVersion : String?, remoteRealmVersion : String?, remoteRealm: [String : AnyObject]?) {
        var responseCount : Int32 = 2
        var remoteRealmJSON : [String : AnyObject]?
        var localRealmVersion : String?
        var remoteRealmVersion : String?
        let syncSemaphore = dispatch_semaphore_create(0)
        var syncError : ErrorType?
        
        // Issue an HTTP get request to get the latest remote realm
        GetRealmCommand(httpManager: self.apiRequestManager, completionQueue: self.httpQueue)
            .execute({ realmJSON in
                OSAtomicDecrement32(&responseCount)
                
                remoteRealmJSON = realmJSON
                remoteRealmVersion = realmJSON?["v"] as? String
                DDLogInfo("Found remote realm version is \(remoteRealmVersion!)")
                
                dispatch_semaphore_signal(syncSemaphore)
            }, error: { error in
                OSAtomicDecrement32(&responseCount)
                syncError = error
            }
        )

        // Asynchronously, issue a query to get the current local realm version
        dispatch_async(self.databaseQueue, {
            
            let query = SQLQueryOperation(database: self.database, statementBuilder: SQLiteStatementBuilder())
            query.tableName = DataDragonDatabase.Realm.table
            query.projection = [DataDragonDatabase.Realm.Columns.realmVersion]
            
            do {
                let cursor = try query.executeQuery()
                if cursor.next() {
                    localRealmVersion = cursor.stringFor(DataDragonDatabase.Realm.Columns.realmVersion)
                    DDLogInfo("Found local realm version \(localRealmVersion)")
                } else {
                    DDLogInfo("No local realm version found")
                }
                
                defer {
                    cursor.close()
                }
            } catch {
                DDLogError("Encountered an error querying the realm table, \(error)")
                syncError = error
            }
            
            OSAtomicDecrement32(&responseCount)
            
            dispatch_semaphore_signal(syncSemaphore)
        })
        
        while responseCount > 0 {
            dispatch_semaphore_wait(syncSemaphore, DISPATCH_TIME_FOREVER)
        }
        
        if let syncError = syncError {
            throw syncError
        }
        
        return (
            localRealmVersion: localRealmVersion,
            remoteRealmVersion: remoteRealmVersion,
            remoteRealm: remoteRealmJSON
        )
    }
    
    /// insertChampionAndSkins: Inserts a row for each champion and champion skin
    /// Throws: A SQL error, if one occurs
    /// Return: A tuple of 3 batches of image URL's, one for the splash, one for the portrait and one for the landscape images
    private func insertChampionsAndSkins(json: [String : AnyObject],
        cdn: String,
        championRealmVersion: String)
        throws -> (squareUrls : [String], portraitUrls : [String], landscapeUrls : [String]) {
        let sqlSemaphore = dispatch_semaphore_create(0)
        let baseCDNUrl = NSURL(string: cdn)
        var sqlError : ErrorType?
        var squareImageUrls : [String] = []
        var portraitImageUrls : [String] = []
        var landscapeImageUrls : [String] = []
        var count = 0
        var skinCount = 0
        
        dispatch_async(self.databaseQueue, {
            defer {
                dispatch_semaphore_signal(sqlSemaphore)
            }
            
            do {
                let allChampionsData = json["data"] as! [String : AnyObject]
                let insertOp = SQLUpdateOperation(database: self.database, statementBuilder: SQLiteStatementBuilder())
                
                for key in allChampionsData.keys {
                    count++
                    var championData = allChampionsData[key] as! [String : AnyObject] // All JSON data for a champion
                    let skinsData = championData["skins"] as! [[String : AnyObject]] // All JSON skins data for a champion
                    let championId = championData["id"] as! Int
                    let championKey = championData["key"] as! String
                    
                    
                    let squareImageURL = NSURL(string: "cdn/\(championRealmVersion)/img/champion/\(championKey).png", relativeToURL: baseCDNUrl!)?.absoluteString
                    var contentValues : [String : AnyObject] = [:]
                    
                    contentValues[DataDragonDatabase.Champion.Columns.id] = championId
                    contentValues[DataDragonDatabase.Champion.Columns.key] = championKey
                    contentValues[DataDragonDatabase.Champion.Columns.name] = championData["name"]
                    contentValues[DataDragonDatabase.Champion.Columns.blurb] = championData["blurb"]
                    contentValues[DataDragonDatabase.Champion.Columns.title] = championData["title"]
                    contentValues[DataDragonDatabase.Champion.Columns.imageUrl] = squareImageURL!
                    
                    squareImageUrls.append(squareImageURL!)
                    
                    insertOp.tableName = DataDragonDatabase.Champion.table
                    insertOp.contentValues = contentValues
                    try insertOp.executeInsert()
                    
                    contentValues.removeAll()
                    
                    for skinData : [String : AnyObject] in skinsData {
                        skinCount++
                        let skinNumber = skinData["num"] as! Int
                        let landscapeImageURL = NSURL(string: "cdn/img/champion/splash/\(championKey)_\(skinNumber).jpg", relativeToURL: baseCDNUrl!)?.absoluteString
                        let portraitImageURL = NSURL(string: "cdn/img/champion/loading/\(championKey)_\(skinNumber).jpg", relativeToURL: baseCDNUrl!)?.absoluteString
                        
                        contentValues[DataDragonDatabase.ChampionSkin.Columns.championId] = championId
                        contentValues[DataDragonDatabase.ChampionSkin.Columns.id] = skinData["id"]
                        contentValues[DataDragonDatabase.ChampionSkin.Columns.skinNumber] = skinNumber
                        contentValues[DataDragonDatabase.ChampionSkin.Columns.name] = skinData["name"]
                        contentValues[DataDragonDatabase.ChampionSkin.Columns.portraitImageUrl] = portraitImageURL
                        contentValues[DataDragonDatabase.ChampionSkin.Columns.landscapeImageUrl] = landscapeImageURL
                        
                        portraitImageUrls.append(portraitImageURL!)
                        landscapeImageUrls.append(landscapeImageURL!)
                        
                        insertOp.tableName = DataDragonDatabase.ChampionSkin.table
                        insertOp.contentValues = contentValues
                        
                        try insertOp.executeInsert()
                    }
                
                }
            } catch {
                sqlError = error
            }
        })
            
        dispatch_semaphore_wait(sqlSemaphore, DISPATCH_TIME_FOREVER)
        print("Inserted \(count) champs and \(skinCount) skins")
        if sqlError != nil {
            throw sqlError!
        }
            
        return (squareImageUrls, portraitImageUrls, landscapeImageUrls)
    }
    
    /// insertRealm: Inserts the specified realm into the database
    private func insertRealm(json: [String : AnyObject]) throws {
        let sqlSemaphore = dispatch_semaphore_create(0)
        var sqlError : ErrorType?
        
        dispatch_async(self.databaseQueue, {
            defer {
                dispatch_semaphore_signal(sqlSemaphore)
            }
            
            do {
                let insertOp = SQLUpdateOperation(database: self.database, statementBuilder: SQLiteStatementBuilder())
                insertOp.tableName = DataDragonDatabase.Realm.table
                
                let apiVersions = json["n"] as! [ String : AnyObject] // Sub-dictionary of individual API versions
                var contentValues : [String : AnyObject] = [:]
                contentValues[DataDragonDatabase.Realm.Columns.realmVersion] = json["v"]  // Realm version
                contentValues[DataDragonDatabase.Realm.Columns.cdn] = json["cdn"] // CDN URL
                contentValues[DataDragonDatabase.Realm.Columns.profileIconMax] = json["profileiconmax"] // Max profile icon identifier
                contentValues[DataDragonDatabase.Realm.Columns.championVersion] = apiVersions["champion"] // Champion version
                contentValues[DataDragonDatabase.Realm.Columns.summonerVersion] = apiVersions["summoner"] // Summoner version
                contentValues[DataDragonDatabase.Realm.Columns.languageVersion] = apiVersions["language"] // Language version
                contentValues[DataDragonDatabase.Realm.Columns.mapVersion] = apiVersions["map"] // Map version
                contentValues[DataDragonDatabase.Realm.Columns.itemVersion] = apiVersions["item"] // Item version
                contentValues[DataDragonDatabase.Realm.Columns.masteryVersion] = apiVersions["mastery"] // Mastery version
                contentValues[DataDragonDatabase.Realm.Columns.runeVersion] = apiVersions["rune"] // Rune version
                contentValues[DataDragonDatabase.Realm.Columns.profileIconVersion] = apiVersions["profileicon"] // Profile icon version
                
                insertOp.contentValues = contentValues
                try insertOp.executeInsert()
            } catch {
                sqlError = error
            }
        })
        
        // Wait for the insert to complete/error
        dispatch_semaphore_wait(sqlSemaphore, DISPATCH_TIME_FOREVER)
        
        if let sqlError = sqlError {
            throw sqlError
        }
    }
    
    private func parseVersion(fullVersion: String?) throws -> ParsedVersion? {
        guard let fullVersion = fullVersion else {
            return nil
        }
        
        let regex = try NSRegularExpression(pattern: "(\\d{1,2})", options: NSRegularExpressionOptions(rawValue: 0))
        let range = NSMakeRange(0, fullVersion.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        let matches = regex.matchesInString(fullVersion as String, options: NSMatchingOptions.ReportProgress, range: range)
        
        let matched = matches.map() { match in
            return match.range
        }
        .map() { matchRange in
            return (fullVersion as NSString).substringWithRange(matchRange)
        }
        
        return (major: Int(matched[0])!, minor: Int(matched[1])!, patch: Int(matched[2])!)
    }
    
    private func resetLocalStorage() throws {
        let clearSemaphore = dispatch_semaphore_create(0)
        
        dispatch_async(self.databaseQueue, {
            let deleteOp = SQLUpdateOperation(database: self.database, statementBuilder: SQLiteStatementBuilder())
            
            do {
                defer {
                    dispatch_semaphore_signal(clearSemaphore)
                }
                
                // Delete all rows from the champion skin table
                deleteOp.tableName = DataDragonDatabase.ChampionSkin.table
                var count = try deleteOp.executeDelete()
                DDLogInfo("Deleted \(count) row(s) from the \(deleteOp.tableName!) table")
                
                // Delete all rows from the champion table
                deleteOp.tableName = DataDragonDatabase.Champion.table
                count = try deleteOp.executeDelete()
                DDLogInfo("Deleted \(count) row(s) from the \(deleteOp.tableName!) table")
                
                // Delete all rows from the realm table
                deleteOp.tableName = DataDragonDatabase.Realm.table
                count = try deleteOp.executeDelete()
                DDLogInfo("Deleted \(count) row(s) from the \(deleteOp.tableName!) table")
            } catch {
                DDLogError("An error occurred deleting rows from the DataDragon database, \(error)")
            }
        })
        
        dispatch_semaphore_wait(clearSemaphore, DISPATCH_TIME_FOREVER)
    }
}