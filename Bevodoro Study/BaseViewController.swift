//
//  BaseViewController.swift
//  Bevodoro Study
//
//  Created by Anjie on 3/13/26.
//

import UIKit

class BaseViewController: UIViewController {
    
    var backgroundImageName: String { "texture_ut_light" }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set default background image for all views
        let bg = UIImageView(frame: view.bounds)
        bg.image = UIImage(named: backgroundImageName)
        bg.contentMode = .scaleAspectFill
        view.insertSubview(bg, at: 0)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
