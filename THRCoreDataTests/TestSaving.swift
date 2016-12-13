//
//  TestSaving.swift
//  THRCoreData
//
//  Created by David Yates on 13/12/2016.
//  Copyright © 2016 3Squared Ltd. All rights reserved.
//

import XCTest
import CoreData
@testable
import THRCoreData

class TestSaving: TestCase {
    
    func test_ThatSavingMainContext_WithChangesSucceeds_CompletionHandlerIsCalled() {
        
        let mainContext = coreDataManager.mainContext
        
        self.createTestObjects(inContext: mainContext, count: 100)
        
        var didSaveMain = false
        expectation(forNotification: Notification.Name.NSManagedObjectContextDidSave.rawValue, object: mainContext) { notification in
            didSaveMain = true
            return true
        }
        
        var didUpdateBackground = false
        expectation(forNotification: Notification.Name.NSManagedObjectContextObjectsDidChange.rawValue, object: coreDataManager.backgroundContext) { notification in
            didUpdateBackground = true
            return true
        }
        
        let saveExpectation = expectation(description: #function)
        
        coreDataManager.save(context: mainContext) { result in
            XCTAssertTrue(result == SaveResult.success, "Save should not error")
            saveExpectation.fulfill()
        }
        
        // THEN: then the main and background contexts are saved and the completion handler is called
        waitForExpectations(timeout: 1.0, handler: { error in
            XCTAssertNil(error, "Expectation should not error")
            XCTAssertTrue(didSaveMain, "Main context should be saved")
            XCTAssertTrue(didUpdateBackground, "Background context should be updated")
        })
    }
    
    func test_ThatSavingBackgroundContext_WithChangesSucceeds_CompletionHandlerIsCalled() {
        
        let backgroundContext = coreDataManager.backgroundContext
        
        self.createTestObjects(inContext: backgroundContext, count: 100)
        
        var didSaveBackground = false
        expectation(forNotification: Notification.Name.NSManagedObjectContextDidSave.rawValue, object: backgroundContext) { notification in
            didSaveBackground = true
            return true
        }
        
        var didUpdateMain = false
        expectation(forNotification: Notification.Name.NSManagedObjectContextObjectsDidChange.rawValue, object: coreDataManager.mainContext) { notification in
            didUpdateMain = true
            return true
        }
        
        let saveExpectation = expectation(description: #function)
        
        coreDataManager.save(context: backgroundContext) { result in
            XCTAssertTrue(result == SaveResult.success, "Save should not error")
            saveExpectation.fulfill()
        }
        
        // THEN: then the main and background contexts are saved and the completion handler is called
        waitForExpectations(timeout: 1.0, handler: { error in
            XCTAssertNil(error, "Expectation should not error")
            XCTAssertTrue(didSaveBackground, "Main context should be saved")
            XCTAssertTrue(didUpdateMain, "Background context should be updated")
        })
    }
    
    func test_ThatSavingMainContextAynchronously_WithChangesSucceeds_CompletionHandlerIsCalled() {
        
        let wait = false
        
        let mainContext = coreDataManager.mainContext
        
        self.createTestObjects(inContext: mainContext, count: 100)
        
        var didSaveMain = false
        expectation(forNotification: Notification.Name.NSManagedObjectContextDidSave.rawValue, object: mainContext) { notification in
            didSaveMain = true
            return true
        }
        
        var didUpdateBackground = false
        expectation(forNotification: Notification.Name.NSManagedObjectContextObjectsDidChange.rawValue, object: coreDataManager.backgroundContext) { notification in
            didUpdateBackground = true
            return true
        }
        
        let saveExpectation = expectation(description: #function)
        
        coreDataManager.save(context: mainContext, wait: wait) { result in
            XCTAssertTrue(result == SaveResult.success, "Save should not error")
            saveExpectation.fulfill()
        }
        
        // THEN: then the main and background contexts are saved and the completion handler is called
        waitForExpectations(timeout: 1.0, handler: { error in
            XCTAssertNil(error, "Expectation should not error")
            XCTAssertTrue(didSaveMain, "Main context should be saved")
            XCTAssertTrue(didUpdateBackground, "Background context should be updated")
        })
    }
    
    func test_ThatSavingBackgroundContextAsynchronously_WithChangesSucceeds_CompletionHandlerIsCalled() {
        
        let wait = false

        let backgroundContext = coreDataManager.backgroundContext
        
        self.createTestObjects(inContext: backgroundContext, count: 100)
        
        var didSaveBackground = false
        expectation(forNotification: Notification.Name.NSManagedObjectContextDidSave.rawValue, object: backgroundContext) { notification in
            didSaveBackground = true
            return true
        }
        
        var didUpdateMain = false
        expectation(forNotification: Notification.Name.NSManagedObjectContextObjectsDidChange.rawValue, object: coreDataManager.mainContext) { notification in
            didUpdateMain = true
            return true
        }
        
        let saveExpectation = expectation(description: #function)
        
        coreDataManager.save(context: backgroundContext, wait: wait) { result in
            XCTAssertTrue(result == SaveResult.success, "Save should not error")
            saveExpectation.fulfill()
        }
        
        // THEN: then the main and background contexts are saved and the completion handler is called
        waitForExpectations(timeout: 1.0, handler: { error in
            XCTAssertNil(error, "Expectation should not error")
            XCTAssertTrue(didSaveBackground, "Main context should be saved")
            XCTAssertTrue(didUpdateMain, "Background context should be updated")
        })
    }
    
    func test_ThatAsyncSaveMainContext_WithoutChanges_ReturnsImmediately() {
        
        let wait = false

        var didCallCompletion = false
        
        // WHEN: we attempt to save the context asynchronously
        coreDataManager.save(context: coreDataManager.mainContext, wait: wait) { result in
            didCallCompletion = true
        }
        
        // THEN: the save operation is ignored
        XCTAssertFalse(didCallCompletion, "Save should be ignored")
    }
    
    func test_ThatAsyncSaveBackgroundContext_WithoutChanges_ReturnsImmediately() {
        
        let wait = false
        
        var didCallCompletion = false
        
        // WHEN: we attempt to save the context asynchronously
        coreDataManager.save(context: coreDataManager.backgroundContext, wait: wait) { result in
            didCallCompletion = true
        }
        
        // THEN: the save operation is ignored
        XCTAssertFalse(didCallCompletion, "Save should be ignored")
    }
    
    func test_ThatSavingChildContext_SucceedsAndSavesParentMainContext() {
        
        let childContext = coreDataManager.createChildContext(withConcurrencyType: .mainQueueConcurrencyType)
        
        self.createTestObjects(inContext: childContext, count: 100)
        
        var didSaveChild = false
        expectation(forNotification: Notification.Name.NSManagedObjectContextDidSave.rawValue, object: childContext) { notification in
            didSaveChild = true
            return true
        }
        
        var didSaveMain = false
        expectation(forNotification: Notification.Name.NSManagedObjectContextDidSave.rawValue, object: coreDataManager.mainContext) { notification in
            didSaveMain = true
            return true
        }
        
        var didUpdateBackground = false
        expectation(forNotification: Notification.Name.NSManagedObjectContextObjectsDidChange.rawValue, object: coreDataManager.backgroundContext) { notification in
            didUpdateBackground = true
            return true
        }
        
        let saveExpectation = expectation(description: #function)
        
        coreDataManager.save(context: childContext) {
            result in
            XCTAssertTrue(result == .success, "Save should not error")
            saveExpectation.fulfill()
        }
        
        // THEN: then all contexts are saved, synchronized and the completion handler is called
        waitForExpectations(timeout: defaultTimeout, handler: { (error) -> Void in
            XCTAssertNil(error, "Expectation should not error")
            XCTAssertTrue(didSaveChild, "Child context should be saved")
            XCTAssertTrue(didSaveMain, "Main context should be saved")
            XCTAssertTrue(didUpdateBackground, "Background context should be updated")
        })
    }
    
    func test_ThatSavingChildContext_SucceedsAndSavesParentBackgroundContext() {
        
        let childContext = coreDataManager.createChildContext(withConcurrencyType: .privateQueueConcurrencyType)
        
        self.createTestObjects(inContext: childContext, count: 100)
        
        var didSaveChild = false
        expectation(forNotification: Notification.Name.NSManagedObjectContextDidSave.rawValue, object: childContext) { notification in
            didSaveChild = true
            return true
        }
        
        var didSaveBackground = false
        expectation(forNotification: Notification.Name.NSManagedObjectContextDidSave.rawValue, object: coreDataManager.backgroundContext) { notification in
            didSaveBackground = true
            return true
        }
        
        var didUpdateMain = false
        expectation(forNotification: Notification.Name.NSManagedObjectContextObjectsDidChange.rawValue, object: coreDataManager.mainContext) { notification in
            didUpdateMain = true
            return true
        }
        
        let saveExpectation = expectation(description: #function)
        
        coreDataManager.save(context: childContext) {
            result in
            XCTAssertTrue(result == .success, "Save should not error")
            saveExpectation.fulfill()
        }
        
        // THEN: then all contexts are saved, synchronized and the completion handler is called
        waitForExpectations(timeout: defaultTimeout, handler: { (error) -> Void in
            XCTAssertNil(error, "Expectation should not error")
            XCTAssertTrue(didSaveChild, "Child context should be saved")
            XCTAssertTrue(didSaveBackground, "Main context should be saved")
            XCTAssertTrue(didUpdateMain, "Background context should be updated")
        })
    }
    
    func test_ThatSavingChildContextAsynchronously_SucceedsAndSavesParentMainContext() {
        
        let childContext = coreDataManager.createChildContext(withConcurrencyType: .mainQueueConcurrencyType)
        
        self.createTestObjects(inContext: childContext, count: 100)
        
        var didSaveChild = false
        expectation(forNotification: Notification.Name.NSManagedObjectContextDidSave.rawValue, object: childContext) { notification in
            didSaveChild = true
            return true
        }
        
        var didSaveMain = false
        expectation(forNotification: Notification.Name.NSManagedObjectContextDidSave.rawValue, object: coreDataManager.mainContext) { notification in
            didSaveMain = true
            return true
        }
        
        var didUpdateBackground = false
        expectation(forNotification: Notification.Name.NSManagedObjectContextObjectsDidChange.rawValue, object: coreDataManager.backgroundContext) { notification in
            didUpdateBackground = true
            return true
        }
        
        let saveExpectation = expectation(description: #function)
        
        var didCallCompletion = false
        coreDataManager.save(context: childContext, wait: false) {
            result in
            didCallCompletion = true
            XCTAssertTrue(result == .success, "Save should not error")
            saveExpectation.fulfill()
        }
        
        // THEN: then all contexts are saved, synchronized and the completion handler is called
        waitForExpectations(timeout: defaultTimeout, handler: { (error) -> Void in
            XCTAssertNil(error, "Expectation should not error")
            XCTAssertTrue(didCallCompletion, "Completion should be called")
            XCTAssertTrue(didSaveChild, "Child context should be saved")
            XCTAssertTrue(didSaveMain, "Main context should be saved")
            XCTAssertTrue(didUpdateBackground, "Background context should be updated")
        })
    }
    
    func test_ThatSavingChildContextAsynchronously_SucceedsAndSavesParentBackgroundContext() {
        
        let childContext = coreDataManager.createChildContext(withConcurrencyType: .privateQueueConcurrencyType)
        
        self.createTestObjects(inContext: childContext, count: 100)
        
        var didSaveChild = false
        expectation(forNotification: Notification.Name.NSManagedObjectContextDidSave.rawValue, object: childContext) { notification in
            didSaveChild = true
            return true
        }
        
        var didSaveBackground = false
        expectation(forNotification: Notification.Name.NSManagedObjectContextDidSave.rawValue, object: coreDataManager.backgroundContext) { notification in
            didSaveBackground = true
            return true
        }
        
        var didUpdateMain = false
        expectation(forNotification: Notification.Name.NSManagedObjectContextObjectsDidChange.rawValue, object: coreDataManager.mainContext) { notification in
            didUpdateMain = true
            return true
        }
        
        let saveExpectation = expectation(description: #function)
        
        var didCallCompletion = false
        coreDataManager.save(context: childContext, wait: false) {
            result in
            didCallCompletion = true
            XCTAssertTrue(result == .success, "Save should not error")
            saveExpectation.fulfill()
        }
        
        XCTAssertFalse(didCallCompletion, "Save should be ignored")
        
        // THEN: then all contexts are saved, synchronized and the completion handler is called
        waitForExpectations(timeout: defaultTimeout, handler: { (error) -> Void in
            XCTAssertNil(error, "Expectation should not error")
            XCTAssertTrue(didCallCompletion, "Completion should be called")
            XCTAssertTrue(didSaveChild, "Child context should be saved")
            XCTAssertTrue(didSaveBackground, "Main context should be saved")
            XCTAssertTrue(didUpdateMain, "Background context should be updated")
        })
    }
}
