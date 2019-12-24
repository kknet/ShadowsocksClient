//
//  SSRouteModel.swift
//  SSFree
//
//  Created by Ning Li on 2019/12/17.
//  Copyright © 2019 Ning Li. All rights reserved.
//

import Foundation

class SSRouteModel: Codable {
    var id: UUID
    var ip_address: String
    var port: Int
    var password: String
    var encryptionType: String
    var isSelected: Bool?
    
    init(ip_address: String, port: String, password: String, encryptionType: String) {
        self.id = UUID()
        self.ip_address = ip_address
        self.port = Int(port) ?? 0
        self.password = password
        self.encryptionType = encryptionType
        self.isSelected = false
    }
}
