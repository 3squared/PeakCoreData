//
//  TestManagedObjectType.swift
//  PeakCoreData
//
//  Created by David Yates on 12/12/2016.
//  Copyright © 2016 3Squared Ltd. All rights reserved.
//

import XCTest
import CoreData
@testable import PeakCoreData

class ManagedObjectTypeTests: CoreDataTests {
    
    func testFetchObject() {
        let id = UUID().uuidString
        TestEntity.insertObject(with: id, in: viewContext)
        let object = TestEntity.fetchObject(with: id, in: viewContext)
        XCTAssertNotNil(object, "")
    }
    
    func testFirstMatchingPredicate() {
        let id = UUID().uuidString
        TestEntity.insertObject(with: id, in: viewContext)
        let object = TestEntity.first(in: viewContext, matching: NSPredicate(equalTo: id, keyPath: #keyPath(TestEntity.uniqueID)))
        XCTAssertNotNil(object, "")
    }
    
    func testFirstConfigured() {
        let count = 100
        CoreDataTests.createTestEntityManagedObjects(in: viewContext, count: count)
        let object = TestEntity.first(in: viewContext) { request in
            request.predicate = NSPredicate(equalTo: "Item " + String(45), keyPath: #keyPath(TestEntity.title))
        }
        XCTAssertNotNil(object, "")
    }
    
    func testInsertAndDeleteAll() {
        let count = 100
        CoreDataTests.createTestEntityManagedObjects(in: viewContext, count: count)
        
        let preDeleteCount = TestEntity.count(in: viewContext)
        XCTAssertEqual(preDeleteCount, count, "Count before delete should be same as count")
        
        TestEntity.delete(in: viewContext)
        
        let postDeleteCount = TestEntity.count(in: viewContext)
        XCTAssertEqual(postDeleteCount, 0, "Count after delete should be 0")
    }
    
    func testInsertAndDeleteSingleObject() {
        let count = 2
        let newObjects = CoreDataTests.createTestEntityManagedObjects(in: viewContext, count: count)
        let itemToDelete = newObjects.first!
        
        let preDeleteCount = TestEntity.count(in: viewContext)
        XCTAssertEqual(preDeleteCount, count, "\(preDeleteCount)")
        
        let predicate = TestEntity.uniqueObjectPredicate(with: itemToDelete.uniqueID!)
        TestEntity.delete(in: viewContext, matching: predicate)
        
        let postDeleteCount = TestEntity.count(in: viewContext)
        XCTAssertEqual(postDeleteCount, count-1, "\(postDeleteCount)")
    }
    
    func testInsertOrFetchObjectMethod() {
        let id = UUID().uuidString
        let item1 = TestEntity.fetchOrInsertObject(with: id, in: viewContext, with: managedObjectCache)
        let item2 = TestEntity.fetchOrInsertObject(with: id, in: viewContext, with: managedObjectCache)
        XCTAssertEqual(item1, item2)
    }
    
    func testBatchInsertOrUpdate() {
        let expectedCount = 100
        let intermediateItems = CoreDataTests.createTestIntermediateObjects(number: expectedCount, in: viewContext)
        
        let countBeforeUpdate = TestEntity.count(in: viewContext)
        XCTAssertEqual(countBeforeUpdate, (expectedCount/2), "Count before update should be equal to half expected count")

        TestEntity.insertOrUpdate(intermediates: intermediateItems, in: viewContext, with: managedObjectCache) {
            (intermediate, managedObject) in
            managedObject.title = intermediate.title
        }
        
        let countAfterUpdate = TestEntity.count(in: viewContext)
        XCTAssertEqual(countAfterUpdate, expectedCount, "Count after update should be equal to expected count")
    }
    
    func testBatchInsertCreatesDuplicatesInSomeSituations() {
        let expectedCount = 10
        let intermediateItems = CoreDataTests.createTestIntermediateObjects(number: expectedCount, in: viewContext)
        
        TestEntity.insertOrUpdate(intermediates: intermediateItems, in: viewContext, with: managedObjectCache) {
            (intermediate, managedObject) in
            managedObject.title = intermediate.title
            
            TestEntity.insertOrUpdate(intermediates: intermediateItems, in: viewContext, with: managedObjectCache) {
                (intermediate, managedObject) in
                managedObject.title = intermediate.title
            }
        }
        
        let countAfterUpdate = TestEntity.count(in: viewContext)
        // 10 unique ID exist, but because the optimised batch caches the inserted objects, it does not know about them.
        XCTAssertTrue(countAfterUpdate > expectedCount, "Count after update should be greater than the expected count")
    }
    
    func testBatchInsertPerformance() {
        let insertCount = 100
        let intermediateItems = CoreDataTests.createTestIntermediateObjects(number: insertCount, in: viewContext)
        measure {
            TestEntity.insertOrUpdate(intermediates: intermediateItems, in: viewContext) { (intermediate, managedObject) in
                managedObject.title = intermediate.title
            }
            
            TestEntity.insertOrUpdate(intermediates: intermediateItems, in: viewContext) { (intermediate, managedObject) in
                managedObject.title = intermediate.title
            }
            
            let countAfterUpdate = TestEntity.count(in: viewContext)
            XCTAssertEqual(countAfterUpdate, insertCount)
        }
    }
    
    func testBatchInsertPerformanceWithCache() {
        // The cache starts to significantly out-perform the non-cache version at 10,000
        let insertCount = 100
        let intermediateItems = CoreDataTests.createTestIntermediateObjects(number: insertCount, in: viewContext)
        measure {
            TestEntity.insertOrUpdate(intermediates: intermediateItems, in: viewContext, with: managedObjectCache) { (intermediate, managedObject) in
                managedObject.title = intermediate.title
            }
            
            TestEntity.insertOrUpdate(intermediates: intermediateItems, in: viewContext, with: managedObjectCache) { (intermediate, managedObject) in
                managedObject.title = intermediate.title
            }
            
            let countAfterUpdate = TestEntity.count(in: viewContext)
            XCTAssertEqual(countAfterUpdate, insertCount)
        }
    }
    
    func testNonBatchInsertPerformance() {
        let insertCount = 100
        let intermediateItems = CoreDataTests.createTestIntermediateObjects(number: insertCount, in: viewContext)
        measure {
            for intermediate in intermediateItems {
                TestEntity.fetchOrInsertObject(with: intermediate.uniqueID, in: viewContext) { entity in
                    entity.title = intermediate.title
                }
            }
            
            for intermediate in intermediateItems {
                TestEntity.fetchOrInsertObject(with: intermediate.uniqueID, in: viewContext) { entity in
                    entity.title = intermediate.title
                }
            }
            
            let countAfterUpdate = TestEntity.count(in: viewContext)
            XCTAssertEqual(countAfterUpdate, insertCount)
        }
    }
    
    func testNonBatchInsertPerformanceWithCache() {
        let insertCount = 100
        let intermediateItems = CoreDataTests.createTestIntermediateObjects(number: insertCount, in: viewContext)
        measure {
            for intermediate in intermediateItems {
                TestEntity.fetchOrInsertObject(with: intermediate.uniqueID, in: viewContext, with: managedObjectCache) { entity in
                    entity.title = intermediate.title
                }
            }
            
            for intermediate in intermediateItems {
                TestEntity.fetchOrInsertObject(with: intermediate.uniqueID, in: viewContext, with: managedObjectCache) { entity in
                    entity.title = intermediate.title
                }
            }
            
            let countAfterUpdate = TestEntity.count(in: viewContext)
            XCTAssertEqual(countAfterUpdate, insertCount)
        }
    }
    
    func testEncodingToData() {
        let id = UUID().uuidString
        let item1 = TestEntity.fetchOrInsertObject(with: id, in: viewContext, with: managedObjectCache)
        item1.title = "Hello"
        
        let data = try! item1.encode(to: TestEntityJSON.self, encoder: JSONEncoder())
        
        XCTAssertNotNil(data)
        
        let json = String(data: data, encoding: .utf8)
        
        XCTAssertEqual(json!, "{\"id\":\"\(item1.uniqueID!)\",\"title\":\"\(item1.title!)\"}")
    }
}
