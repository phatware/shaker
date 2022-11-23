 //
 //  SourceCell.m
 //  Shaker
 //
 //  Created by Stanislav Miasnikov on 7/9/08.
 //  Copyright 2008 PhatWare Corp.. All rights reserved.
 //
 

#import "SourceCell.h"
#import "utils.h"

// cell identifier for this custom cell
NSString *kSourceCell_ID = @"SourceCell_ID";

@implementation SourceCell

@synthesize sourceLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier
{
	if (self = [super initWithStyle:style reuseIdentifier:identifier])
	{
		// turn off selection use
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		
		sourceLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		sourceLabel.opaque = NO;
        sourceLabel.textColor = [UIColor darkTextColor];
		sourceLabel.font = [UIFont systemFontOfSize:12];
        sourceLabel.textAlignment = NSTextAlignmentCenter;
        sourceLabel.minimumScaleFactor = 0.5;
        sourceLabel.adjustsFontSizeToFitWidth = YES;
		[self.contentView addSubview:sourceLabel];
	}
	return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	sourceLabel.frame = [self.contentView bounds];
}

#if !__has_feature(objc_arc)

- (void)dealloc
{
    [sourceLabel removeFromSuperview];
	[sourceLabel release];
    [super dealloc];
}

#endif

@end
