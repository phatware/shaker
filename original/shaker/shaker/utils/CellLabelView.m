//
//  CellLabelView.m
//  Shaker
//
//  Created by Stanislav Miasnikov on 7/9/08.
//  Copyright 2008 PhatWare Corp.. All rights reserved.
//

#import "CellLabelView.h"
#import "UIConst.h"
#import "utils.h"

// cell identifier for this custom cell
NSString* kCellLabelView_ID = @"CellLavelView_ID";

@implementation CellLabelView

@synthesize textLabel;
@synthesize nameLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier
{
	self = [super initWithStyle:style reuseIdentifier:identifier];
	if (self)
	{
		// turn off selection use
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		
		nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		nameLabel.opaque = NO;
        nameLabel.font = [UIFont systemFontOfSize:kTitleFontSize]; // [UIFont boldSystemFontOfSize:kTitleFontSize];
		
		textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		textLabel.opaque = NO;
		textLabel.numberOfLines = 1;
		textLabel.textAlignment = NSTextAlignmentLeft;
		textLabel.lineBreakMode = NSLineBreakByWordWrapping;
		textLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
		textLabel.font = [UIFont systemFontOfSize:kLabelFontSize];
		
		imageView = nil;

		[self.contentView addSubview:nameLabel];
		[self.contentView addSubview:textLabel];
		
	}
	return self;
}

- (void)set_Image:(NSString *)imageName
{	
	if ( nil == imageView )
	{
		UIImage * Image = [UIImage imageNamed:imageName];
		CGRect frame = CGRectMake(	0.0, 0.0, Image.size.width, Image.size.height );
		imageView = [[UIImageView alloc] initWithFrame:frame];
		imageView.image = Image;
		[self.contentView addSubview:imageView];
	}
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	CGRect contentRect = [self.contentView bounds];
	
	int		yOffset = kCellTopOffset;
	if ( nameLabel.text != nil && [nameLabel.text length] > 0 )
	{
		// In this example we will never be editing, but this illustrates the appropriate pattern
		nameLabel.frame = CGRectMake(contentRect.origin.x + kCellLeftOffset, yOffset, 
							  contentRect.size.width - 2 * kCellLeftOffset, kCellLabelHeight );
		yOffset += (kCellLabelHeight + kInsertValue);
	}
	// inset the text view within the cell
	if (contentRect.size.width > (kInsertValue*2) && contentRect.size.height > (2 * kCellLabelHeight) )	// but not if the cell is too small
	{
		int yImage = 0;
		if ( nil != imageView )
		{
			yImage = imageView.frame.size.height + kInsertValue;
		}
		
		textLabel.frame  = CGRectMake(contentRect.origin.x + kCellLeftOffset,
									  contentRect.origin.y + yOffset - kInsertValue,
									  contentRect.size.width - (kCellLeftOffset*2),
									  kCellLabelHeight);
	}
	if ( nil != imageView )
	{
		imageView.frame = CGRectMake( (contentRect.size.width - imageView.frame.size.width)/2,
		(kInsertValue + yOffset + 1 + textLabel.frame.size.height),
		imageView.frame.size.width, imageView.frame.size.height );
	}
}

#if !__has_feature(objc_arc)
- (void)dealloc
{
    [textLabel removeFromSuperview];
	[nameLabel removeFromSuperview];
	[imageView removeFromSuperview];
    [textLabel release];
	[nameLabel release];
	[imageView release];
    [super dealloc];
}
#endif //

@end
