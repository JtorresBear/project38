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

class ViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    //see top^^^
    var container: NSPersistentContainer!
    //objects that are to be saved to and loaded from
    //var commits = [Commit]()
    
    //a  predicate is a filter. you specify the criteria you want to match.
    // core data will ensure only matching objects get returned.
    var commitPredicate: NSPredicate?
    
    //
    var fetchedResultsController: NSFetchedResultsController<Commit>!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(changeFilter))
        
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
        let newestCommitDate = getNewestCommitDate()
        
        
        
        if let data = try? String(contentsOf: URL(string: "https://api.github.com/repos/apple/swift/commits?per_page=100&since=\(newestCommitDate)")!) {
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
    
    func getNewestCommitDate() -> String{
        let formatter = ISO8601DateFormatter()
        
        let newest = Commit.createFetchRequest()
        let sort = NSSortDescriptor(key: "date", ascending: false)
        
        newest.sortDescriptors = [sort]
        //sets a fetch limit for nsRequests
        newest.fetchLimit = 1
        
        if let commits = try? container.viewContext.fetch(newest){
            if commits.count > 0 {
                
                
                return formatter.string(from: commits[0].date.addingTimeInterval(1))
            }
        }
        
        return formatter.string(from: Date(timeIntervalSince1970: 0))
    }
    
    func configure(commit: Commit, usingJSON json: JSON){
        commit.sha = json["sha"].stringValue
        commit.message = json["commit"]["message"].stringValue
        commit.url = json["html_url"].stringValue
        
        //converts a ISO8601 date to a regular date and back from string. if it fails
        //we get todays date.
        let formatter = ISO8601DateFormatter()
        commit.date = formatter.date(from: json["commit"]["committer"]["date"].stringValue) ?? Date()
        
        var commitAuthor: Author!
        
        //see if this author exists already
        let authorRequest = Author.createFetchRequest()
        authorRequest.predicate = NSPredicate(format: "name == %@", json["commit"]["committer"]["name"].stringValue)
        
        if let authors = try? container.viewContext.fetch(authorRequest) {
            if authors.count > 0 {
                //we have this author already
                commitAuthor = authors[0]
            }
        }
        
        if commitAuthor == nil {
            // we didn't find a saved author - create new one!
            print("no author found")
            let author = Author(context: container.viewContext)
            author.name = json["commit"]["committer"]["name"].stringValue
            author.email = json["commit"]["committer"]["email"].stringValue
            commitAuthor = author
        }
        //use author , either saved or new
        commit.author = commitAuthor
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Commit", for: indexPath)
        
        let commit = fetchedResultsController.object(at: indexPath)
        cell.textLabel!.text = commit.message
        cell.detailTextLabel!.text = "By \(commit.author.name) on \(commit.date.description)"
        
        return cell
    }
    
    func loadSavedData(){
        //New Load method
        if fetchedResultsController == nil {
            //creates an NSRequest
            let request = Commit.createFetchRequest()
            //creates a sort order of the date data in Commit object
            //date is the key or Commit.date and it sorts it in descending order
            let sort = NSSortDescriptor(key: "date", ascending: false)
            //uses the sort we initialized
            request.sortDescriptors = [sort]
            request.fetchBatchSize = 20
            
            fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: container.viewContext, sectionNameKeyPath: "author.name", cacheName: nil)
            fetchedResultsController.delegate = self
            
        }
        
        fetchedResultsController.fetchRequest.predicate = commitPredicate
        
        do{
            try fetchedResultsController.performFetch()
            tableView.reloadData()
        } catch {
            print("Fetch Failed")
        }
        
        
        // in the change filter function. we change the class varibable commit predicate
        //so we use that as the request predicate to change the tableview values.
        //request.predicate = commitPredicate
        
//        do{
//            //loads the commits into the commits array using the request we specified
//            commits = try container.viewContext.fetch(request)
//            print("Got \(commits.count) commits")
//            tableView.reloadData()
//        } catch {
//            print("Fetch Failed")
//        }
    }
    
    @objc func changeFilter(){
        let ac = UIAlertController(title: "Filter Commits", message: nil, preferredStyle: .actionSheet)
        //1 the CONTAINS[c] part is an operator just like == except more useful for this app. CONTAINS means it will for sure see "fix" and the [c] means its case-insensitive so fix, Fix, FIX will be found or any combo
        ac.addAction(UIAlertAction(title: "Show only fixes", style: .default, handler: { [unowned self](_) in
            self.commitPredicate = NSPredicate(format: "message CONTAINS[c] 'fix'")
            self.loadSavedData()
        }))
        //2 BEGINSWITH works like contains but the matching text must be at the start of a string. the NOT keyword means don't find the message that begins with.
        ac.addAction(UIAlertAction(title: "Ignore Pull Requests", style: .default, handler: { [unowned self](_) in
            self.commitPredicate = NSPredicate(format: "NOT message BEGINSWITH 'Merge pull request'")
            self.loadSavedData()
        }))
        //3 in this predicate we're using date to find commits only 43,200 seconds ago.
        ac.addAction(UIAlertAction(title: "Show only Recent", style: .default, handler: { [unowned self](_) in
            let twelveHoursAgo = Date().addingTimeInterval(-43200)
            self.commitPredicate = NSPredicate(format: "date > %@", twelveHoursAgo as NSDate)
            self.loadSavedData()
        }))
        //4 puts commitPredicate back to nil so all request show again.
        ac.addAction(UIAlertAction(title: "Show all Commits", style: .default, handler: { [unowned self] _ in
            self.commitPredicate = nil
            self.loadSavedData()
        }))
        //5
        ac.addAction(UIAlertAction(title: "show only Durian commits", style: .default, handler: { [unowned self](_) in
            self.commitPredicate = NSPredicate(format: "author.name == 'Joe Groff'")
            self.loadSavedData()
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(ac, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "Detail") as? DetailViewController {
            vc.detailItem = fetchedResultsController.object(at: indexPath)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let commit = fetchedResultsController.object(at: indexPath)
            container.viewContext.delete(commit)
            
            
            saveContext()
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fetchedResultsController.sections![section].name
    }

}

