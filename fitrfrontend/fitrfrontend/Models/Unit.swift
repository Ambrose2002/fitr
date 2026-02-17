//
//  Unit.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

/// Represents a unit of measurement.
enum Unit: String, Codable, CaseIterable {
    /// Kilograms
    case kg = "KG"
    
    /// Pounds
    case lb = "LB"
    
    /// Kilometers
    case km = "KM"
    
    /// Miles
    case mi = "MI"
    
    /// Centimeters
    case cm = "CM"
}
