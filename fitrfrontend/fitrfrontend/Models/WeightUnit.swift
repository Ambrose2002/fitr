//
//  WeightUnit.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/19/26.
//


enum WeightUnit: String, CaseIterable, Identifiable {
    case kg = "Kilograms"
    case lb = "Pounds"
    var id: String { rawValue }
    var abbreviation: String {
        switch self {
        case .kg: return "KG"
        case .lb: return "LB"
        }
    }
}
