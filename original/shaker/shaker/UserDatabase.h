//
//  UserDatabase.h
//  shaker
//
//  Created by Stanislav Miasnikov on 12/15/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#ifdef IMAGE_SUPPORT
#import <UIKit/UIKit.h>
#endif

@interface UserDatabase : NSObject

- (Boolean) initializeDatabase;
- (sqlite3_int64) createNewUserRecord:(sqlite3_int64)coctail_id;
- (nullable NSDictionary *) getUserRecord:(sqlite3_int64)record_id noImage:(BOOL)noImage;
- (BOOL) updateUserRecord:(sqlite3_int64)record_id note:(nullable NSString *)note rating:(int)rating visible:(BOOL)visible;
- (BOOL) updateUserPhoto:(nullable NSData *)photo record:(sqlite3_int64)record_id;

#ifdef IMAGE_SUPPORT
- (nullable UIImage *) getPhoto:(sqlite3_int64)record_id;
#endif

@end
