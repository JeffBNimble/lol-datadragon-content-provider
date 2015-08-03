//
//  DataDragonSQLiteOpenHelper.swift
//  LoLDataDragonContentProvider
//
//  Created by Jeff Roberts on 8/1/15.
//  Copyright © 2015 nimbleNoggin.io. All rights reserved.
//

import Foundation
import SwiftProtocolsSQLite
import SwiftProtocolsCore

public class DataDragonSQLiteOpenHelper : BaseSQLiteOpenHelper {
    public required init(databaseFactory: Factory, databaseName: String?, version: Int) {
        super.init(databaseFactory: databaseFactory, databaseName: databaseName, version: version)
    }
    
    override public func onCreate(database: SQLiteDatabase) throws {
        try super.onCreate(database)
        
        try self.createRealmTable(database)
        try self.createChampionTable(database)
        try self.createChampionSkinTable(database)
    }
    
    override public func onDowngrade(database: SQLiteDatabase, fromOldVersion: Int, toNewVersion: Int) throws {
        try super.onDowngrade(database, fromOldVersion: fromOldVersion, toNewVersion: toNewVersion)
        
        try self.dropAndRecreateDatabase(database)
    }
    
    override public func onUpgrade(database: SQLiteDatabase, fromOldVersion: Int, toNewVersion: Int) throws {
        try super.onUpgrade(database, fromOldVersion: fromOldVersion, toNewVersion: toNewVersion)
        
        try self.dropAndRecreateDatabase(database)
    }
    
    // MARK: Private functions
    private func createChampionTable(database: SQLiteDatabase) throws {
        var sqlString = "CREATE TABLE " +
            DataDragonDatabase.Champion.table +
            " (" +
            DataDragonDatabase.Champion.Columns.id + " INTEGER NOT NULL PRIMARY KEY, " +
            DataDragonDatabase.Champion.Columns.name + " TEXT NOT NULL, " +
            DataDragonDatabase.Champion.Columns.title + " TEXT NOT NULL, " +
            DataDragonDatabase.Champion.Columns.blurb + " TEXT NOT NULL, " +
            DataDragonDatabase.Champion.Columns.key + " TEXT NOT NULL, " +
            DataDragonDatabase.Champion.Columns.imageUrl + " TEXT NOT NULL)"
        
        try database.executeUpdate(sqlString)
        
        sqlString = "CREATE INDEX champion_idx_01 ON " +
            DataDragonDatabase.Champion.table +
            "(" + DataDragonDatabase.Champion.Columns.name + ")"
        
        try database.executeUpdate(sqlString)
    }
    
    private func createChampionSkinTable(database: SQLiteDatabase) throws {
        let sqlString = "CREATE TABLE " +
            DataDragonDatabase.ChampionSkin.table +
            " (" +
            DataDragonDatabase.ChampionSkin.Columns.id + " INTEGER NOT NULL, " +
            DataDragonDatabase.ChampionSkin.Columns.championId + " INTEGER NOT NULL, " +
            DataDragonDatabase.ChampionSkin.Columns.skinNumber + " INTEGER NOT NULL, " +
            DataDragonDatabase.ChampionSkin.Columns.name + " TEXT NOT NULL, " +
            DataDragonDatabase.ChampionSkin.Columns.portraitImageUrl + " TEXT NOT NULL, " +
            DataDragonDatabase.ChampionSkin.Columns.landscapeImageUrl + " TEXT NOT NULL, " +
            "PRIMARY KEY(" +
            DataDragonDatabase.ChampionSkin.Columns.id + "," +
            DataDragonDatabase.ChampionSkin.Columns.skinNumber + ")"
        
        try database.executeUpdate(sqlString)
    }
    
    private func createRealmTable(database: SQLiteDatabase) throws {
        let sqlString = "CREATE TABLE " +
            DataDragonDatabase.Realm.table +
            " (" +
            DataDragonDatabase.Realm.Columns.realmVersion + " TEXT NOT NULL, " +
            DataDragonDatabase.Realm.Columns.cdn + " TEXT NOT NULL, " +
            DataDragonDatabase.Realm.Columns.championVersion + " TEXT NOT NULL, " +
            DataDragonDatabase.Realm.Columns.itemVersion + " TEXT NOT NULL, " +
            DataDragonDatabase.Realm.Columns.languageVersion + " TEXT NOT NULL, " +
            DataDragonDatabase.Realm.Columns.mapVersion + " TEXT NOT NULL, " +
            DataDragonDatabase.Realm.Columns.masteryVersion + " TEXT NOT NULL, " +
            DataDragonDatabase.Realm.Columns.profileIconVersion + " TEXT NOT NULL, " +
            DataDragonDatabase.Realm.Columns.profileIconMax + " INTEGER NOT NULL, " +
            DataDragonDatabase.Realm.Columns.runeVersion + " TEXT NOT NULL, " +
            DataDragonDatabase.Realm.Columns.summonerVersion + " TEXT NOT NULL)"
        
        try database.executeUpdate(sqlString)
     }
    
    private func dropTables(database: SQLiteDatabase) throws {
        try database.executeUpdate("DROP TABLE IF EXISTS " + DataDragonDatabase.Realm.table)
        try database.executeUpdate("DROP TABLE IF EXISTS " + DataDragonDatabase.Champion.table)
        try database.executeUpdate("DROP TABLE IF EXISTS " + DataDragonDatabase.ChampionSkin.table)
        
    }
    
    private func dropAndRecreateDatabase(database: SQLiteDatabase) throws {
        try self.dropTables(database)
        try self.onCreate(database)
    }
}