//
//  RowView.swift
//  RowView
//
//  Created by Yang Xu on 2021/8/27.
//

import Foundation
import SwiftUI

struct RowView: View {
    let item: Item
    var body: some View {
        VStack {
            Text("Item at \(item.timestamp!, formatter: itemFormatter)")
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct RowView_Previews: PreviewProvider {
    static var previews: some View {
        RowView(item: PersistenceController.shared.sampleItem)
            
        RowView(item: PersistenceController.itemByEntityDescription)
    }
}

extension PersistenceController {
    var sampleItem: Item {
        let context = Self.shared.previewInMemory.viewContext
        let item = Item(context: context)
        // 调整数据，可以直接在预览中看到变化
        item.timestamp = Date().addingTimeInterval(30000000)
        return item
    }
}
