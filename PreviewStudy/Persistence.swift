//
//  Persistence.swift
//  PreviewStudy
//
//  Created by Yang Xu on 2021/8/27.
//

import CoreData
import Foundation

class PersistenceController {
    static let shared = PersistenceController()
    var modelName: String { "PreviewStudy" }
    static let alwaysCopy = false // 是否始终覆盖catch中用于preview的DB

    init() {}

    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName, managedObjectModel: Self.model())
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    lazy var previewInMemory: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName, managedObjectModel: Self.model())
        container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        container.loadPersistentStores(completionHandler: { _, error in

            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        let viewContext = container.viewContext
        for _ in 0 ..< 10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return container
    }()

    lazy var previewInBundle: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName, managedObjectModel: Self.model())
        guard let url = Bundle.main.url(forResource: "PreviewStudy", withExtension: "sqlite") else {
            fatalError("无法从Bundle中获取数据库文件")
        }
        container.persistentStoreDescriptions.first?.url = url
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    lazy var previewInCatch: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName, managedObjectModel: Self.model())
        let fm = FileManager.default
        let DBName = "PreviewStudy"

        guard let sqliteURL = Bundle.main.url(forResource: DBName, withExtension: "sqlite"),
              let shmURL = Bundle.main.url(forResource: DBName, withExtension: "sqlite-shm"),
              let walURL = Bundle.main.url(forResource: DBName, withExtension: "sqlite-wal")
        else {
            fatalError("无法从Bundle中获取数据库文件")
        }
        let originalURLs = [sqliteURL, shmURL, walURL]

        let storeURL = fm.urls(for: .cachesDirectory, in: .userDomainMask).first!

        let sqliteTargetURL = storeURL.appendingPathComponent(sqliteURL.lastPathComponent)
        let shmTargetURL = storeURL.appendingPathComponent(shmURL.lastPathComponent)
        let walTargetURL = storeURL.appendingPathComponent(walURL.lastPathComponent)

        let tragetURLs = [sqliteTargetURL, shmTargetURL, walTargetURL]

        zip(originalURLs, tragetURLs).forEach { originalURL, targetURL in
            do {
                if fm.fileExists(atPath: targetURL.path) {
                    if Self.alwaysCopy {
                        try fm.removeItem(at: targetURL)
                        try fm.copyItem(at: originalURL, to: targetURL)
                    }
                } else {
                    try fm.copyItem(at: originalURL, to: targetURL)
                }
            } catch let error as NSError {
                fatalError(error.localizedDescription)
            }
        }

        container.persistentStoreDescriptions.first?.url = sqliteTargetURL
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
}

// MARK: - 读取momd文件

/*
 此段代码存在的目的是为了可以使用同一个momde文件创建多个container
 如果直接使用NSPersistentContainer的便捷方式来读取momd文件，当创建第二个container时，会出现无法读取的情况，从而创建失败。
 具研究，可能是由于Coredata对于一个momd只能生成一个实例而导致
 因此我们首先将momd文件读取到_momd中保存，在创建container时采用`NSPersistentContiner(name:managedObjectModel)`方法即可解决该问题

 这样我们就可以在预览中采用同应用程序完全不同的container而不会崩溃。
 */
extension PersistenceController {
    /// momd文件的唯一实例。使用loadModel调用而来
    private static var _model: NSManagedObjectModel?

    static func model(name: String = "PreviewStudy") -> NSManagedObjectModel {
        let bundle = Bundle.main

        if _model == nil {
            do {
                _model = try loadModel(name: name, bundle: bundle)
            } catch {
                let err = error.localizedDescription
                fatalError("数据库momd文件无法加载\(err)")
            }
        }
        // 如果无法获取必然需要崩溃
        return _model!
    }

    private static func loadModel(name: String, bundle: Bundle) throws -> NSManagedObjectModel {
        guard let modelURL = bundle.url(forResource: name, withExtension: "momd") else {
            fatalError("数据库momd文件无法加载")
        }
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("数据库momd文件无法解析")
        }
        return model
    }
}

extension PersistenceController {
    static let itemByEntityDescription: Item = {
        guard let entityDescription = model().entitiesByName["Item"] else {
            fatalError("abc")
        }
        let item = Item(entity: entityDescription, insertInto: nil)
        item.timestamp = Date.now
        return item
    }()
}
