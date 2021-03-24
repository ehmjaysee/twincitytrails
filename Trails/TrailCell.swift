//
//  TrailCell.swift
//  Trails 411
//
//  Created by Michael Chartier on 12/31/20.
//

import UIKit

class TrailCell: UITableViewCell
{
    @IBOutlet var O_icon: UIImageView!
    @IBOutlet var O_title: UILabel!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
