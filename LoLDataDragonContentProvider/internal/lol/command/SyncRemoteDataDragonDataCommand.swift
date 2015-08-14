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

public class SyncRemoteDataDragonDataCommand {
    private typealias ParsedVersion = (major: Int, minor: Int, patch: Int)
    private let apiRequestManager : LoLApiRequestManager
    private let contentResolver : ContentResolver
    private let database : SQLiteDatabase
    private let databaseQueue : dispatch_queue_t
    private let httpQueue : dispatch_queue_t
    private let urlCache : NSURLCache
    
    public init(apiRequestManager : LoLApiRequestManager,
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
    
    public func execute(result: () -> (), error: (ErrorType) -> ()) {
        do {
            // First, retrieve the local and remote realm versions and compare
            let versions = try self.getLocalAndRemoteRealmVersions()
            let parsedRemoteVersion = try self.parseVersion(versions.remoteRealmVersion)
            let parsedLocalVersion = try self.parseVersion(versions.localRealmVersion)
            
            guard self.compareVersions(parsedLocalVersion, remoteVersion: parsedRemoteVersion) == false else {
                result()
                return
            }
            
            // If we get here, we need to re-sync
            try self.resetLocalStorage()
            let championJSON = try self.getChampionJSONData()
            
            // Insert the realm
            try self.insertRealm(versions.remoteRealm!)
            
            // Insert the champion and champion skins
            let imageUrls = try self.insertChampionsAndSkins(championJSON, dataDragonCDN: versions.remoteRealm["cdn"] as! String)
            
        } catch {
            DDLogError("An error occurred trying to sync the local data with the latest remote, \(error)")
        }
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
        var responseCount = 0
        var remoteRealmJSON : [String : AnyObject]?
        var localRealmVersion : String?
        var remoteRealmVersion : String?
        let syncSemaphore = dispatch_semaphore_create(2)
        var syncError : ErrorType?
        
        // Issue an HTTP get request to get the latest remote realm
        GetRealmCommand(httpManager: self.apiRequestManager, completionQueue: self.httpQueue)
            .execute({ realmJSON in
                responseCount++
                
                remoteRealmJSON = realmJSON
                remoteRealmVersion = realmJSON?["v"] as? String
                DDLogInfo("Found remote realm version is \(remoteRealmVersion!)")
                
                dispatch_semaphore_signal(syncSemaphore)
            }, error: { error in
                responseCount++
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
            
            responseCount++
            
            dispatch_semaphore_signal(syncSemaphore)
        })
        
        while responseCount < 2 {
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
    private func insertChampionsAndSkins(json: [String : AnyObject], dataDragonCDN: String) throws -> (splashUrls : [String], portraitUrls : [String], landscapeUrls : [String]) {
        let sqlSemaphore = dispatch_semaphore_create(0)
        var sqlError : ErrorType?
        var splashImageUrls : [String] = []
        var portraitImageUrls : [String] = []
        var landscapeImageUrls : [String] = []
        
        dispatch_async(self.databaseQueue, {
            defer {
                dispatch_semaphore_signal(sqlSemaphore)
            }
            
            do {
                let allChampionData = json["data"] as! [String : AnyObject]
                let insertOp = SQLUpdateOperation(database: self.database, statementBuilder: SQLiteStatementBuilder())
                
                for key in allChampionData.keys {
                    var championData = (allChampionData[key] as! [String : AnyObject]).map() { championJSON in
                        guard let championJSON = championJSON as! [String : AnyObject] else {
                            return [String : AnyObject]()
                        }
                    }
                }
            } catch {
                sqlError = error
            }
        })
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
        
        self.urlCache.removeAllCachedResponses()
        DDLogInfo("Clearing the shared URL cache")
        
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