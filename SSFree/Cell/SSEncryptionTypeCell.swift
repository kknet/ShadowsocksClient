//
//  SSEncryptionTypeCell.swift
//  SSFree
//
//  Created by Ning Li on 2019/12/17.
//  Copyright © 2019 Ning Li. All rights reserved.
//

import UIKit

let kEncryptionTypeCellId = "kEncryptionTypeCellId"

/// 加密方式 cell
class SSEncryptionTypeCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var selectedIconView: UIImageView!
    
    func set(_ model: SSEncryptionTypeModel) {
        nameLabel.text = model.name
        selectedIconView.isHidden = !(model.isSelected ?? false)
    }
}
