//
//  UserModel.swift
//  Berkeleychat
//
//  Created by David Zechowy on 6/22/24.
//

import Foundation

@Observable
class UserModel {
    var email: String
    var name: String
    var profilePhotoUrl: String
    var major: String
    var courses: [String]
    var intro: Data

    init(email: String, name: String, profilePhotoUrl: String, major: String, courses: [String], intro: Data) {
        self.email = email
        self.name = name
        self.profilePhotoUrl = profilePhotoUrl
        self.major = major
        self.courses = courses
        self.intro = intro
    }
}
