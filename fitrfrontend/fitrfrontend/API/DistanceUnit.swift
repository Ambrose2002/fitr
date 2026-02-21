//
//  DistanceUnit.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/19/26.
//

enum DistanceUnit: String, CaseIterable, Identifiable {
    case km = "Kilometers"
    case mi = "Miles"
    var id: String { rawValue }
    var abbreviation: String {
        switch self {
        case .km: return "KM"
        case .mi: return "MI"
        }
    }
}
