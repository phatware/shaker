//
//  FavoritesViewController.h
//  shaker
//
//  Created by Stanislav Miasnikov on 7/3/15.
//  Copyright (c) 2015 PhatWare Corp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoctailsDatabase.h"

typedef enum
{
    kRecipeViewPresentationLike,
    kRecipeViewPresentationHate
    
} RecipesViewPresentationFilder;

@interface FavoritesViewController : UITableViewController

@property (nonatomic) RecipesViewPresentationFilder recipesPresnetation;
@property (nonatomic, strong) CoctailsDatabase * database;

@end
