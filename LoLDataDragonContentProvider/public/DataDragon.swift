//
//  DataDragon.swift
//  LoLDataDragonContentProvider
//
//  DataDragon is the top level interface to the framework. Other than the Content Provider, everything else is exposed
//  through this interface.
//
//  Created by Jeff Roberts on 8/2/15.
//  Copyright © 2015 nimbleNoggin.io. All rights reserved.
//

import Foundation
import CocoaLumberjackSwift
import SwiftProtocolsCore
import SwiftProtocolsSQLite
import SwiftContentProvider

public protocol ModuleInterface {
    var database : SQLiteDatabase { get }
    init(databaseFactory: Factory,
        contentResolver : ContentResolver,
        apiKey : String,
        contentAuthority : String,
        urlCache: NSURLCache,
        databaseName : String?,
        region : String?,
        databaseDispatchQueue: dispatch_queue_t?)

    func sync(complete: (() -> ())?, error: ((error : ErrorType) -> ())?)
}

public class DataDragon : ModuleInterface {
    
    /// database: The SQLiteDatabase instance used to store Data Dragon content
    public var database : SQLiteDatabase {
        get { return self.sqliteOpenHelper.getDatabase() }
    }
    
    // Mark: Private variables
    
    /// apiKey: The Riot Games Developer API key used to make requests against the Riot API
    private let apiKey : String
    
    /// apiVersion: The version of the static data API to use, defaults to v1.2
    private let apiVersion = "v1.2"
    
    /// baseURL: The base static data Riot API url, defaults to https://global.api.pvp.net
    private let baseURL = "https://global.api.pvp.net"
    
    /// contentAuthority: The content authority to use for data dragon content. This should be set to the bundle identifier
    private var contentAuthority : String {
        didSet {
            DataDragonDatabase.contentAuthority = contentAuthority
        }
    }
    
    /// contentResolver: The ContentResolver through which all application content is resolved
    private var contentResolver : ContentResolver
    
    /// dataDragonHttpRequestManager: The AlamoFire Http request manager used to make requests of the Riot API
    private let dataDragonHttpRequestManager : LoLApiRequestManager

    /// databaseFactory: The Factory used to create a SQLiteDatabase instance through which SQL is executed
    private var databaseFactory : Factory
    
    /// databaseName: The name of the SQLite database name
    private let databaseName : String?
    
    /// databaseVersion: The version of the database schema
    private let databaseVersion = 1
    
    /// databaseQueue: The dispatch queue to use for making database requests, should be a serial queue
    private let databaseQueue : dispatch_queue_t
    
    /// httpQueue: The dispatch queue to use for requesting and returning http responses
    private let httpQueue : dispatch_queue_t
    
    /// region: The region to use when making Riot API requests, defaults to na (North America)
    private let region : String
    
    /// sqliteOpenHelper: The internally created open helper
    private let sqliteOpenHelper : SQLiteOpenHelper!
    
    /// urlCache: The NSURLCache that is used to cache content from the Data Dragon API (images)
    private let urlCache : NSURLCache
    
    public required init(databaseFactory: Factory,
        contentResolver : ContentResolver,
        apiKey : String,
        contentAuthority : String,
        urlCache : NSURLCache,
        databaseName : String?,
        region : String? = "na",
        databaseDispatchQueue: dispatch_queue_t?) {
            self.databaseFactory = databaseFactory
            self.contentResolver = contentResolver
            self.apiKey = apiKey
            self.contentAuthority = contentAuthority
            self.urlCache = urlCache
            self.databaseName = databaseName
            self.region = region!
            
            self.sqliteOpenHelper = DataDragonSQLiteOpenHelper(databaseFactory: self.databaseFactory, databaseName: self.databaseName, version: self.databaseVersion)
            
            if databaseDispatchQueue == nil {
                self.databaseQueue = dispatch_queue_create("io.nimblenoggin.datadragon.database_queue", DISPATCH_QUEUE_SERIAL)
            } else {
                self.databaseQueue = databaseDispatchQueue!
            }
            
            self.httpQueue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
            
            self.dataDragonHttpRequestManager = LoLApiRequestManager(sessionConfiguration: NSURLSessionConfiguration.defaultSessionConfiguration(),
                baseURL: NSURL(string: self.baseURL)!,
                apiKey: self.apiKey,
                region: self.region,
                apiVersion: self.apiVersion)
            
            self.initialize()
    }
    
    /// sync: Request that a sync occur between the Riot API and the Data Dragon Content Provider
    /// complete: An optional closure that will be called if/when the sync completes without error
    /// error: An optional closure that will be called if the sync ends in an error
    public func sync(complete: (() -> ())?, error: ((error : ErrorType) -> ())?) {
        let syncCommand = SyncRemoteDataDragonDataCommand(apiRequestManager: self.dataDragonHttpRequestManager,
            contentResolver: self.contentResolver,
            database: self.database,
            databaseQueue: self.databaseQueue,
            httpQueue: self.httpQueue,
            urlCache: self.urlCache)
        syncCommand.execute( { result in
            }, error: { error in
            }
        )
    }
    
    // Mark: Private functions
    private func initialize() {
        self.initializeDatabaseAsync()
    }
    
    private func initializeDatabaseAsync() {
        dispatch_async(self.databaseQueue, {
            do {
                DDLogVerbose("Opening SQLite database...")
                self.sqliteOpenHelper.getDatabase()
                
                DDLogVerbose("Preparing SQLite database...")
                try self.sqliteOpenHelper.prepare()
            } catch {
                let error = error as NSError
                DDLogError("An error occurred opening and/or preparing the database \(error.description)")
            }
        })
    }
}