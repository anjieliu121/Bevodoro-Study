//
//  UserManager.swift
//  Bevodoro Study
//
//  Created by Anjie on 3/11/26.
//

import Foundation

class UserManager {
    static let shared = UserManager()
    var currentUser: User?
    private init() {}
}
