//
//  UserModel.swift
//  Berkeleychat
//
//  Created by David Zechowy on 6/22/24.
//

import Foundation

@Observable
class UserModel: Hashable, Equatable, Identifiable {
    var id: String
    var email: String
    var name: String
    var profilePhotoUrl: String
    var major: String
    var courses: [String]
    var introUrl: String
    var messages: [String]

    init(email: String, name: String, profilePhotoUrl: String, major: String, courses: [String], introUrl: String, messages: [String]) {
        id = email
        self.email = email
        self.name = name
        self.profilePhotoUrl = profilePhotoUrl
        self.major = major
        self.courses = courses
        self.introUrl = introUrl
        self.messages = messages
    }

    static func == (lhs: UserModel, rhs: UserModel) -> Bool {
        return lhs.email == rhs.email &&
            lhs.name == rhs.name &&
            lhs.profilePhotoUrl == rhs.profilePhotoUrl &&
            lhs.major == rhs.major &&
            lhs.courses == rhs.courses &&
            lhs.introUrl == rhs.introUrl &&
            lhs.messages == rhs.messages
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(email)
        hasher.combine(name)
        hasher.combine(profilePhotoUrl)
        hasher.combine(major)
        hasher.combine(courses)
        hasher.combine(introUrl)
        hasher.combine(messages)
    }
}
