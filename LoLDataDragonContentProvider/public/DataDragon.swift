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
import SwiftProtocolsCore
import SwiftProtocolsSQLite
import SwiftContentProvider
import SwiftyBeaver

public protocol ModuleInterface {
    static var contentAuthority : String { get }
    var database : SQLiteDatabase { get }
    init(databaseFactory: DatabaseFactory,
        contentResolver : ContentResolver,
        apiKey : String,
        contentAuthorityBase : String,
        urlCache: NSURLCache,
        databaseName : String?,
        region : String?,
        databaseDispatchQueue: dispatch_queue_t?)

    func sync() throws
}

@objc
public class DataDragon : NSObject, ModuleInterface {
    private let logger = SwiftyBeaver.self

    public static var contentAuthority : String {
        get { return "dataDragon" }
    }
    
    /// database: The SQLiteDatabase instance used to store Data Dragon content
    public var database : SQLiteDatabase {
        get { return self.sqliteOpenHelper.getDatabase() }
    }
    
    /// databaseQueue: The dispatch queue to use for making database requests, should be a serial queue
    public let databaseQueue : dispatch_queue_t
    
    // Mark: Private variables
    
    /// apiKey: The Riot Games Developer API key used to make requests against the Riot API
    private let apiKey : String
    
    /// apiVersion: The version of the static data API to use, defaults to v1.2
    private let apiVersion = "v1.2"
    
    /// baseURL: The base static data Riot API url, defaults to https://global.api.pvp.net
    private let baseURL = "https://global.api.pvp.net"
    
    /// contentResolver: The ContentResolver through which all application content is resolved
    private var contentResolver : ContentResolver
    
    /// dataDragonHttpRequestManager: The AlamoFire Http request manager used to make requests of the Riot API
    private let dataDragonHttpRequestManager : LoLApiRequestManager

    /// databaseFactory: The DatabaseFactory used to create a SQLiteDatabase instance through which SQL is executed
    private var databaseFactory : DatabaseFactory
    
    /// databaseName: The name of the SQLite database name
    private let databaseName : String?
    
    /// databaseVersion: The version of the database schema
    private let databaseVersion = 1
    
    /// httpQueue: The dispatch queue to use for requesting and returning http responses
    private let httpQueue : dispatch_queue_t
    
    /// region: The region to use when making Riot API requests, defaults to na (North America)
    private let region : String
    
    /// sqliteOpenHelper: The internally created open helper
    private let sqliteOpenHelper : SQLiteOpenHelper!
    
    /// urlCache: The NSURLCache that is used to cache content from the Data Dragon API (images)
    private let urlCache : NSURLCache
    
    public required init(databaseFactory: DatabaseFactory,
        contentResolver : ContentResolver,
        apiKey : String,
        contentAuthorityBase : String,
        urlCache : NSURLCache,
        databaseName : String?,
        region : String? = "na",
        databaseDispatchQueue: dispatch_queue_t?) {
            self.databaseFactory = databaseFactory
            self.contentResolver = contentResolver
            self.apiKey = apiKey
            self.urlCache = urlCache
            self.databaseName = databaseName
            self.region = region!
            
            DataDragonDatabase.contentAuthority = "\(contentAuthorityBase).\(DataDragon.contentAuthority)"
            
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
            
            super.init()
            
            self.initialize()
    }
    
    /// sync: Request that a sync occur between the Riot API and the Data Dragon Content Provider
    /// complete: An optional closure that will be called if/when the sync completes without error
    /// error: An optional closure that will be called if the sync ends in an error
    public func sync() throws {
        let syncCommand = SyncRemoteDataDragonDataCommand(apiRequestManager: self.dataDragonHttpRequestManager,
            contentResolver: self.contentResolver,
            database: self.database,
            databaseQueue: self.databaseQueue,
            httpQueue: self.httpQueue,
            urlCache: self.urlCache)
        try syncCommand.execute()
    }
    
    // Mark: Private functions
    private func initialize() {
        self.initializeDatabaseAsync()
    }
    
    private func initializeDatabaseAsync() {
        dispatch_async(self.databaseQueue, {
            do {
                self.logger.debug("Opening SQLite database...")
                self.sqliteOpenHelper.getDatabase()
                
                self.logger.debug("Preparing SQLite database...")
                try self.sqliteOpenHelper.prepare()
            } catch {
                let error = error as NSError
                self.logger.error("An error occurred opening and/or preparing the database \(error.description)")
            }
        })
    }
}