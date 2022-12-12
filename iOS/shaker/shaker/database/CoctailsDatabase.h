//
//  CoctailsDatabase.h
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

typedef enum
{
    kGameFilterDefault,
    kGameFilterTop10,
    kGameFilterTop5,
    kGameFilterFree,
    kGameFilterCustom
} GameFilterSetting;

#define kShakerRecordChanged         @"ShakerRecordChanged"
#define kShakerRecipeUnlocked        @"ShakerRecipeUnlocked"
#define kShakerSyncDatabase          @"ShakerSyncDatabase"

@interface CoctailsDatabase : NSObject

- (Boolean) initializeDatabase;
- (sqlite3_int64) findRandomRecipe;

- (nullable NSDictionary *) getRecipe:(sqlite3_int64)record_id noImage:(BOOL)noImage;
- (nullable NSDictionary *) getRecipe:(sqlite3_int64)record_id alcohol:(BOOL)alcohol noImage:(BOOL)noImage;

- (sqlite3_int64) getUnlockedRecipeCount:(BOOL)alcohol;
- (nonnull NSDictionary<NSNumber *, NSArray<NSNumber *> *> * ) getUnlockedRecordList:(BOOL)alcohol filter:(nullable NSString * )filter sort:(nonnull NSString *)sort group:(nullable NSString *)group;
- (nullable NSArray *) getFavorites:(BOOL)like all:(BOOL)all isAlcogol:(BOOL)alcohol;
- (nullable NSDictionary *) getRecipeName:(sqlite3_int64)record_id alcohol:(BOOL)alcohol;

- (nullable NSArray <NSDictionary *> *) inredientsCategories;
- (nonnull NSString *) categoryName:(sqlite3_int64)cid;
- (nonnull NSString *) glassName:(sqlite3_int64)gid;
- (nullable NSArray <NSDictionary *> *) inredientsForCategory:(sqlite3_int64)category_id showall:(BOOL)showall filter:(nullable NSString *)filter sort:(nullable NSString *)sort;
- (BOOL) enableIngredient:(BOOL)enable withRecordid:(sqlite3_int64)recordid;
- (BOOL) enableAllIngredients:(BOOL)enable;
- (sqlite3_int64) countEnabledIngradients:(BOOL)enabled;

#ifdef IMAGE_SUPPORT
- (BOOL) updateUserPhoto:(nullable UIImage *)photo record:(sqlite3_int64)record_id;
- (nullable UIImage *) getPhoto:(sqlite3_int64)record_id alcohol:(BOOL)alcohol;
- (BOOL) updateUserRecord:(sqlite3_int64)record_id note:(nullable NSString *)note rating:(int)rating visible:(BOOL)visible;
#endif // IMAGE_SUPPORT

#ifdef IMPORT_FROM_CSV
- (BOOL) importFromCSV:(nonnull NSString *)filename toDatabase:(nonnull NSString *)db_file;
#endif

- (void)sync;

@property (nonatomic, assign) GameFilterSetting     gamefilter;
@property (nonatomic, assign) BOOL                  unlocked;

@end
