//
//  Error+Cancellation.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 3/9/26.
//

import Foundation

extension Error {
  var isCancellation: Bool {
    if self is CancellationError {
      return true
    }

    if let urlError = self as? URLError, urlError.code == .cancelled {
      return true
    }

    let nsError = self as NSError
    return nsError.domain == NSURLErrorDomain && nsError.code == URLError.cancelled.rawValue
  }
}
