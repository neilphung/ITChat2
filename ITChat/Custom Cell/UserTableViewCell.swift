//
//  UserTableViewCell.swift
//  ITChat
//
//  Created by NeilPhung on 8/3/19.
//  Copyright © 2019 NeilPhung. All rights reserved.
//

import UIKit

protocol UserTableViewCellDelegate {
    func didTapAvatarImage(indexPath: IndexPath)
}

class UserTableViewCell: UITableViewCell {
    
    
    var indexPath : IndexPath!
    
    var delegate: UserTableViewCellDelegate?
    
    let tapGestureRecogizer = UITapGestureRecognizer()
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
     
        tapGestureRecogizer.addTarget(self, action: #selector(self.avatarTap))
        
        avatarImageView.isUserInteractionEnabled = true
        
        avatarImageView.addGestureRecognizer(tapGestureRecogizer)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func geneateCellWith(fUser: FirebaseUser, indexPath: IndexPath){
        
        self.indexPath = indexPath
        
        fullNameLabel.text = fUser.fullname

        if fUser.avatar != "" {
            // convert imageData to image
            imageFromData(pictureData: fUser.avatar) { (avatarImage) in
                if avatarImage != nil {
                    //circleMasked : calculate size image
                    avatarImageView.image = avatarImage!.circleMasked
                }
            }
        }
    }
    
    //MARK: Helper Method
    
    @objc func avatarTap() {
        delegate!.didTapAvatarImage(indexPath: indexPath)
    }
    
}
