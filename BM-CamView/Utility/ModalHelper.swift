//
//  ModalHelper.swift
//  BM-CamView
//
//  Created by John Sherman on 10/15/23.
//



import Foundation
import UIKit

// Helper function to create a information modal window
func PresentModal(title: String, subtitle: String) {
    if let window = UIApplication.shared.keyWindow {
        let alert = UIAlertController(title: title, message: subtitle, preferredStyle: .actionSheet)
        
    }
}
