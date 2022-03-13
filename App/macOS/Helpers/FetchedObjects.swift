//
//  FetchedObjects.swift
//  Pulse Pro
//
//  Created by Alexander Grebenyuk on 10/21/21.
//  Copyright © 2021 kean. All rights reserved.
//

import Foundation
import CoreData

final class FetchedObjects<Element: NSManagedObject>: Collection {
    typealias Index = Int
    
    private let controller: NSFetchedResultsController<Element>
            
    init(controller: NSFetchedResultsController<Element>) {
        self.controller = controller
    }
    
    var count: Int {
        controller.sections?.first?.numberOfObjects ?? 0
    }
    
    var startIndex: Int { 0 }
    var endIndex: Int { count }
    
    var isEmpty: Bool {
        count == 0
    }
    
    var indices: Range<Int> {
        startIndex..<endIndex
    }
    
    var first: Element? {
        guard !isEmpty else { return nil }
        return self[0]
    }
    
    subscript(index: Int) -> Element {
        controller.object(at: IndexPath(item: index, section: 0))
    }
    
    func index(after i: Int) -> Int {
        i + 1
    }
}

enum FetchedObjectsUpdate {
    case append(range: Range<Int>)
    case reload
}
