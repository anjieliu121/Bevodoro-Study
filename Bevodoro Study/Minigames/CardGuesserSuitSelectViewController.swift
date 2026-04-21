//
//  CardGuesserSuitSelectViewController.swift
//  Bevodoro Study
//
//  Created by Yim, Isabella H on 2/16/26.
//
//  Original Project: YimIsabella-HW4
//  EID: iy925
//  Course: CS371L
//

import UIKit

let suitCellIdentifier = "suitCell"

class CardGuesserSuitSelectViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var delegate: UIViewController!
    var suits: [String] = []
    
    @IBOutlet weak var suitTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        suitTableView.delegate = self
        suitTableView.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suits.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: suitCellIdentifier, for: indexPath)
        
        var content = cell.defaultContentConfiguration()
        content.text = suits[indexPath.row]
        cell.contentConfiguration = content
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        print("tableView selected indexPath=\(indexPath)=\(suits[indexPath.row])")
        // ask main to change its suit value
        let otherVC = delegate as! SuitChanger
        otherVC.changeSuit(newSuit: suits[indexPath.row])
        self.dismiss(animated: true)
    }
}
