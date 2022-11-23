//
//  CellLabelView.h
//  Shaker
//
//  Created by Stanislav Miasnikov on 7/9/08.
//  Copyright 2008 PhatWare Corp.. All rights reserved.
//

#import <UIKit/UIKit.h>

// cell identifier for this custom cell
extern NSString *kCellLabelView_ID;

@interface CellLabelView : UITableViewCell
{
    UILabel *		textLabel;
	UILabel	*		nameLabel;
	UIImageView *	imageView;
}

- (void)set_Image:(NSString *)imageName;

@property (nonatomic, retain) UILabel *textLabel;
@property (nonatomic, retain) UILabel *nameLabel;

@end
