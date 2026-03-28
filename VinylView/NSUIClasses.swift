//
//  NSUIImage.swift
//  VinylView
//
//  Created by Enie Weiß on 11.04.23.
//

import SwiftUI
#if os(iOS) || os(watchOS) || os(tvOS)
import UIKit

public typealias NSUIImage = UIImage
public typealias NSUIViewRepresentable = UIViewRepresentable
#elseif os(macOS)
import AppKit

public typealias NSUIImage = NSImage
public typealias NSUIViewRepresentable = NSViewRepresentable

#endif
