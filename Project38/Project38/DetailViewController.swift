//
//  DetailViewController.swift
//  Project38
//
//  Created by Juan Torres on 6/14/20.
//  Copyright © 2020 Juan Torres. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    @IBOutlet var detailLabel: UILabel!
    var detailItem: Commit?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let detail = self.detailItem {
            detailLabel.text = detail.message
            //navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Commit" 1/\(detail.author.commits.count)", style: .plain, target: self, action: #selector(showAuthorCommits))
        }
    }
    

}
