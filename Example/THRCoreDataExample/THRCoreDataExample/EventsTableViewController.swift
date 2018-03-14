//
//  EmptyTableViewController.swift
//  THRCoreDataExample
//
//  Created by David Yates on 21/12/2016.
//  Copyright © 2016 3Squared Ltd. All rights reserved.
//

import UIKit
import CoreData
import THRResult
import THRCoreData

class EventsTableViewController: UITableViewController, PersistentContainerSettable {

    var persistentContainer: NSPersistentContainer!
    
    var operationQueue: OperationQueue {
        let queue = OperationQueue()
        return queue
    }
    
    private var dataSource: FetchedTableViewDataSource<EventsTableViewController>!
    
    private lazy var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .long
        df.timeStyle = .short
        return df
    }()
    
    lazy var emptyView: UIView? = {
        let nibViews = Bundle.main.loadNibNamed(EmptyView.nibName, owner: self, options: nil)
        let view = nibViews?.first as! EmptyView
        view.titleLabel.text = "No events in table view"
        view.subtitleLabel.text = "Not a sausage."
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        setupTableView()
    }
    
    @IBAction func deleteButtonTapped(_ sender: Any) {
        Event.batchDelete(in: viewContext)
    }
    
    @IBAction func addButtonTapped(_ sender: Any) {
        let numberOfItems = 100
        var intermediateItems: [EventJSON] = []
        for item in 0..<numberOfItems {
            let id = UUID().uuidString
            let date = Date().addingTimeInterval(-Double(item))
            let intermediate = EventJSON(uniqueID: id, date: date)
            intermediateItems.append(intermediate)
        }
        let operation = CoreDataBatchImportOperation<EventJSON>(with: persistentContainer)
        operation.input = Result { intermediateItems }
        operationQueue.addOperation(operation)
    }

    private func setupTableView() {
        let frc = NSFetchedResultsController(fetchRequest: Event.sortedFetchRequest(), managedObjectContext: viewContext, sectionNameKeyPath: nil, cacheName: nil)
        dataSource = FetchedTableViewDataSource(tableView: tableView, cellIdentifier: EventTableViewCell.cellIdentifier, fetchedResultsController: frc, delegate: self)
        dataSource.animateUpdates = true
        dataSource.onDidChangeContent = {
            print("Table View - Something changed")
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension EventsTableViewController: FetchedTableViewDataSourceDelegate {
    
    func configure(_ cell: EventTableViewCell, with object: Event) {
        cell.textLabel?.text = dateFormatter.string(from: (object.date! as Date))
    }
    
    func canEditRow(at indexPath: IndexPath) -> Bool {
        return true
    }
    
    func commit(editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            let objectToDelete = dataSource.object(at: indexPath)
            viewContext.delete(objectToDelete)
            try! viewContext.save()
        default:
            break
        }
    }
}
