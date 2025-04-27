//
//  NotificationModels.swift
//  Choir
//
//  Created by Augment on 6/10/24.
//

import Foundation

// MARK: - Device Token Registration

/// Request to register a device token for push notifications
struct DeviceTokenRegistrationRequest: APIRequest {
    typealias Response = DeviceTokenRegistrationResponse

    let deviceToken: String
    let walletAddress: String

    var endpoint: String { "notifications/register-device" }

    enum CodingKeys: String, CodingKey {
        case deviceToken = "device_token"
        case walletAddress = "wallet_address"
    }
}

/// Response from device token registration
struct DeviceTokenRegistrationResponse: Decodable {
    let success: Bool
    let message: String?
}
