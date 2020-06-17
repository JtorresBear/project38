//
//  Commit+CoreDataClass.swift
//  Project38
//
//  Created by Juan Torres on 6/16/20.
//  Copyright © 2020 Juan Torres. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Commit)
public class Commit: NSManagedObject {

    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
        print("Init called!")
    }
    
}
