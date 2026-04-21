//
//  CardGuesserPipSelectViewController.swift
//  Bevodoro Study
//
//  Created by Yim, Isabella H on 2/16/26.
//
//  original Project: YimIsabella-HW4
//  EID: iy925
//  Course: CS371L
//

import UIKit

let pipCellIdentifier = "pipCell"

class CardGuesserPipSelectViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var delegate: UIViewController!
    var pips: [String] = []
    @IBOutlet weak var pipTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pipTableView.delegate = self
        pipTableView.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pips.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: pipCellIdentifier, for: indexPath)
        
        var content = cell.defaultContentConfiguration()
        content.text = pips[indexPath.row]
        cell.contentConfiguration = content
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        print("tableView selected indexPath=\(indexPath)=\(pips[indexPath.row])")
        // ask main to change its pip value
        let otherVC = delegate as! PipChanger
        otherVC.changePip(newPip: pips[indexPath.row])
        self.dismiss(animated: true)
    }
}
