//
//  Goal.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

/// Represents a user's fitness goal.
enum Goal: String, Codable, CaseIterable, Identifiable {
    case strength = "STRENGTH"
    case hypertrophy = "HYPERTROPHY"
    case fatLoss = "FAT_LOSS"
    case general = "GENERAL"
    
    var id: String { rawValue }
    var description: String {
        switch self {
        case .strength: return "Build maximum strength"
        case .hypertrophy: return "Build muscle mass"
        case .fatLoss: return "Lose weight"
        case .general: return "General fitness"
        }
    }
    
    var representation: String {
        switch self {
        case .strength: return "Strength"
        case .hypertrophy: return "Hypertrophy"
        case .fatLoss: return "Fat Loss"
        case .general: return "General"
        }
    }
}
