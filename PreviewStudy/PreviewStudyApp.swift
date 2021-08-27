//
//  PreviewStudyApp.swift
//  PreviewStudy
//
//  Created by Yang Xu on 2021/8/27.
//

import SwiftUI

@main
struct PreviewStudyApp: App {
    // 正常程序运行会设置成PersistenceController.shared.container
    var container = PersistenceController.shared.container

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, container.viewContext)
        }
    }
}


