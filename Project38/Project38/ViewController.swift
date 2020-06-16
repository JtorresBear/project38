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
    //objects that are to be saved to and loaded from
    var commits = [Commit]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //must be given the name of the COREDATAMODEL(.xcdatamodeld)
        container = NSPersistentContainer(name: "Project38")
        //loads saved data, or creates it if it doesn't exist
        container.loadPersistentStores { (storeDescription, error) in
            
            // this instructs core data to allow updates to objects if an object exists in the data store with message A
            //and an object with the same attribute("sha", which is a constraint in the data model) with message B
            //the in memory bersion overwrites the data store version
            self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            if let error = error {
                print("unresolved error \(error)")
            }
        }
        
        performSelector(inBackground: #selector(fetchCommits), with: nil)
        
        loadSavedData()
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

    @objc func fetchCommits(){
        if let data = try? String(contentsOf: URL(string: "https://api.github.com/repos/apple/swift/commits?per_page=100")!) {
            //give data to swiftyJSON to parse
            let jsonCommits = JSON(parseJSON: data)
            
            //read the commits back out
            let jsonCommitArray = jsonCommits.arrayValue
            
            print("Recieved\(jsonCommitArray.count) new commits")
            
            DispatchQueue.main.async { [unowned self] in
                for jsonCommit in jsonCommitArray{
                    let commit = Commit(context: self.container.viewContext)
                    self.configure(commit: commit, usingJSON: jsonCommit)
                }
                
                self.saveContext()
                self.loadSavedData()
            }
        }
    }
    
    func configure(commit: Commit, usingJSON json: JSON){
        commit.sha = json["sha"].stringValue
        commit.message = json["commit"]["message"].stringValue
        commit.url = json["html_url"].stringValue
        
        //converts a ISO8601 date to a regular date and back from string. if it fails
        //we get todays date.
        let formatter = ISO8601DateFormatter()
        commit.date = formatter.date(from: json["commit"]["commiter"]["date"].stringValue) ?? Date()
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commits.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Commit", for: indexPath)
        
        let commit = commits[indexPath.row]
        cell.textLabel!.text = commit.message
        cell.detailTextLabel!.text = commit.date.description
        
        return cell
    }
    
    func loadSavedData(){
        //creates an NSRequest
        let request = Commit.createFetchRequest()
        //creates a sort of the date data in Commit object
        //date is the key or Commit.date and it sorts it in descending order
        let sort = NSSortDescriptor(key: "date", ascending: false)
        //uses the sort we initialized
        request.sortDescriptors = [sort]
        
        do{
            //loads the commits into the commits array using the request we specified
            commits = try container.viewContext.fetch(request)
            print("Got\(commits.count) commits")
            tableView.reloadData()
        } catch {
            print("Fetch Failed")
        }
    }

}

