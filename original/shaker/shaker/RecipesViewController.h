//
//  RecipesViewController.h
//  shaker
//
//  Created by Stanislav Miasnikov on 12/24/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoctailsDatabase.h"
#import "MKStoreManager.h"

@interface RecipesViewController : UITableViewController <UISearchControllerDelegate, UISearchResultsUpdating, MKStoreKitDelegate, UISearchBarDelegate>


@property (nonatomic, strong) CoctailsDatabase * database;


@end
