//
//  IngredientsViewController.h
//  shaker
//
//  Created by Stanislav Miasnikov on 12/25/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoctailsDatabase.h"

@interface IngredientsViewController : UITableViewController <UISearchControllerDelegate, UISearchResultsUpdating>

@property (nonatomic, strong) CoctailsDatabase * database;
@property (nonatomic, assign) sqlite3_int64 category_id;

@end
