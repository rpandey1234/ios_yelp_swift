//
//  SwitchCell.swift
//  Yelp
//
//  Created by Rahul Pandey on 10/20/16.
//  Copyright © 2016 Timothy Lee. All rights reserved.
//

import UIKit

@objc protocol SwitchCellDelegate {
    @objc optional func switchCell(switchCell: SwitchCell, didChange value: Bool)
}

class SwitchCell: UITableViewCell, SwitchCellDelegate {
    @IBOutlet weak var switchLabel: UILabel!
    @IBOutlet weak var onSwitch: UISwitch!
    
    weak var delegate: SwitchCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func switchValueChanged(_ sender: AnyObject) {
        print("value changed")
        delegate?.switchCell?(switchCell: self, didChange: onSwitch.isOn)
    }
}
