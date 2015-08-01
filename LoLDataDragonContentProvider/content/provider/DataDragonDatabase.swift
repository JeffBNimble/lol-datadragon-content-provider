//
//  DataDragonDatabase.swift
//  LoLDataDragonContentProvider
//
//  Created by Jeff Roberts on 7/31/15.
//  Copyright © 2015 nimbleNoggin.io. All rights reserved.
//

import Foundation
import SwiftContentProvider

public class DataDragonDatabase {
    public static var contentAuthority : String?
    
    public static var contentUri : Uri {
        get {
            return NSURL(string: self.contentAuthorityBase)!
        }
    }
    
    private static var contentAuthorityBase: String {
        get {
            return "content://" + DataDragonDatabase.contentAuthority!
        }
    }
    
    public class Champion {
        public static var table : String {
            get {
                return "champion"
            }
        }
        
        public static var uri : Uri {
            get {
                return DataDragonDatabase.contentUri.URLByAppendingPathComponent("champion")
            }
        }
        
        public static func uri(championId : Int) -> Uri {
            return self.uri.URLByAppendingPathComponent("\(championId)")
        }
        
        public class Columns {
            public static var blurb : String {
                get { return "blurb" }
            }
            
            public static var id : String {
                get { return "id" }
            }
            
            public static var imageUrl : String {
                get { return "image_url" }
            }
            
            public static var key : String {
                get { return "key" }
            }
            
            public static var name : String {
                get { return "name" }
            }
            
            public static var title : String {
                get { return "title" }
            }
        }
    }
    
    public class ChampionSkin {
        public static var table : String {
            get {
                return "champion_skin"
            }
        }
        
        public static var uri : Uri {
            get {
                return Champion.uri.URLByAppendingPathComponent("skin")
            }
        }
        
        public static func uri(skinId : Int) -> Uri {
            return self.uri.URLByAppendingPathComponent("\(skinId)")
        }
        
        public class Columns {
            public static var championId : String {
                get { return Champion.Columns.id }
            }
            
            public static var id : String {
                get { return "skin_id" }
            }
            
            public static var portraitImageUrl : String {
                get { return "portrait_image_url" }
            }
            
            public static var name : String {
                get { return Champion.Columns.name }
            }
            
            public static var skinNumber : String {
                get { return "skin_number" }
            }
            
            public static var landscapeImageUrl : String {
                get { return "landscape_image_url" }
            }
        }
        
    }

    
    public class Realm {
        public static var table : String {
            get {
                return "realm"
            }
        }
        
        public static var uri : Uri {
            get {
                return DataDragonDatabase.contentUri.URLByAppendingPathComponent("realm")
            }
        }
        
        public static func uri(realmVersion : String) -> Uri {
            return self.uri.URLByAppendingPathComponent(realmVersion)
        }
        
        public class Columns {
            public static var championVersion : String {
                get { return "champion_version" }
            }
            
            public static var cdn : String {
                get { return "cdn" }
            }
            
            public static var itemVersion : String {
                get { return "item_version" }
            }
            
            public static var languageVersion : String {
                get { return "language_version" }
            }
            
            public static var mapVersion : String {
                get { return "map_version" }
            }
            
            public static var masteryVersion : String {
                get { return "mastery_version" }
            }
            
            public static var profileIconMax : String {
                get { return "profile_icon_max" }
            }
            
            public static var profileIconVersion : String {
                get { return "profile_icon_version" }
            }
            
            public static var realmVersion : String {
                get { return "realm_version" }
            }
        
            public static var runeVersion : String {
                get { return "rune_version" }
            }
            
            public static var summonerVersion : String {
                get { return "summoner_version" }
            }
        }
    }
    
}