//
//  CallDirectoryHandler.swift
//  CallDirectoryExtension
//
//  Created by Chuck Harvey on 9/28/26.
//

import Foundation
import CallKit

class CallDirectoryHandler: CXCallDirectoryProvider {

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self

        // Clear existing entries to prevent duplicates
        context.removeAllIdentificationEntries()

        // Add identification entries from app settings
        addIdentificationPhoneNumbers(to: context)

        context.completeRequest()
    }

    private func addIdentificationPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        // App Group shared defaults
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.yourname.SeniorScamShield") else { return }
       
        let guardianPhoneRaw = sharedDefaults.string(forKey: "guardian_phone") ?? ""
        let guardianName = sharedDefaults.string(forKey: "guardian_name") ?? "Guardian"
       
        // CallKit requires numbers formatted strictly as 64-bit integers with country code (e.g., 15551234567)
        var phoneNumbersToIdentify: [(CXCallDirectoryPhoneNumber, String)] = []
       
        if let cleanNumber = formatPhoneNumberToCXType(guardianPhoneRaw) {
            let label = "SeniorScamShield: \(guardianName) (Trusted)"
            phoneNumbersToIdentify.append((cleanNumber, label))
        }
       
        // IMPORTANT: CallKit requires entries to be sorted in numerical ascending order
        phoneNumbersToIdentify.sort { $0.0 < $1.0 }
       
        for (phoneNumber, label) in phoneNumbersToIdentify {
            context.addIdentificationEntry(withNextSequentialPhoneNumber: phoneNumber, label: label)
        }
    }

    private func formatPhoneNumberToCXType(_ rawPhone: String) -> CXCallDirectoryPhoneNumber? {
        // Strip non-digit characters
        let digitsOnly = rawPhone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
       
        guard !digitsOnly.isEmpty else { return nil }
       
        // Ensure US country code (1) is prefixed if 10 digits are provided
        var formatted = digitsOnly
        if formatted.count == 10 {
            formatted = "1" + formatted
        }
       
        return CXCallDirectoryPhoneNumber(formatted)
    }
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {

    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        print("Call Directory extension request failed: \(error.localizedDescription)")
    }
}
