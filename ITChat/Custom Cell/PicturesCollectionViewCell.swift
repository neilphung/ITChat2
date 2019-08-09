//
//  PicturesCollectionViewCell.swift
//  ITChat
//
//  Created by NeilPhung on 8/9/19.
//  Copyright © 2019 NeilPhung. All rights reserved.
//

import UIKit

class PicturesCollectionViewCell: UICollectionViewCell {
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    func generateCell(image: UIImage) {
        
        self.imageView.image = image
    }
}
