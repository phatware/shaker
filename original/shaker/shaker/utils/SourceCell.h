//
//  SourceCell.m
//  Shaker
//
//  Created by Stanislav Miasnikov on 7/9/08.
//  Copyright 2008 PhatWare Corp.. All rights reserved.
//

#import <UIKit/UIKit.h>

// cell identifier for this custom cell
extern NSString *kSourceCell_ID;

@interface SourceCell : UITableViewCell
{
	UILabel	*sourceLabel;
}

@property (nonatomic, retain) UILabel *sourceLabel;

@end
