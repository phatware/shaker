//
//  SearchScopeController.h
//  shaker
//
//  Created by Stanislav Miasnikov on 7/7/15.
//  Copyright (c) 2015 PhatWare Corp. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>


typedef enum {
    kSearchScopeTtitle = 0,
    kSearchScopeIngredients = 1,
    kSearchScopeInstructions = 2,
} SearchScopeType;

@protocol SearchScopeProtocol <NSObject>

- (void) searchScopeSelected:(SearchScopeType)scope;

@end

@interface SearchScopeController : WKInterfaceController

@end
