//
//  ViewController.swift
//  Project38
//
//  Created by Juan Torres on 6/14/20.
//  Copyright © 2020 Juan Torres. All rights reserved.
//

//load data model from application bundle and create NSManagedObjectModel
//create NSPersistenStoreCoordinator
//set up URL pointing to database on disk where our actual saved objects live(this will be an SQLite database named Project38.sqlite)
//load that database into the NSPersistentStoreCoordinator so it knows where we want it to save. if it doesn't exist it will be created automatically
//create an NSManageObjectContext and point it at the persistent store coordinator

//^^ that is what NSPersistentContainer does ^^

import UIKit
import CoreData

class ViewController: UITableViewController {
    //see top^^^
    var container: NSPersistentContainer!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //must be given the name of the COREDATAMODEL(.xcdatamodeld)
        container = NSPersistentContainer(name: "Project38")
        //loads saved data, or creates it if it doesn't exist
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error {
                print("unresolved error \(error)")
            }
        }
    }
    
    func saveContext(){
        // a viewContext managed object context where core data objects can be manipulated in ram
        
        if container.viewContext.hasChanges{
            do{
                try container.viewContext.save()
            } catch {
                print("an error has occured while saving: \(error)")
            }
        }
    }


}

