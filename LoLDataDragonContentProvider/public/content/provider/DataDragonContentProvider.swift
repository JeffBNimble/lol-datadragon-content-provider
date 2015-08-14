//
//  DataDragonContentProvider.swift
//  LoLDataDragonContentProvider
//
//  Created by Jeff Roberts on 7/31/15.
//  Copyright © 2015 nimbleNoggin.io. All rights reserved.
//

import Foundation
import SwiftProtocolsCore
import SwiftProtocolsSQLite
import SwiftContentProvider

public enum DataDragonUris : MatchedUri {
    case Realm
    case Champions
    case ChampionSkins
    
    public func isEqual(another: MatchedUri) -> Bool {
        guard another.dynamicType == self.dynamicType else {
            return false
        }
        
        return true
    }
}

public class DataDragonContentProvider : ContentProvider {
    public var contentResolver : ContentResolver?
    
    private let database : SQLiteDatabase
    private let sqlStatementBuilder = SQLiteStatementBuilder()
    private let uriMatcher : UriMatcher = UriMatcher()
    
    public init(database: SQLiteDatabase) {
        self.database = database
    }
    
    public func delete(uri: Uri, selection: String?, selectionArgs: [AnyObject]?) throws -> Int {
        let match = self.uriMatcher.match(uri)
        
        var deleteCount:Int = 0
        
        switch match {
            case DataDragonUris.Realm:
                deleteCount = try self.deleteRealm(selection, selectionArgs: selectionArgs)
            
            case DataDragonUris.Champions:
                deleteCount = try self.deleteChampion(selection, selectionArgs: selectionArgs)
            
            case DataDragonUris.ChampionSkins:
                deleteCount = try self.deleteChampionSkin(selection, selectionArgs: selectionArgs)
            
            default:
                throw UriMatchError.UriNotMatched
        }
        
        return deleteCount
    }
    
    public func delete(uri: Uri, selection: String?, selectionArgs: [String : AnyObject]?) throws -> Int {
        let match = self.uriMatcher.match(uri)
        
        var deleteCount:Int = 0
        
        switch match {
        case DataDragonUris.Realm:
            deleteCount = try self.deleteRealm(selection, selectionArgs: selectionArgs)
            
        case DataDragonUris.Champions:
            deleteCount = try self.deleteChampion(selection, selectionArgs: selectionArgs)
            
        case DataDragonUris.ChampionSkins:
            deleteCount = try self.deleteChampionSkin(selection, selectionArgs: selectionArgs)
            
        default:
            throw UriMatchError.UriNotMatched
        }
        
        return deleteCount
    }
    
    public func insert(uri: Uri, values: [String : AnyObject]) throws -> Uri {
        let match = self.uriMatcher.match(uri)
        
        var insertedUri : Uri?
        
        switch match {
        case DataDragonUris.Realm:
            insertedUri = try self.insertRealm(values)
            
        case DataDragonUris.Champions:
            insertedUri = try self.insertChampion(values)
            
        case DataDragonUris.ChampionSkins:
            insertedUri = try self.insertChampionSkin(values)
            
        default:
            throw UriMatchError.UriNotMatched
        }
        
        return insertedUri!
    }
    
    public func onCreate() {
        self.uriMatcher.addUri(DataDragonDatabase.Realm.uri, matchedUri: DataDragonUris.Realm)
        self.uriMatcher.addUri(DataDragonDatabase.Champion.uri, matchedUri: DataDragonUris.Champions)
        self.uriMatcher.addUri(DataDragonDatabase.ChampionSkin.uri, matchedUri: DataDragonUris.ChampionSkins)
    }
    
    public func query(uri: Uri,
        projection: [String]?,
        selection: String?,
        selectionArgs: [AnyObject]?,
        groupBy: String?,
        having: String?,
        sort: String?) throws -> Cursor {
            let match = self.uriMatcher.match(uri)
        
            var cursor : Cursor?
        
            switch match {
                case DataDragonUris.Realm:
                    cursor = try self.queryRealm(projection,
                        selection: selection,
                        selectionArgs: selectionArgs,
                        groupBy: groupBy,
                        having: having,
                        sort: sort)
            
                case DataDragonUris.Champions:
                    cursor = try self.queryChampions(projection,
                        selection: selection,
                        selectionArgs: selectionArgs,
                        groupBy: groupBy,
                        having: having,
                        sort: sort)
            
                case DataDragonUris.ChampionSkins:
                    cursor = try self.queryChampionSkins(projection,
                        selection: selection,
                        selectionArgs: selectionArgs,
                        groupBy: groupBy,
                        having: having,
                        sort: sort)
            
                default:
                    throw UriMatchError.UriNotMatched
            }
        
            return cursor!

    }
    
    public func query(uri: Uri,
        projection: [String]?,
        selection: String?,
        selectionArgs: [String : AnyObject]?,
        groupBy: String?,
        having: String?,
        sort: String?) throws -> Cursor {
            let match = self.uriMatcher.match(uri)
            
            var cursor : Cursor?
            
            switch match {
            case DataDragonUris.Realm:
                cursor = try self.queryRealm(projection,
                    selection: selection,
                    selectionArgs: selectionArgs,
                    groupBy: groupBy,
                    having: having,
                    sort: sort)
                
            case DataDragonUris.Champions:
                cursor = try self.queryChampions(projection,
                    selection: selection,
                    selectionArgs: selectionArgs,
                    groupBy: groupBy,
                    having: having,
                    sort: sort)
                
            case DataDragonUris.ChampionSkins:
                cursor = try self.queryChampionSkins(projection,
                    selection: selection,
                    selectionArgs: selectionArgs,
                    groupBy: groupBy,
                    having: having,
                    sort: sort)
                
            default:
                throw UriMatchError.UriNotMatched
            }
            
            return cursor!
    }
    
    public func update(uri: Uri, values: [String : AnyObject], selection: String?, selectionArgs: [AnyObject]?) throws -> Int {
        let match = self.uriMatcher.match(uri)
        
        var updateCount:Int = 0
        
        switch match {
        case DataDragonUris.Realm:
            updateCount = try self.updateRealm(values, selection: selection, selectionArgs: selectionArgs)
            
        case DataDragonUris.Champions:
            updateCount = try self.updateChampion(values, selection: selection, selectionArgs: selectionArgs)
            
        case DataDragonUris.ChampionSkins:
            updateCount = try self.updateChampionSkin(values, selection: selection, selectionArgs: selectionArgs)
            
        default:
            throw UriMatchError.UriNotMatched
        }
        
        return updateCount
    }
    
    public func update(uri: Uri, values: [String : AnyObject], selection: String?, selectionArgs: [String : AnyObject]?) throws -> Int {
        let match = self.uriMatcher.match(uri)
        
        var updateCount:Int = 0
        
        switch match {
        case DataDragonUris.Realm:
            updateCount = try self.updateRealm(values, selection: selection, selectionArgs: selectionArgs)
            
        case DataDragonUris.Champions:
            updateCount = try self.updateChampion(values, selection: selection, selectionArgs: selectionArgs)
            
        case DataDragonUris.ChampionSkins:
            updateCount = try self.updateChampionSkin(values, selection: selection, selectionArgs: selectionArgs)
            
        default:
            throw UriMatchError.UriNotMatched
        }
        
        return updateCount
    }
    
    /// MARK : Private functions
    private func insertChampion(contentValues: [String : AnyObject]) throws -> Uri {
        let op = try self.createSqlUpdateOperation(DataDragonDatabase.Champion.table,
            contentValues: contentValues,
            selection: nil,
            selectionArgs: nil as [String]?)
        try op.executeInsert()
        return DataDragonDatabase.Champion.uri(contentValues[DataDragonDatabase.Champion.Columns.id] as! Int)
    }
    
    private func insertChampionSkin(contentValues: [String : AnyObject]) throws -> Uri {
        let op = try self.createSqlUpdateOperation(DataDragonDatabase.ChampionSkin.table,
            contentValues: contentValues,
            selection: nil,
            selectionArgs: nil as [String]?)
        try op.executeInsert()
        return DataDragonDatabase.ChampionSkin.uri(contentValues[DataDragonDatabase.ChampionSkin.Columns.skinNumber] as! Int)
    }
    
    private func insertRealm(contentValues: [String : AnyObject]) throws -> Uri {
        let op = try self.createSqlUpdateOperation(DataDragonDatabase.Realm.table,
            contentValues: contentValues,
            selection: nil,
            selectionArgs: nil as [String]?)
        try op.executeInsert()
        return DataDragonDatabase.Realm.uri(contentValues[DataDragonDatabase.Realm.Columns.realmVersion] as! String)
    }
    
    private func deleteChampion(selection: String?, selectionArgs: [AnyObject]?) throws -> Int {
        let op = try self.createSqlUpdateOperation(DataDragonDatabase.Champion.table,
            contentValues: nil,
            selection: selection,
            selectionArgs: selectionArgs)
        return try op.executeDelete()
    }
    
    private func deleteChampion(selection: String?, selectionArgs: [String : AnyObject]?) throws -> Int {
        let op = try self.createSqlUpdateOperation(DataDragonDatabase.Champion.table,
            contentValues: nil,
            selection: selection,
            selectionArgs: selectionArgs)
        return try op.executeDelete()
    }
    
    private func deleteChampionSkin(selection: String?, selectionArgs: [AnyObject]?) throws -> Int {
        let op = try self.createSqlUpdateOperation(DataDragonDatabase.ChampionSkin.table,
            contentValues: nil,
            selection: selection,
            selectionArgs: selectionArgs)
        return try op.executeDelete()
    }
    
    private func deleteChampionSkin(selection: String?, selectionArgs: [String : AnyObject]?) throws -> Int {
        let op = try self.createSqlUpdateOperation(DataDragonDatabase.ChampionSkin.table,
            contentValues: nil,
            selection: selection,
            selectionArgs: selectionArgs)
        return try op.executeDelete()
    }
    
    private func deleteRealm(selection: String?, selectionArgs: [AnyObject]?) throws -> Int {
        let op = try self.createSqlUpdateOperation(DataDragonDatabase.Realm.table,
            contentValues: nil,
            selection: selection,
            selectionArgs: selectionArgs)
        return try op.executeDelete()
    }
    
    private func deleteRealm(selection: String?, selectionArgs: [String : AnyObject]?) throws -> Int {
        let op = try self.createSqlUpdateOperation(DataDragonDatabase.Realm.table,
            contentValues: nil,
            selection: selection,
            selectionArgs: selectionArgs)
        return try op.executeDelete()
    }
    
    private func queryChampions(projection: [String]?,
        selection: String?,
        selectionArgs: [AnyObject]?,
        groupBy: String?,
        having: String?,
        sort: String?) throws -> Cursor {
        let op = try self.createSqlQueryOperation(DataDragonDatabase.Champion.table,
            projection: projection,
            selection: selection,
            selectionArgs: selectionArgs,
            groupBy: groupBy,
            having: having,
            sort: sort)
        return try op.executeQuery()
    }
    
    private func queryChampions(projection: [String]?,
        selection: String?,
        selectionArgs: [String : AnyObject]?,
        groupBy: String?,
        having: String?,
        sort: String?) throws -> Cursor {
            let op = try self.createSqlQueryOperation(DataDragonDatabase.Champion.table,
                projection: projection,
                selection: selection,
                selectionArgs: selectionArgs,
                groupBy: groupBy,
                having: having,
                sort: sort)
            return try op.executeQuery()
    }
    
    private func queryChampionSkins(projection: [String]?,
        selection: String?,
        selectionArgs: [AnyObject]?,
        groupBy: String?,
        having: String?,
        sort: String?) throws -> Cursor {
            let op = try self.createSqlQueryOperation(DataDragonDatabase.ChampionSkin.table,
                projection: projection,
                selection: selection,
                selectionArgs: selectionArgs,
                groupBy: groupBy,
                having: having,
                sort: sort)
            return try op.executeQuery()
    }
    
    private func queryChampionSkins(projection: [String]?,
        selection: String?,
        selectionArgs: [String : AnyObject]?,
        groupBy: String?,
        having: String?,
        sort: String?) throws -> Cursor {
            let op = try self.createSqlQueryOperation(DataDragonDatabase.ChampionSkin.table,
                projection: projection,
                selection: selection,
                selectionArgs: selectionArgs,
                groupBy: groupBy,
                having: having,
                sort: sort)
            return try op.executeQuery()
    }
    
    private func queryRealm(projection: [String]?,
        selection: String?,
        selectionArgs: [AnyObject]?,
        groupBy: String?,
        having: String?,
        sort: String?) throws -> Cursor {
            let op = try self.createSqlQueryOperation(DataDragonDatabase.Realm.table,
                projection: projection,
                selection: selection,
                selectionArgs: selectionArgs,
                groupBy: groupBy,
                having: having,
                sort: sort)
            return try op.executeQuery()
    }
    
    private func queryRealm(projection: [String]?,
        selection: String?,
        selectionArgs: [String : AnyObject]?,
        groupBy: String?,
        having: String?,
        sort: String?) throws -> Cursor {
            let op = try self.createSqlQueryOperation(DataDragonDatabase.Realm.table,
                projection: projection,
                selection: selection,
                selectionArgs: selectionArgs,
                groupBy: groupBy,
                having: having,
                sort: sort)
            return try op.executeQuery()
    }
    
    private func updateChampion(contentValues: [String : AnyObject], selection: String?, selectionArgs: [AnyObject]?) throws -> Int {
        let op = try self.createSqlUpdateOperation(DataDragonDatabase.Champion.table,
            contentValues: contentValues,
            selection: selection,
            selectionArgs: selectionArgs)
        return try op.executeUpdate()
    }
    
    private func updateChampion(contentValues: [String : AnyObject], selection: String?, selectionArgs: [String : AnyObject]?) throws -> Int {
        let op = try self.createSqlUpdateOperation(DataDragonDatabase.Champion.table,
            contentValues: contentValues,
            selection: selection,
            selectionArgs: selectionArgs)
        return try op.executeUpdate()
    }
    
    private func updateChampionSkin(contentValues: [String : AnyObject], selection: String?, selectionArgs: [AnyObject]?) throws -> Int {
        let op = try self.createSqlUpdateOperation(DataDragonDatabase.ChampionSkin.table,
            contentValues: contentValues,
            selection: selection,
            selectionArgs: selectionArgs)
        return try op.executeUpdate()
    }
    
    private func updateChampionSkin(contentValues: [String : AnyObject], selection: String?, selectionArgs: [String : AnyObject]?) throws -> Int {
        let op = try self.createSqlUpdateOperation(DataDragonDatabase.ChampionSkin.table,
            contentValues: contentValues,
            selection: selection,
            selectionArgs: selectionArgs)
        return try op.executeUpdate()
    }
    
    private func updateRealm(contentValues: [String : AnyObject], selection: String?, selectionArgs: [AnyObject]?) throws -> Int {
        let op = try self.createSqlUpdateOperation(DataDragonDatabase.Realm.table,
            contentValues: contentValues,
            selection: selection,
            selectionArgs: selectionArgs)
        return try op.executeUpdate()
    }
    
    private func updateRealm(contentValues: [String : AnyObject], selection: String?, selectionArgs: [String : AnyObject]?) throws -> Int {
        let op = try self.createSqlUpdateOperation(DataDragonDatabase.Realm.table,
            contentValues: contentValues,
            selection: selection,
            selectionArgs: selectionArgs)
        return try op.executeUpdate()
    }
    
    private func createSqlQueryOperation(table: String,
        projection: [String]?,
        selection: String?,
        selectionArgs: [AnyObject]?,
        groupBy: String?,
        having: String?,
        sort: String?) throws -> SQLQueryOperation {
            try self.ensureDatabaseIsOpen()
            let op = SQLQueryOperation(database: self.database, statementBuilder: self.sqlStatementBuilder)
            op.tableName = table
            op.projection = projection
            op.selection = selection
            op.selectionArgs = selectionArgs
            op.groupBy = groupBy
            op.having = having
            op.sort = sort
            
            return op
    }
    
    private func createSqlQueryOperation(table: String,
        projection: [String]?,
        selection: String?,
        selectionArgs: [String : AnyObject]?,
        groupBy: String?,
        having: String?,
        sort: String?) throws -> SQLQueryOperation {
            try self.ensureDatabaseIsOpen()
            let op = SQLQueryOperation(database: self.database, statementBuilder: self.sqlStatementBuilder)
            op.tableName = table
            op.projection = projection
            op.selection = selection
            op.namedSelectionArgs = selectionArgs
            op.groupBy = groupBy
            op.having = having
            op.sort = sort
            
            return op
    }

    private func createSqlUpdateOperation(table: String,
        contentValues: [String : AnyObject]?,
        selection: String?,
        selectionArgs: [AnyObject]?) throws -> SQLUpdateOperation {
            try self.ensureDatabaseIsOpen()
            let op = SQLUpdateOperation(database: self.database, statementBuilder: self.sqlStatementBuilder)
            op.tableName = table
            op.contentValues = contentValues
            op.selection = selection
            op.selectionArgs = selectionArgs
        
            return op
    }
    
    private func createSqlUpdateOperation(table: String,
        contentValues: [String : AnyObject]?,
        selection: String?,
        selectionArgs: [String : AnyObject]?) throws -> SQLUpdateOperation {
            try self.ensureDatabaseIsOpen()
            let op = SQLUpdateOperation(database: self.database, statementBuilder: self.sqlStatementBuilder)
            op.tableName = table
            op.contentValues = contentValues
            op.selection = selection
            op.namedSelectionArgs = selectionArgs
        
            return op
    }
    
    private func ensureDatabaseIsOpen() throws {
        if !self.database.isOpen {
            try self.database.open()
        }
    }

}