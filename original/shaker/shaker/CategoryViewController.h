//
//  CategoryViewController.h
//  shaker
//
//  Created by Stanislav Miasnikov on 12/25/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoctailsDatabase.h"

@protocol CategoryViewControllerDelegate <NSObject>

- (void) categoryViewControllerPlayPressed;

@end

@interface CategoryViewController : UITableViewController

@property (nonatomic, strong) CoctailsDatabase * database;
@property (nonatomic, weak) id <CategoryViewControllerDelegate> delegate;

@end

