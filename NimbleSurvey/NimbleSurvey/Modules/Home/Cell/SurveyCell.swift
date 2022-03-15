//
//  SurveyCell.swift
//  NimbleSurvey
//
//  Created by Duc Bui on 15/03/2022.
//

import UIKit
import SDWebImage

class SurveyCell: UICollectionViewCell {
    static let cellIdentifier = "SurveyCell"
    
    @IBOutlet weak var surveyImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var survey: NimbleSurvey? {
        didSet {
            guard let survey = survey else {
                return
            }            
            surveyImageView.sd_setImage(with: URL(string: survey.attributes?.getLargeCoverImage() ?? ""))
            titleLabel.text = survey.attributes?.title
            descriptionLabel.text = survey.attributes?.desc
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
