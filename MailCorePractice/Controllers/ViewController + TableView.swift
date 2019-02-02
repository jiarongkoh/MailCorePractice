//
//  ViewController + TableView.swift
//  MailCorePractice
//
//  Created by Koh Jia Rong on 2019/2/2.
//  Copyright © 2019 Koh Jia Rong. All rights reserved.
//

import UIKit

extension ViewController {
    
    func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let message = messages[indexPath.row]
        cell.textLabel?.text = message.subject ?? ""
        cell.detailTextLabel?.text = message.bodyText ?? ""
        return cell
    }    
    
    
}
