//
//  Gender.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

enum Gender: String, Codable, CaseIterable, Identifiable {
    case male = "MALE"
    case female = "FEMALE"
    case other = "OTHER"
    var id: String { rawValue }
    var systemImageName: String {
        switch self {
        case .male: return "person.badge.plus"
        case .female: return "person.badge.minus"
        case .other: return "person"
        }
    }
    
    var representation: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        }
    }
}
