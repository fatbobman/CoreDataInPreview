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
        let container = NSPersistentContainer(name: modelName)
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    lazy var previewInMemory: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName)
        container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        container.loadPersistentStores(completionHandler: { _, error in

            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        let viewContext = container.viewContext
        for _ in 0..<10 {
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
        let container = NSPersistentContainer(name: modelName)
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
        let container = NSPersistentContainer(name: modelName)
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
