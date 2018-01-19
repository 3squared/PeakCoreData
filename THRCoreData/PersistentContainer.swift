//
//  PersistentContainer.swift
//  THRCoreData
//
//  Created by David Yates on 20/02/2017.
//  Copyright © 2017 3Squared Ltd. All rights reserved.
//

import CoreData

public typealias SetupCompletionType = (PersistentStoreDescription, Error?) -> ()

/// A container that encapsulates the Core Data stack in your application.
/// - warning:
/// There is a missing full stop in the storeURL. Fixing this would break apps that already use PersistentContainer.
/// - warning:
/// It is recommended that you do not use this in new apps that only support iOS 10+. Use NSPersistentContainer instead.
public final class PersistentContainer {
    
    internal enum ModelFileExtension: String {
        case bundle = "momd"
        case sqlite = "sqlite"
    }
    
    /**
     The managed object context associated with the main queue. (read-only)
     
     - discussion:  This property contains a reference to the `NSManagedObjectContext` that is created and owned by the persistent container which is associated with the main queue of the application. 
     This context is created automatically as part of the initialization of the persistent container. 
     This context is configured to be generational and to automatically consume save notifications from other contexts. 
     This context is associated directly with the NSPersistentStoreCoordinator.
     */
    public let mainContext: NSManagedObjectContext
    
    /**
     The persistent store description used to create the persistent stores referenced by this persistent container.
     
     - discussion:  If you want to override the type (or types) of persistent store used by the persistent container, you can set this property with a `PersistentStoreDescription` object.
     If you will be configuring a custom persistent store description, you must set this property before calling loadPersistentStores(completionHandler:).
     */
    public var persistentStoreDescription: PersistentStoreDescription?
    
    /**
     The name of this persistent container. (read-only)
     
     - discussion:  This property is passed in as part of the initialization of the persistent container.
     This name is used to locate the `NSManagedObjectModel` (if the `NSManagedObjectModel` object is not passed in as part of the initialization) and is used to name the persistent store.
    */
    public let name: String
    
    /**
     The model associated with this persistent container. (read-only)
     
     - discussion:  This property contains a reference to the `NSManagedObjectModel` object associated with this persistent container.
     */
    public let managedObjectModel: NSManagedObjectModel
    
    /**
     The persistent store coordinator associated with this persistent container. (read-only)
     
     - discussion:  When the persistent container is initialized, it creates a persistent store coordinator as part of that initialization. That persistent store coordinator is referenced in this property.
     */
    public let persistentStoreCoordinator: NSPersistentStoreCoordinator
    
    /**
     Initializes a persistent container with the given data model name.
     
     - parameter    name: The name used by the persistent container.
     
     - returns:     A persistent container initialized with the given name.
     
     - discussion:  By default, the provided name value is used to name the persistent store and is used to look up the name of the `NSManagedObjectModel` object to be used with the `PersistentContainer` object.
    */
    public convenience init(name: String) {
        guard let modelURL = Bundle.main.url(forResource: name, withExtension: ModelFileExtension.bundle.rawValue) else {
            fatalError("*** Error loading model URL for model named \(name)")
        }
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("*** Error loading managed object model at url: \(modelURL)")
        }
        self.init(name: name, model: model)
    }
    
    /**
     Initializes a persistent container with the given name and model.
     
     - parameter    name: The name used by the persistent container.
     - parameter    model: The managed object model to be used by the persistent container.

     - returns:     A persistent container initialized with the given name and model.
     
     - discussion:  By default, the provided name value of the container is used as the name of the persisent store associated with the container. Passing in the `NSManagedObjectModel` object overrides the lookup of the model by the provided name value.
     */
    public init(name: String, model: NSManagedObjectModel) {
        self.name = name
        self.managedObjectModel = model
        self.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        let mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        mainContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        mainContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyStoreTrumpMergePolicyType)
        mainContext.name = "THRCoreData.PersistentContainer.context.main"
        self.mainContext = mainContext
    }

    /**
     Instructs the persistent container to load the persistent stores.

     - parameter    block: Once the loading of the persistent stores has completed, this block will be executed on the calling thread.

     - discussion:  Once the persistent container has been initialized, you need to execute loadPersistentStores(completionHandler:)
     to instruct the container to load the persistent stores and complete the creation of the Core Data stack.
     Once the completion handler has fired, the stack is fully initialized and is ready for use.
    */
    public func loadPersistentStores(completionHandler: @escaping SetupCompletionType = { _, _ in }) {
        let description: PersistentStoreDescription
        if let persistentStoreDescription = persistentStoreDescription {
            description = persistentStoreDescription
        } else {
            let storeURL = PersistentContainer.defaultDirectoryURL().appendingPathComponent(name + ModelFileExtension.sqlite.rawValue)
            description = PersistentStoreDescription(url: storeURL)
        }
        
        do {
            try self.persistentStoreCoordinator.addPersistentStore(ofType: description.type.value,
                                                                   configurationName: nil,
                                                                   at: description.url,
                                                                   options: description.options)
            completionHandler(description, nil)
        } catch {
            completionHandler(description, error)
        }
    }
}

// MARK: - Public Methods

extension PersistentContainer {
    
    /**
     Creates the default directory for the persistent stores.
     
     - return:      An URL that references the directory in which the persistent store will be located or are currently located.
    */
    public class func defaultDirectoryURL() -> URL {
        let searchPathDirectory = FileManager.SearchPathDirectory.documentDirectory
        
        do {
            return try FileManager.default.url(for: searchPathDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: true)
        } catch {
            fatalError("*** Error finding default directory: \(error)")
        }
    }
    
    /**
     Creates a private managed object context
     
     - return:      A newly created private managed object context.
     */
    public func newBackgroundContext() -> NSManagedObjectContext {
        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSManagedObjectContextDidSave, object: backgroundContext, queue: nil) { [weak self] (notification) in
            guard let strongSelf = self else { return }
            strongSelf.mainContext.perform {
                strongSelf.mainContext.mergeChanges(fromContextDidSave: notification)
            }
        }
        
        return backgroundContext
    }
}