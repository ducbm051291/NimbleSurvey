//
//  SurveyCell.swift
//  NimbleSurvey
//
//  Created by Duc Bui on 15/03/2022.
//

import UIKit
import SDWebImage
import UIView_Shimmer

extension UILabel: ShimmeringViewProtocol { }

class SurveyCell: UICollectionViewCell {
    static let cellIdentifier = "SurveyCell"
    
    @IBOutlet weak var surveyImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var shimmeringAnimatedItems: [UIView] {
        [
            titleLabel,
            descriptionLabel
        ]
    }
    
    var survey: NimbleSurvey? {
        didSet {
            guard let survey = survey else {
                return
            }
            surveyImageView.sd_setImage(
                with: URL(string: survey.getLargeCoverImage()),
                placeholderImage: UIImage(named: "img_placeholder"))
            titleLabel.text = survey.title
            descriptionLabel.text = survey.desc
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }    
}
