# Introduction
LoLDataDragonContentProvider is an iOS framework written in Swift 2. It is a set of classes that utilize the [swift-content-provider](https://github.com/JeffBNimble/swift-content-provider) for retrieving and storing League of Legends Champion and Champion skin data in a local SQLite database. It also uses [swift-protocols-sqlite](https://github.com/JeffBNimble/swift-protocols-sqlite) so that the framework is not dependent upon any specific SQLite library/framework allowing you to plugin your own implementation or use one of the existing adapters.

# Using the framework
Most of the code in the framework is private. Interfacing with the framework module is described using the [ModuleInterface](https://github.com/JeffBNimble/lol-datadragon-content-provider/blob/master/LoLDataDragonContentProvider/public/DataDragon.swift#L18) protocol. Specifically, you must create an instance of [DataDragon](https://github.com/JeffBNimble/lol-datadragon-content-provider/blob/master/LoLDataDragonContentProvider/public/DataDragon.swift#L34). DataDragon has one public function, sync() which will do all of the heavy lifting for you, including:
* Creating a local SQLite database (if necessary)
* Interrogating the [Riot Games API](https://developer.riotgames.com) to compare with the local data
* Syncing data from the Riot Games API, if necessary and storing data in the local SQLite database tables
* Caching all League of Legends champion images locally
* It also provides a [ContentProvider](https://github.com/JeffBNimble/swift-content-provider) as the [DataDragonContentProvider](https://github.com/JeffBNimble/lol-datadragon-content-provider/blob/master/LoLDataDragonContentProvider/public/content/provider/DataDragonContentProvider.swift) to give you access to the data from within your application.

# Example
An application which uses this framework is the [League of Legends Champion Browser](https://github.com/JeffBNimble/LoLBookOfChampions-swift2-sqlite).

# Installation
Use [Carthage](https://github.com/Carthage/Carthage). This framework requires the use of Swift 2 and XCode 7 or greater.

Specify the following in your Cartfile to use swift-adapters-fmdb:

```github "JeffBNimble/lol-datadragon-content-provider" "0.0.16"```

This library/framework has its own set of dependencies and you should use ```carthage update```. The framework dependencies are specified in the [Cartfile](https://github.com/JeffBNimble/lol-datadragon-content-provider/blob/master/Cartfile).
