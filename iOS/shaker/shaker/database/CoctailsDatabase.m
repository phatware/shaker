//
//  CoctailsDatabase.m
//  shaker
//
//  Created by Stanislav Miasnikov on 12/15/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import "CoctailsDatabase.h"
#import "UserDatabase.h"
#import "NSFileManager+Folder.h"

#ifndef IMPORT_FROM_CSV
#import "shaker-Swift.h"
#endif // IMPORT_FROM_CSV

#define MAX_RETRY_NUMBER    1024
#define TOP10USED           501
#define TOP5USED            1001

@interface MyData : NSObject

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSString * category;
@property (nonatomic, strong) NSString * alcohol;
@property (nonatomic, strong) NSString * glass;
@property (nonatomic, strong) NSString * ingr;
@property (nonatomic, strong) NSString * instr;
@property (nonatomic, strong) NSString * shop;


@end

@implementation MyData

@end


@interface CoctailsDatabase()
{
    BOOL            modified;
    BOOL            initialized;
    sqlite3 *       sqlDatabaseRef;
    sqlite3_int64    adrinks_count;
    sqlite3_int64    sdrinks_count;
}

@property (nonatomic, strong) NSString * databasename;
@property (nonatomic, strong) UserDatabase * userdatabase;

#ifndef IMPORT_FROM_CSV
@property (nonatomic, strong) WatchConnect * wconnect;
#endif

@end

@implementation CoctailsDatabase


- (void)sync
{
#ifndef IMPORT_FROM_CSV
    [self.wconnect sendMessageWithMessage:@{ @"event" : kShakerSyncDatabase }];
#endif
}

// Creates a writable copy of the bundled default database in the application Documents directory.
- (BOOL)createEditableCopyOfDatabaseIfNeeded
{
    // First, test for existence.
    NSFileManager *	fileManager = [NSFileManager defaultManager];
    NSError *		error = nil;
    BOOL res = [fileManager fileExistsAtPath:self.databasename];
//    if ( !res )
//    {
//        NSString *  documentsPath = [NSFileManager documentsPath];
//        NSString *  name = [documentsPath stringByAppendingPathComponent:@"shaker.sql"];
//        res = [fileManager fileExistsAtPath:name];
//        if ( res )
//        {
//            res = [NSFileManager moveToShared:@"shaker.sql" error:&error];
//            if ( res )
//            {
//                res = [fileManager fileExistsAtPath:self.databasename];
//            }
//            else
//            {
//                NSLog( @"Cant move from local to shared with message '%@'.", [error localizedDescription]);
//            }
//        }
//    }
    if ( !res )
    {
        // The writable database does not exist, so copy the default to the appropriate location.
        NSString *	defaultDatabase = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"shaker.sql"];
        res = [fileManager copyItemAtPath:defaultDatabase toPath:self.databasename error:&error];
        if ( ! res )
        {
            NSLog( @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
        }
    }
    
    return res;
}

- (sqlite3_int64) getItemCount:(NSString *)tableName filter:(NSString *)filter
{
    sqlite3_stmt *  statement = NULL;
    sqlite3_int64   itemCount = 0;
    
    NSString * strCount = @"*";
    if ( filter != nil )
    {
        NSRange range = [filter rangeOfString:@"="];
        if ( range.location != NSNotFound )
            strCount = [filter substringToIndex:range.location];
    }
    
    NSString * strSql = [NSString stringWithFormat:@"SELECT count(%@) FROM %@", strCount, tableName];
    
    if ( filter != nil )
    {
        strSql = [NSString stringWithFormat:@"%@ WHERE %@", strSql, filter];
    }

    if (sqlite3_prepare_v2(sqlDatabaseRef, [strSql UTF8String], -1, &statement, NULL) == SQLITE_OK)
    {
        // We "step" through the results - once for each row
        if (sqlite3_step(statement) == SQLITE_ROW)
            itemCount = sqlite3_column_int64(statement, 0);
        
        // "Finalize" the statement - releases the resources associated with the statement.
        sqlite3_finalize(statement);
    }
    else
    {
        NSLog( @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
        itemCount = -1;
    }
    return itemCount;
}

- (NSArray *) getFavorites:(BOOL)like all:(BOOL)all isAlcogol:(BOOL)alcohol
{
    NSString *	strSQL = [NSString stringWithFormat:@"SELECT record_id, user_id, name, shopping FROM %@ WHERE unlocked=1 ORDER BY name ASC", (alcohol ? @"harddrinks" : @"softdrinks")];
    NSMutableArray * array = [[NSMutableArray alloc] init];

    sqlite3_stmt *	statement = NULL;
    if ( sqlite3_prepare_v2(  sqlDatabaseRef, [strSQL UTF8String], -1, &statement, NULL) == SQLITE_OK )
    {
        while ( sqlite3_step(statement) == SQLITE_ROW )
        {
            sqlite3_int64 record_id = sqlite3_column_int64( statement, 0 );
            sqlite3_int64 user_id = sqlite3_column_int64( statement, 1 );
            const unsigned char * name = sqlite3_column_text( statement, 2 );
            const unsigned char * shop = sqlite3_column_text( statement, 3 );
            if ( record_id > 0 && user_id > 0 && name != NULL && shop != NULL )
            {
                NSNumber *      num;
                NSDictionary *  user_info = [self.userdatabase getUserRecord:user_id noImage:YES];
                int             rating = all ? 0 : [[user_info objectForKey:@"userrating"] intValue];
                NSString *      nam = [NSString stringWithUTF8String:(char *)name];
                NSString *      shopping = [NSString stringWithUTF8String:(char *)shop];
                NSInteger       index = 0;
                if ( like && rating >= 5 && (!all) )
                {
                    for ( index = 0; index < [array count]; index++ )
                    {
                        num = [[array objectAtIndex:index] objectForKey:@"rating"];
                        if ( rating > [num intValue] )
                            break;
                        if ( rating == [num intValue] )
                        {
                            NSComparisonResult res = [nam caseInsensitiveCompare:[[array objectAtIndex:index] objectForKey:@"name"]];
                            if ( res == NSOrderedSame || res == NSOrderedAscending )
                            {
                                break;
                            }
                        }
                    }
                }
                else if ( (!like) && rating > 0 && rating < 5 && (!all) )
                {
                    for ( index = 0; index < [array count]; index++ )
                    {
                        num = [[array objectAtIndex:index] objectForKey:@"rating"];
                        if ( rating < [num intValue] )
                            break;
                        if ( rating == [num intValue] )
                        {
                            if ( rating == [num intValue] )
                            {
                                NSComparisonResult res = [nam caseInsensitiveCompare:[[array objectAtIndex:index] objectForKey:@"name"]];
                                if ( res == NSOrderedSame || res == NSOrderedAscending )
                                {
                                    break;
                                }
                            }
                        }
                    }
                }
                else
                {
                    rating = 0;
                }
                if ( rating > 0 || all )
                {
                    NSDictionary * dict = @{ @"id" : [NSNumber numberWithLongLong:record_id],
                                             @"name" : nam,
                                             @"shopping" : shopping,
                                             @"rating" : [NSNumber numberWithInt:rating] };
                    if ( index < [array count] && (!all) )
                        [array insertObject:dict atIndex:index];
                    else
                        [array addObject:dict];
                }
            }
        }
    }
    else
    {
        NSLog( @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
        return nil;
    }
    sqlite3_finalize( statement );
    return (NSArray *)array;
}

-(NSArray *)fetchTableNames
{
    sqlite3_stmt* statement;
    NSString *query = @"SELECT name FROM sqlite_master WHERE type=\'table\'";
    int retVal = sqlite3_prepare_v2(sqlDatabaseRef,
                                    [query UTF8String],
                                    -1,
                                    &statement,
                                    NULL);
    
    NSMutableArray *selectedRecords = [NSMutableArray array];
    if ( retVal == SQLITE_OK )
    {
        while(sqlite3_step(statement) == SQLITE_ROW )
        {
            NSString *value = [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 0)
                                                 encoding:NSUTF8StringEncoding];
            [selectedRecords addObject:value];
        }
    }
    
    sqlite3_clear_bindings(statement);
    sqlite3_finalize(statement);
    
    return selectedRecords;
}

- (NSDictionary<NSNumber *, NSArray<NSNumber *> *> *) getUnlockedRecordList:(BOOL)alcohol filter:(NSString *)filter sort:(NSString *)sort group:(NSString *)group range:(NSRange)range
{
    sqlite3_int64 count = [self getUnlockedRecipeCount:alcohol];
    if (count < 1)
        return [NSDictionary dictionary];
    
    NSTimeInterval ts = [NSDate timeIntervalSinceReferenceDate];
    
    // build SQL statment
    NSString *	strSQL = @"SELECT record_id";
    if (nil != group)
    {
        strSQL = [strSQL stringByAppendingString:@", "];
        strSQL = [strSQL stringByAppendingString:group];
    }
    strSQL = [strSQL stringByAppendingFormat:@" FROM %@", (alcohol ? @"harddrinks" : @"softdrinks")];
    if ( (! self.unlocked) || filter != nil )
    {
        strSQL = [strSQL stringByAppendingString:@" WHERE "];
        if ( ! self.unlocked )
        {
            strSQL = [strSQL stringByAppendingString:@"unlocked=1"];
            if ( filter != nil )
                strSQL = [strSQL stringByAppendingString:@" AND "];
        }
        if ( filter != nil )
            strSQL = [strSQL stringByAppendingString:filter];
    }
    
    strSQL = [strSQL stringByAppendingString:@" ORDER BY "];
    if (nil != group)
    {
        strSQL = [strSQL stringByAppendingString:group];
        strSQL = [strSQL stringByAppendingString:@" ASC, "];
    }
    strSQL = [strSQL stringByAppendingString:sort];
    if (range.length > 0)
    {
        strSQL = [strSQL stringByAppendingFormat:@" LIMIT %lu, %lu", (unsigned long)range.location, (unsigned long)range.length];
    }

    NSMutableDictionary * result = [[NSMutableDictionary alloc] init];
    @autoreleasepool
    {
        NSMutableArray * array = [[NSMutableArray alloc] initWithCapacity:(NSUInteger)count];
        sqlite3_int64 group_id = -1;
        
        sqlite3_stmt *	statement = NULL;
        if ( sqlite3_prepare_v2( sqlDatabaseRef, [strSQL UTF8String], -1, &statement, NULL) == SQLITE_OK )
        {
            while ( sqlite3_step(statement) == SQLITE_ROW )
            {
                int index = 0;
                sqlite3_int64 record_id = sqlite3_column_int64(statement, index++);
                if ( record_id > 0)
                {
                    [array addObject:[NSNumber numberWithLongLong:record_id]];
                    if (nil != group)
                    {
                        sqlite3_int64 gid = sqlite3_column_int64(statement, index++);
                        if (gid != group_id)
                        {
                            if (array.count > 0 && group_id != -1)
                            {
                                result[@(group_id)] = array;
                                array = [[NSMutableArray alloc] initWithCapacity:(NSUInteger)count];
                            }
                            group_id = gid;
                        }
                    }
                }
            }
            if (array.count > 0)
            {
                result[@(group_id)] = array;
            }
        }
        else
        {
            NSLog( @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
            return nil;
        }
        sqlite3_finalize( statement );
    }
    ts = [NSDate timeIntervalSinceReferenceDate] - ts;
    NSLog( @"SQL database load time %f", ts );
    return (NSDictionary<NSNumber *, NSArray<NSNumber *> *> *)result;
}

- (sqlite3_int64) getUnlockedRecipeCount:(BOOL)alcohol
{
    NSString * tableName = alcohol ? @"harddrinks" : @"softdrinks";
    if ( self.unlocked )
        return [self getItemCount:tableName filter:nil];
    return [self getItemCount:tableName filter:@"unlocked=1"];
}

// Open the database connection and retrieve minimal information for all objects.
- (Boolean) initializeDatabase
{
    if (initialized)
        return YES;
    self.databasename = [[NSFileManager documentsPath] stringByAppendingPathComponent:@"shaker.sql"];
    if( ! [self createEditableCopyOfDatabaseIfNeeded] )
        return NO;
    sqlDatabaseRef = NULL;
    // Open the database. The database was prepared outside the application.
    if ( sqlite3_open( [self.databasename UTF8String], &sqlDatabaseRef) != SQLITE_OK )
    {
        // Even though the open failed, call close to properly clean up resources.
        if ( sqlDatabaseRef )
            sqlite3_close( sqlDatabaseRef );
        sqlDatabaseRef = NULL;
        NSLog( @"Failed to open database with message '%s'", sqlite3_errmsg(sqlDatabaseRef));
        // Additional error handling, as appropriate...
        return FALSE;
    }
    
    // exclude from backup
    NSURL * fileURL = [NSURL fileURLWithPath:self.databasename];
    if ( nil != fileURL )
    {
        NSError *error = nil;
        BOOL success = [fileURL setResourceValue: [NSNumber numberWithBool: YES]
                                          forKey: NSURLIsExcludedFromBackupKey error: &error];
        if(!success)
        {
            NSLog(@"Error excluding %@ from backup %@", [fileURL lastPathComponent], error);
        }
    }
    UserDatabase * user = [[UserDatabase alloc] init];
    if ( ! [user initializeDatabase] )
        return FALSE;
    self.userdatabase = user;
    self.gamefilter = kGameFilterDefault;
    self.unlocked = YES; // TODO: change later

    adrinks_count = [self getItemCount:@"harddrinks" filter:nil];
    
#ifdef IMPORT_FROM_CSV
//    NSArray *   paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *  documentsPath = [paths objectAtIndex:0];
//    NSString *  filename = [documentsPath stringByAppendingPathComponent:@"ingredients.csv"];
//    NSLog( @"%@", filename );
//
//    if ( adrinks_count < 1 )
//    {
//        // TODO: this is temporary database generator, remove later
//        NSString *	originalData = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"drinks.csv"];
//
//        [self importFromCSV:originalData];
//        [self dumpIngredientsToCSV:filename];
//        adrinks_count = [self getItemCount:@"harddrinks" filter:nil];
//    }
//    else
//    {
//        NSString *	catData = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"ingredients-master.csv"];
//        [self importCategoriesFromCSV:catData];
//        [self dumpIngredientsToCSV:filename];
//    }
#else
    self.wconnect = [[WatchConnect alloc] initWithDatabase:self];
#endif // IMPORT_FROM_CSV
    
    sdrinks_count = [self getItemCount:@"softdrinks" filter:nil];
    srand ( (unsigned int)time(NULL) );
    initialized = true;
    return YES;
}

- (void) dealloc
{
    if ( sqlDatabaseRef )
        sqlite3_close( sqlDatabaseRef );
    sqlDatabaseRef = NULL;
}

- (BOOL) areAllIngredientsEnabled:(NSArray *)ids
{
    BOOL bResult = YES;
    @autoreleasepool
    {
        NSString * strColumn = @"enabled_default";
        if ( self.gamefilter == kGameFilterCustom )
            strColumn = @"enabled";
        if ( self.gamefilter == kGameFilterTop10 || self.gamefilter == kGameFilterTop5 )
            strColumn = @"used";
        NSString * strSql = [NSString stringWithFormat:@"SELECT %@ FROM ingredients WHERE record_id IN ( ", strColumn];
     
        for ( NSNumber * item_id in ids )
        {
            strSql = [strSql stringByAppendingString:[item_id stringValue]];
            if ( [[ids lastObject] isEqual:item_id] )
            {
                strSql = [strSql stringByAppendingString:@" )"];
            }
            else
            {
                strSql = [strSql stringByAppendingString:@", "];
            }
        }

        sqlite3_stmt *	statement = NULL;
        if ( sqlite3_prepare_v2(  sqlDatabaseRef, [strSql  UTF8String], -1, &statement, NULL) == SQLITE_OK )
        {
            while ( sqlite3_step(statement) == SQLITE_ROW )
            {
                int value = sqlite3_column_int( statement, 0 );
                if ( self.gamefilter == kGameFilterTop10 )
                {
                    if ( value < TOP10USED )
                    {
                        bResult = NO;
                        break;
                    }
                }
                else if ( self.gamefilter == kGameFilterTop5 )
                {
                    if ( value < TOP5USED )
                    {
                        bResult = NO;
                        break;
                    }
                }
                else if ( value == 0 )
                {
                    bResult = NO;
                    break;
                }
            }
            sqlite3_finalize( statement );
        }
        else
        {
            NSLog( @"Error sqlite3_prepare_v2" );
            bResult = NO;
        }
    }
    return bResult;
}

BOOL check_record_in_records( sqlite3_int64 record, sqlite3_int64 * records )
{
    int i;
    for ( i = 0; i < MAX_RETRY_NUMBER && records[i]; i++ )
    {
        if ( record == records[i] )
            return YES;
    }
    records[i] = record;
    return NO;
}

- (BOOL) enableAllIngredients:(BOOL)enable
{
    BOOL result = YES;
    sqlite3_stmt *    sql_statement = nil;
    const char * sql = "UPDATE ingredients SET enabled=?";
    if (sqlite3_prepare_v2( sqlDatabaseRef, sql, -1, &sql_statement, NULL ) == SQLITE_OK)
    {
        sqlite3_bind_int( sql_statement, 1, enable ? 1 : 0 );
        if (SQLITE_ERROR == sqlite3_step( sql_statement ) )
        {
            // Error...
            NSLog( @"Error: failed to update ingredients record with message '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
            result = NO;
        }
        sqlite3_finalize( sql_statement );
    }
    else
    {
        NSLog( @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
        result = NO;
    }
    return result;
}

- (BOOL) enableIngredient:(BOOL)enable withRecordid:(sqlite3_int64)recordid
{
    BOOL result = YES;
    sqlite3_stmt *	sql_statement = nil;
    const char * sql = "UPDATE ingredients SET enabled=? WHERE record_id=?";
    if (sqlite3_prepare_v2( sqlDatabaseRef, sql, -1, &sql_statement, NULL ) == SQLITE_OK)
    {
        sqlite3_bind_int( sql_statement, 1, enable ? 1 : 0 );
        sqlite3_bind_int64( sql_statement, 2, recordid );
        if (SQLITE_ERROR == sqlite3_step( sql_statement ) )
        {
            // Error...
            NSLog( @"Error: failed to update ingredients record with message '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
            result = NO;
        }
        sqlite3_finalize( sql_statement );
    }
    else
    {
        NSLog( @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
        result = NO;
    }
    return result;
}

- (sqlite3_int64) countEnabledIngradients:(BOOL)enabled
{
    NSString * filter = [NSString stringWithFormat:@"enabled=%d", enabled? 1 : 0];
    sqlite3_int64 count = [self getItemCount:@"ingredients" filter:filter];
    return count;
}

// CREATE TABLE ingredients( record_id integer PRIMARY KEY NOT NULL, item text, used integer, options integer, enabled boolean, enabled_default boolean, category_id integer );

- (NSArray <NSDictionary *> *) inredientsForCategory:(sqlite3_int64)category_id showall:(BOOL)showall filter:(NSString *)filter sort:(NSString *)sort
{
    sqlite3_int64 count = [self getItemCount:@"ingredients" filter:nil];
    NSMutableArray * array = [[NSMutableArray alloc] initWithCapacity:(NSUInteger)count];
    
    NSString * fltr = (showall) ? @"" : @" AND enabled_default=1";
    if ( filter != nil )
    {
        fltr = [fltr stringByAppendingString:@" AND "];
        fltr = [fltr stringByAppendingString:filter];
    }
    
    const char * sql = [[NSString stringWithFormat:@"SELECT item, used, enabled, enabled_default, record_id FROM ingredients WHERE category_id = %lld%@ ORDER BY %@",
                         category_id, fltr, (sort==nil) ? @"item ASC" : sort] UTF8String];
    sqlite3_stmt *    statement = NULL;
    if ( sqlite3_prepare_v2(  sqlDatabaseRef, sql, -1, &statement, NULL) == SQLITE_OK )
    {
        while ( sqlite3_step(statement) == SQLITE_ROW )
        {
            NSMutableDictionary * result = [[NSMutableDictionary alloc] initWithCapacity:5];
            const unsigned char * name = sqlite3_column_text( statement, 0 );
            if ( name != NULL )
                [result setObject:[NSString stringWithUTF8String:(char *)name] forKey:@"name"];
            [result setObject:[NSNumber numberWithInt:sqlite3_column_int( statement, 1 )] forKey:@"used"];
            [result setObject:[NSNumber numberWithBool:sqlite3_column_int( statement, 2 ) == 0 ? NO : YES] forKey:@"enabled"];
            [result setObject:[NSNumber numberWithBool:sqlite3_column_int( statement, 3 ) == 0 ? NO : YES] forKey:@"visible"];
            [result setObject:[NSNumber numberWithLongLong:sqlite3_column_int64( statement, 4 )] forKey:@"id"];
            [array addObject:result];
        }
    }
    else
    {
        NSLog( @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
        return nil;
    }
    sqlite3_finalize( statement );
    return (NSArray *)array;
}

- (NSArray <NSDictionary *> *) ingredientsCategories
{
    sqlite3_int64 count = [self getItemCount:@"ingredient_types" filter:nil];
    if ( count < 1 )
        return nil;
    
    NSMutableArray * array = [[NSMutableArray alloc] initWithCapacity:(NSUInteger)count];
    
    const char * sql = "SELECT category, category_id FROM ingredient_types";
    sqlite3_stmt *	statement = NULL;
    if ( sqlite3_prepare_v2(  sqlDatabaseRef, sql, -1, &statement, NULL) == SQLITE_OK )
    {
        while ( sqlite3_step(statement) == SQLITE_ROW )
        {
            const unsigned char * name = sqlite3_column_text( statement, 0 );
            sqlite3_int64 category_id = sqlite3_column_int64( statement, 1 );
            if ( name != NULL )
            {
                [array addObject:@{ @"category" : [NSString stringWithUTF8String:(const char *)name], @"id" : [NSNumber numberWithLongLong:category_id] }];
            }
        }
    }
    else
    {
        NSLog( @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
        return nil;
    }
    sqlite3_finalize( statement );
    return (NSArray <NSDictionary *> *)array;
}

- (NSString *) categoryName:(sqlite3_int64)cid
{
    const char * sql = [[NSString stringWithFormat:@"SELECT category FROM categories WHERE crecord_id = %lld", cid] UTF8String];
    NSString * name = @"";
    sqlite3_stmt *    statement = NULL;
    if ( sqlite3_prepare_v2(  sqlDatabaseRef, sql, -1, &statement, NULL) == SQLITE_OK )
    {
        if ( sqlite3_step(statement) == SQLITE_ROW )
        {
            const unsigned char * n = sqlite3_column_text( statement, 0 );
            if ( NULL != n )
                name = [NSString stringWithUTF8String:(char *)n];
        }
    }
    else
    {
        NSLog( @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
        return nil;
    }
    sqlite3_finalize( statement );
    return name;
}
// CREATE TABLE glasses( grecord_id integer PRIMARY KEY NOT NULL, glass text, count integer );
- (NSString *) glassName:(sqlite3_int64)gid
{
    const char * sql = [[NSString stringWithFormat:@"SELECT glass FROM glasses WHERE grecord_id = %lld", gid] UTF8String];
    NSString * name = @"";
    sqlite3_stmt *    statement = NULL;
    if ( sqlite3_prepare_v2(sqlDatabaseRef, sql, -1, &statement, NULL) == SQLITE_OK )
    {
        if ( sqlite3_step(statement) == SQLITE_ROW )
        {
            const unsigned char * n = sqlite3_column_text( statement, 0 );
            if ( NULL != n )
                name = [NSString stringWithUTF8String:(char *)n];
        }
    }
    else
    {
        NSLog( @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
        return nil;
    }
    sqlite3_finalize( statement );
    return name;
}

- (sqlite3_int64) findRandomRecipe
{
    // Preparing a statement compiles the SQL query into a byte-code program in the SQLite library.
    BOOL    alcohol = (self.gamefilter == kGameFilterFree) ? NO : YES;
    sqlite3_int64   randomID = 0;
    sqlite3_int64   count = alcohol ? adrinks_count : sdrinks_count;
    sqlite3_int64   record_id = -1;
    sqlite3_int64   records[MAX_RETRY_NUMBER+1] = {0};
    int retry_count = 0;
    
    @autoreleasepool
    {
        do {
            do {
                // generate unique random number
                randomID = 1 + ((count + 1) * rand())/RAND_MAX;
            } while ( check_record_in_records( randomID, records ) );
            if ( ! alcohol )
            {
                // assume all ingredients are enabled for non-alcohol drinks because only 195 of them
                record_id = randomID;
                break;
            }
            
            const char *	sql = [[NSString stringWithFormat:@"SELECT shopping_ids FROM %@ WHERE record_id = %lld AND enabled = 1",
                                    (alcohol ? @"harddrinks" : @"softdrinks"), randomID] UTF8String];
            sqlite3_stmt *	statement = NULL;

            if ( sqlite3_prepare_v2(  sqlDatabaseRef, sql, -1, &statement, NULL) == SQLITE_OK )
            {
                while ( sqlite3_step(statement) == SQLITE_ROW )
                {
                    const void * data_ptr = sqlite3_column_blob( statement, 0 );
                    int data_len = sqlite3_column_bytes( statement, 0 );
                    if ( data_ptr != NULL && data_len > 0 )
                    {
                        NSData * dataIDs = [NSData dataWithBytes:data_ptr length:data_len];
                        NSError * err = nil;
                        NSArray<NSNumber *> * ids = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSArray<NSNumber *> class] fromData:dataIDs error:&err];
                        if (ids != nil)
                        {
                            if ( [self areAllIngredientsEnabled:ids] )
                            {
                                record_id = randomID;
                                break;
                            }
                        }
                        else
                        {
                            NSLog(@"unarchivedObjectOfClass failed with error: %@", err);
                        }
                    }
                }
                sqlite3_finalize( statement );
            }
        } while( record_id < 0 && retry_count++ < MAX_RETRY_NUMBER );
    }
    NSLog( @"%lld, %d", record_id, retry_count );
    return record_id;
}

- (NSDictionary *) getRecipeName:(sqlite3_int64)record_id alcohol:(BOOL)alcohol
{
    NSString *   strTable = (alcohol ? @"harddrinks" : @"softdrinks");
    NSString *   sql = [NSString stringWithFormat:@"SELECT name, enabled, shopping, category, glass, rating FROM %@ INNER JOIN categories ON (%@.category_id = categories.crecord_id) INNER JOIN glasses ON (%@.glass_id = glasses.grecord_id) WHERE record_id = %lld", strTable, strTable, strTable, record_id];
    
    sqlite3_stmt *	statement = NULL;
    NSMutableDictionary * result = nil;
    const unsigned char * value;
    
    if (sqlite3_prepare_v2(sqlDatabaseRef, [sql UTF8String], -1, &statement, NULL) != SQLITE_OK)
    {
        NSLog( @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
        return nil;
    }
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        result = [[NSMutableDictionary alloc] initWithCapacity:3];
        value = sqlite3_column_text( statement, 0 );
        if ( value != NULL )
            [result setObject:[NSString stringWithUTF8String:(const char *)value] forKey:@"name"];
        [result setObject:[NSNumber numberWithInt:sqlite3_column_int( statement, 1 )] forKey:@"enabled"];
        value = sqlite3_column_text( statement, 2 );
        if ( value != NULL )
            [result setObject:[NSString stringWithUTF8String:(const char *)value] forKey:@"shopping"];
        value = sqlite3_column_text( statement, 3 );
        if ( value != NULL )
            [result setObject:[NSString stringWithUTF8String:(const char *)value] forKey:@"category"];
        value = sqlite3_column_text( statement, 4 );
        if ( value != NULL )
            [result setObject:[NSString stringWithUTF8String:(const char *)value] forKey:@"glass"];
        NSInteger val = sqlite3_column_int( statement, 5 );
        [result setObject:[NSNumber numberWithInteger:val] forKey:@"rating"];
    }
    sqlite3_finalize( statement );
    return (NSDictionary *)result;
}

#ifdef IMAGE_SUPPORT

- (UIImage *) getPhoto:(sqlite3_int64)record_id alcohol:(BOOL)alcohol
{
    const char *	sql = [[NSString stringWithFormat:@"SELECT user_id FROM %@ WHERE record_id = %lld", (alcohol ? @"harddrinks" : @"softdrinks"), record_id] UTF8String];
    
    sqlite3_stmt *	statement = NULL;
    
    UIImage * result = nil;
    
    if ( sqlite3_prepare_v2(  sqlDatabaseRef, sql, -1, &statement, NULL) != SQLITE_OK )
    {
        NSLog( @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
        return nil;
    }
    if ( sqlite3_step(statement) == SQLITE_ROW )
    {
        sqlite3_int64 user_id = sqlite3_column_int64( statement, 0 );
        if ( user_id > 0)
            result = [self.userdatabase getPhoto:user_id];
    }
    sqlite3_finalize( statement );
    return result;
}

- (BOOL) updateUserPhoto:(UIImage *)photo record:(sqlite3_int64)record_id
{
    NSData * data = UIImageJPEGRepresentation( photo, 0.8 );
    if ( nil == data )
        return NO;
    if (![self.userdatabase updateUserPhoto:data record:record_id])
        return NO;
    [self.wconnect sendMessageWithMessage:@{ @"event" : kShakerRecordChanged,
                                             @"recordid" : @(record_id),
                                             @"photo" : data
                                          }];
    return YES;
}

- (BOOL) updateUserRecord:(sqlite3_int64)record_id note:(NSString *)note rating:(int)rating visible:(BOOL)visible
{
    if ( [self.userdatabase updateUserRecord:record_id note:note rating:rating visible:visible] )
    {
        [self.wconnect sendMessageWithMessage:@{ @"event" : kShakerRecordChanged,
                                                 @"recordid" : @(record_id),
                                                 @"note" : note == nil ? @"" : note,
                                                 @"rating" : @(rating),
                                                 @"visible" : @(visible)
                                              }];
        return YES;
    }
    return NO;
}

#endif

- (NSDictionary *) getRecipe:(sqlite3_int64)record_id noImage:(BOOL)noImage
{
    BOOL    alcohol = (self.gamefilter == kGameFilterFree) ? NO : YES;
    return [self getRecipe:record_id alcohol:alcohol noImage:(BOOL)noImage];
}

- (NSDictionary *) getRecipe:(sqlite3_int64)record_id alcohol:(BOOL)alcohol noImage:(BOOL)noImage
{
    NSString *      strTable = (alcohol ? @"harddrinks" : @"softdrinks");
    const char *	sql = [[NSString stringWithFormat:@"SELECT name, ingredients, instructions, shopping, rating, shopcount, user_id, unlocked, category, glass FROM %@ INNER JOIN categories ON (%@.category_id = categories.crecord_id) INNER JOIN glasses ON (%@.glass_id = glasses.grecord_id) WHERE record_id = %lld",
                            strTable, strTable, strTable, record_id] UTF8String];
    
    sqlite3_stmt *	statement = NULL;
    
    NSMutableDictionary * result = nil;
    const unsigned char * value;
    
    if ( sqlite3_prepare_v2(  sqlDatabaseRef, sql, -1, &statement, NULL) != SQLITE_OK )
    {
        NSLog( @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
        return nil;
    }
    if ( sqlite3_step(statement) == SQLITE_ROW )
    {
        result = [[NSMutableDictionary alloc] initWithCapacity:20];
        value = sqlite3_column_text( statement, 0 );
        if ( value != NULL )
            [result setObject:[NSString stringWithUTF8String:(const char *)value] forKey:@"name"];
        value = sqlite3_column_text( statement, 1 );
        if ( value != NULL )
            [result setObject:[NSString stringWithUTF8String:(const char *)value] forKey:@"ingredients"];
        value = sqlite3_column_text( statement, 2 );
        if ( value != NULL )
            [result setObject:[NSString stringWithUTF8String:(const char *)value] forKey:@"instructions"];
        value = sqlite3_column_text( statement, 3 );
        if ( value != NULL )
            [result setObject:[NSString stringWithUTF8String:(const char *)value] forKey:@"shopping"];
        [result setObject:[NSNumber numberWithInt:sqlite3_column_int( statement, 4 )] forKey:@"rating"];
        [result setObject:[NSNumber numberWithInt:sqlite3_column_int( statement, 5 )] forKey:@"numberofitems"];

        sqlite3_int64 user_id = sqlite3_column_int64( statement, 6 );
        BOOL unlocked = sqlite3_column_int( statement, 7 ) == 0 ? NO : YES;
        
        value = sqlite3_column_text( statement, 8 );
        if ( value != NULL )
            [result setObject:[NSString stringWithUTF8String:(const char *)value] forKey:@"category"];
        value = sqlite3_column_text( statement, 9 );
        if ( value != NULL )
            [result setObject:[NSString stringWithUTF8String:(const char *)value] forKey:@"glass"];

        if ( (! unlocked) || user_id < 1 )
        {
            // create new user record and unlock
            user_id = [self.userdatabase createNewUserRecord:record_id];
            if ( user_id > 0 )
            {
                unlocked = YES;
                sqlite3_stmt *	sql_statement = nil;
                const char * sql = [[NSString stringWithFormat:@"UPDATE %@ SET unlocked=?, user_id=? WHERE record_id=?", strTable] UTF8String];
                if (sqlite3_prepare_v2( sqlDatabaseRef, sql, -1, &sql_statement, NULL ) == SQLITE_OK)
                {
                    sqlite3_bind_int( sql_statement, 1, 1 );
                    sqlite3_bind_int64( sql_statement, 2, user_id );
                    sqlite3_bind_int64( sql_statement, 3, record_id );
                    if (SQLITE_ERROR == sqlite3_step( sql_statement ) )
                    {
                        // Error...
                        NSLog( @"Error: failed to update %@ record with message '%s'.", strTable, sqlite3_errmsg( sqlDatabaseRef ) );
                    }
                    else
                    {
#ifndef IMPORT_FROM_CSV
                        // new recipe unlocked
                        [self.wconnect sendMessageWithMessage:@{ @"event" : kShakerRecipeUnlocked,
                                                            @"recordid" : @(record_id),
                                                            @"alcohol" : @(alcohol),
                                                            }];
#endif // IMPORT_FROM_CSV
                    }
                    sqlite3_finalize( sql_statement );
                }
            }
            [result setObject:[NSNumber numberWithInt:0] forKey:@"userrating"];
            [result setObject:[NSNumber numberWithBool:NO] forKey:@"favorite"];
            [result setObject:[NSNumber numberWithBool:YES] forKey:@"visible"];
            [result setObject:[NSNumber numberWithLongLong:record_id] forKey:@"coctail_id"];
        }
        else if ( user_id > 0 )
        {
            NSDictionary * user = [self.userdatabase getUserRecord:user_id noImage:noImage];
            if ( user != nil )
                [result addEntriesFromDictionary:user];
        }
        [result setObject:[NSNumber numberWithLongLong:user_id] forKey:@"userrecord_id"];
    }
    sqlite3_finalize( statement );
    return (NSDictionary *)result;
}

#pragma mark -- Import From CSV File

#ifdef IMPORT_FROM_CSV

- (sqlite3 *) createDatabase:(NSString *)filename
{
    sqlite3 * pDb = NULL;
    int rc = sqlite3_open_v2([filename UTF8String], &pDb, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL);
    if (SQLITE_OK == rc && pDb != NULL )
    {
        // create tables
        const char * harddrinks_table = "CREATE TABLE harddrinks( record_id integer PRIMARY KEY NOT NULL, name text, "
                                        "ingredients text, instructions text, rating integer, comments text, user_id integer, "
                                        "shopping text, category_id integer, shopcount integer, glass_id integer, shopping_ids "
                                        "blob, enabled boolean, unlocked boolean, FOREIGN KEY(glass_id) REFERENCES "
                                        "glasses(grecord_id), FOREIGN KEY(category_id) REFERENCES categories(crecord_id) );";
        const char * softdrinks_table = "CREATE TABLE softdrinks( record_id integer PRIMARY KEY NOT NULL, name text, ingredients text, "
                                        "instructions text, rating integer, comments text, user_id integer, shopping text, category_id "
                                        "integer, shopcount integer, glass_id integer, shopping_ids blob, enabled boolean, unlocked "
                                        "boolean, FOREIGN KEY(glass_id) REFERENCES glasses(grecord_id), FOREIGN KEY(category_id) "
                                        "REFERENCES categories(crecord_id) );";
        const char * glasses_table =    "CREATE TABLE glasses( grecord_id integer PRIMARY KEY NOT NULL, glass text, count integer );";
        const char * categories_table = "CREATE TABLE categories( crecord_id integer PRIMARY KEY NOT NULL, category text, count integer );";
        const char * ingredients_table= "CREATE TABLE ingredients( record_id integer PRIMARY KEY NOT NULL, item text, used integer, options "
                                        "integer, enabled boolean, enabled_default boolean, category_id integer );";
        const char * ingr_types_table = "CREATE TABLE ingredient_types ( 'record_id' INTEGER PRIMARY KEY, category TEXT, category_id integer );";
        const char * types[] = {
            "INSERT INTO ingredient_types (category, category_id) VALUES ('Vodka', 1);",
            "INSERT INTO ingredient_types (category, category_id) VALUES ('Gin', 2);",
            "INSERT INTO ingredient_types (category, category_id) VALUES ('Rum', 3);",
            "INSERT INTO ingredient_types (category, category_id) VALUES ('Whiskey', 4);",
            "INSERT INTO ingredient_types (category, category_id) VALUES ('Brandy / Cognac', 5);",
            "INSERT INTO ingredient_types (category, category_id) VALUES ('Tequila', 6);",
            "INSERT INTO ingredient_types (category, category_id) VALUES ('Schnapps', 7);",
            "INSERT INTO ingredient_types (category, category_id) VALUES ('Liqueur', 8);",
            "INSERT INTO ingredient_types (category, category_id) VALUES ('Other Liquors', 19);",
            "INSERT INTO ingredient_types (category, category_id) VALUES ('Wine / Port / Vermouth', 9);",
            "INSERT INTO ingredient_types (category, category_id) VALUES ('Beer / Malt / Cooler', 13);",
            "INSERT INTO ingredient_types (category, category_id) VALUES ('Juice / Syrup / Mix', 11);",
            "INSERT INTO ingredient_types (category, category_id) VALUES ('Soda / Soft Drinks', 10);",
            "INSERT INTO ingredient_types (category, category_id) VALUES ('Milk / Cream / Ice Cream', 12);",
            "INSERT INTO ingredient_types (category, category_id) VALUES ('Coffee / Tea / Cocoa', 18);",
            "INSERT INTO ingredient_types (category, category_id) VALUES ('Fruit / Berries / Nuts', 14);",
            "INSERT INTO ingredient_types (category, category_id) VALUES ('Jello / Puree / Sweetener', 17);",
            "INSERT INTO ingredient_types (category, category_id) VALUES ('Garnish / Spice / Sauce', 15);",
            "INSERT INTO ingredient_types (category, category_id) VALUES ('Miscellaneous', 16);"
        };
        const size_t type_cnt = sizeof(types)/sizeof(types[0]);

        rc = sqlite3_exec(pDb, harddrinks_table, NULL, NULL, NULL);
        if (SQLITE_OK != rc)
            goto error;
        rc = sqlite3_exec(pDb, softdrinks_table, NULL, NULL, NULL);
        if (SQLITE_OK != rc)
            goto error;
        rc = sqlite3_exec(pDb, glasses_table, NULL, NULL, NULL);
        if (SQLITE_OK != rc)
            goto error;
        rc = sqlite3_exec(pDb, categories_table, NULL, NULL, NULL);
        if (SQLITE_OK != rc)
            goto error;
        rc = sqlite3_exec(pDb, ingredients_table, NULL, NULL, NULL);
        if (SQLITE_OK != rc)
            goto error;
        rc = sqlite3_exec(pDb, ingr_types_table, NULL, NULL, NULL);
        if (SQLITE_OK != rc)
            goto error;

        for (size_t i = 0; i < type_cnt; i++)
        {
            rc = sqlite3_exec(pDb, types[i], NULL, NULL, NULL);
            if (SQLITE_OK != rc)
                goto error;
        }
    }
    else
    {
        NSLog( @"Error: failed to create a new database %s", sqlite3_errmsg( pDb ) );
    }
    return pDb;
    
error:
    NSLog( @"Error: failed to create a new database %s", sqlite3_errmsg( pDb ) );
    sqlite3_close(pDb);
    return NULL;
}

- (sqlite3_int64) addCategory:(NSString *)category
{
    // Get the properties
    sqlite3_int64       record_id = -1;
    if ( [category length] < 1 )
        return record_id;
    
    // Preparing a statement compiles the SQL query into a byte-code program in the SQLite library.
    const char *	sql = [[NSString stringWithFormat:@"SELECT crecord_id FROM categories where category = '%@' COLLATE NOCASE", category] UTF8String];
    sqlite3_stmt *	statement = NULL;
    if ( sqlite3_prepare_v2(  sqlDatabaseRef, sql, -1, &statement, NULL) == SQLITE_OK )
    {
        // We "step" through the results - once for each row
        if ( sqlite3_step(statement) == SQLITE_ROW )
        {
            record_id = sqlite3_column_int64( statement, 0 );
        }
        sqlite3_finalize( statement );
    }
    if ( record_id < 0 )
    {
        sqlite3_stmt *	sql_statement = nil;
        // does not exist, add new
        const char * sql = "insert into categories (category) values (?)";
        if (sqlite3_prepare_v2( sqlDatabaseRef, sql, -1, &sql_statement, NULL ) != SQLITE_OK)
        {
            NSLog( @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
            return record_id;
        }
        sqlite3_bind_text( sql_statement, 1, [category UTF8String],  -1, SQLITE_TRANSIENT);
        //execute
        int success = sqlite3_step(sql_statement);
        
        //sqlite3_reset(sql_statement); //once we're near optimization stage we will start creating static statements in the Database class
        // and finalize them
        sqlite3_finalize(sql_statement);
        if ( success != SQLITE_ERROR )
        {
            record_id = sqlite3_last_insert_rowid( sqlDatabaseRef );
            // NSLog( @"Category:   %@", category );
        }
    }
    return record_id;
}

- (sqlite3_int64) addGlass:(NSString *)glass
{
    // Get the properties
    sqlite3_int64       record_id = -1;
    if ( [glass length] < 1 )
        return record_id;
    
    // Preparing a statement compiles the SQL query into a byte-code program in the SQLite library.
    const char *	sql = [[NSString stringWithFormat:@"SELECT grecord_id FROM glasses where glass = '%@' COLLATE NOCASE", glass] UTF8String];
    sqlite3_stmt *	statement = NULL;
    if ( sqlite3_prepare_v2(  sqlDatabaseRef, sql, -1, &statement, NULL) == SQLITE_OK )
    {
        // We "step" through the results - once for each row
        if ( sqlite3_step(statement) == SQLITE_ROW )
        {
            record_id = sqlite3_column_int( statement, 0 );
        }
        sqlite3_finalize( statement );
    }
    if ( record_id < 0 )
    {
        sqlite3_stmt *	sql_statement = nil;
        // does not exist, add new
        const char * sql = "insert into glasses (glass) values (?)";
        if (sqlite3_prepare_v2( sqlDatabaseRef, sql, -1, &sql_statement, NULL ) != SQLITE_OK)
        {
            NSLog( @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
            return record_id;
        }
        sqlite3_bind_text( sql_statement, 1, [glass UTF8String],  -1, SQLITE_TRANSIENT);
        //execute
        int success = sqlite3_step(sql_statement);
        
        //sqlite3_reset(sql_statement); //once we're near optimization stage we will start creating static statements in the Database class
        // and finalize them
        sqlite3_finalize(sql_statement);
        if ( success != SQLITE_ERROR )
        {
            record_id = sqlite3_last_insert_rowid( sqlDatabaseRef );
        }
    }
    return record_id;
}

- (sqlite3_int64) addShoppingItem:(NSString *)item enabled:(BOOL)enabled
{
    // Get the properties
    sqlite3_int64       record_id = -1;
    if ( [item length] < 1 )
        return record_id;
    
    // Preparing a statement compiles the SQL query into a byte-code program in the SQLite library.
    const char *	sql = [[NSString stringWithFormat:@"SELECT record_id, enabled_default, used FROM ingredients where item = \"%@\" COLLATE NOCASE", item] UTF8String];
    sqlite3_stmt *	statement = NULL;
    int enable = 0, used = 0;
    if ( sqlite3_prepare_v2(  sqlDatabaseRef, sql, -1, &statement, NULL) == SQLITE_OK )
    {
        // We "step" through the results - once for each row
        if ( sqlite3_step(statement) == SQLITE_ROW )
        {
            record_id = sqlite3_column_int( statement, 0 );
            enable = sqlite3_column_int( statement, 1 );
            used = sqlite3_column_int( statement, 2 );
        }
        sqlite3_finalize( statement );
        if ( record_id >= 0 )
        {
            used++;
            sqlite3_stmt *	sql_statement = nil;
            const char * sql = "UPDATE ingredients SET enabled=?, enabled_default=?, used=? WHERE record_id=?";
            if (sqlite3_prepare_v2( sqlDatabaseRef, sql, -1, &sql_statement, NULL ) == SQLITE_OK)
            {
                if ( enabled && used > 4 )
                {
                    sqlite3_bind_int( sql_statement, 1, 1 );
                    sqlite3_bind_int( sql_statement, 2, 1 );
                }
                else
                {
                    sqlite3_bind_int( sql_statement, 1, 0 );
                    sqlite3_bind_int( sql_statement, 2, 0 );
                }
                sqlite3_bind_int( sql_statement, 3, used );
                sqlite3_bind_int64( sql_statement, 4, record_id );
                if (SQLITE_ERROR == sqlite3_step( sql_statement ) )
                {
                    // Error...
                    NSLog( @"Error: failed to update ingredients record with message '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
                    
                }
                sqlite3_finalize( sql_statement );
            }
        }
    }
    if ( record_id < 0 )
    {
        sqlite3_stmt *	sql_statement = nil;
        // does not exist, add new
        const char * sql = "INSERT INTO ingredients (item, options, enabled, enabled_default, used) VALUES (?, ?, ?, ?, ?)";
        if (sqlite3_prepare_v2( sqlDatabaseRef, sql, -1, &sql_statement, NULL ) != SQLITE_OK)
        {
            NSLog( @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
            return record_id;
        }
        sqlite3_bind_text( sql_statement, 1, [item UTF8String],  -1, SQLITE_TRANSIENT);
        sqlite3_bind_int( sql_statement, 2, 0 );
        sqlite3_bind_int( sql_statement, 3, 0 );
        sqlite3_bind_int( sql_statement, 4, 0 );
        sqlite3_bind_int( sql_statement, 5, 1 );

        //execute
        int success = sqlite3_step(sql_statement);
        
        //sqlite3_reset(sql_statement); //once we're near optimization stage we will start creating static statements in the Database class
        // and finalize them
        sqlite3_finalize(sql_statement);
        if ( success != SQLITE_ERROR )
        {
            record_id = sqlite3_last_insert_rowid( sqlDatabaseRef );
            // NSLog( @"%@", item );
        }
    }
    return record_id;
}

- (void) autosetCategories
{
    const char *	sql = "SELECT item, record_id FROM ingredients";
    sqlite3_stmt *	statement = NULL;
    if ( sqlite3_prepare_v2(  sqlDatabaseRef, sql, -1, &statement, NULL) == SQLITE_OK )
    {
        // We "step" through the results - once for each row
        while ( sqlite3_step(statement) == SQLITE_ROW )
        {
            const unsigned char * name = sqlite3_column_text( statement, 0 );
            sqlite3_int64 recid = sqlite3_column_int( statement, 1 );
            int cat = 0;
            if ( name != NULL )
            {
                NSString * item = [NSString stringWithUTF8String:(char *)name];
                item = [item lowercaseString];
                
                if ( [item containsString:@"triple sec"] )
                {
                    cat = 8;
                }
                else if ( [item containsString:@"iced tea"] )
                {
                    cat = 18;
                }
                else if ( [item containsString:@"ice cream"] )
                {
                    cat = 12;
                }
                else if ( [item containsString:@"minute maid"] )
                {
                    cat = 11;
                }
                else if ( [item containsString:@"root beer"] )
                {
                    cat = 10;
                    if ( [item containsString:@"schnapps"] )
                        cat = 7;
                    else if ( [item containsString:@"liqueur"] )
                        cat = 8;
                }
                else if ( [item containsString:@"ginger beer"] )
                {
                    cat = 10;
                }
                else if ( [item containsString:@"ginger ale"] )
                {
                    cat = 10;
                }
                else if ( [item containsString:@"hawaiian punch"] )
                {
                    cat = 10;
                }
                else
                {
                    NSArray * names = [item componentsSeparatedByString:@" "];
                    for ( NSString * n in names )
                    {
                        if ( [n isEqualToString:@"grappa"] )
                        {
                            cat = 8;
                            break;
                        }
                        if ( [n isEqualToString:@"absinthe"] )
                        {
                            cat = 8;
                            break;
                        }
                        if ( [n isEqualToString:@"advocaat"] )
                        {
                            cat = 8;
                            break;
                        }
                        if ( [n isEqualToString:@"aftershock"] )
                        {
                            cat = 8;
                            break;
                        }
                        if ( [n isEqualToString:@"lemonade"] )
                        {
                            cat = 10;
                            break;
                        }
                        if ( [n isEqualToString:@"cooler"] )
                        {
                            cat = 13;
                            //break;
                        }
                        if ( [n isEqualToString:@"malt"] )
                        {
                            cat = 13;
                            break;
                        }
                        if ( [n isEqualToString:@"beer"] )
                        {
                            cat = 13;
                            break;
                        }
                        if ( [n isEqualToString:@"ale"] )
                        {
                            cat = 9;
                            break;
                        }
                        if ( [n isEqualToString:@"lager"] )
                        {
                            cat = 13;
                            break;
                        }
                        if ( [n isEqualToString:@"stout"] )
                        {
                            cat = 13;
                            //break;
                        }
                        if ( [n isEqualToString:@"vodka"] )
                        {
                            cat = 1;
                            break;
                        }
                        if ( [n isEqualToString:@"brandy"] )
                        {
                            cat = 5;
                            break;
                        }
                        if ( [n isEqualToString:@"cognac"] )
                        {
                            cat = 5;
                            break;
                        }
                        if ( [n isEqualToString:@"schnapps"] )
                        {
                            cat = 7;
                            break;
                        }
                        if ( [n isEqualToString:@"liqueur"] )
                        {
                            cat = 8;
                            break;
                        }
                        if ( [n isEqualToString:@"whiskey"] )
                        {
                            cat = 4;
                            break;
                        }
                        if ( [n isEqualToString:@"champagne"] )
                        {
                            cat = 9;
                            break;
                        }
                        if ( [n isEqualToString:@"creamer"] )
                        {
                            cat = 12;
                            //break;
                        }
                        if ( [n isEqualToString:@"milk"] )
                        {
                            cat = 12;
                            //break;
                        }
                        if ( [n isEqualToString:@"mix"] )
                        {
                            cat = 11;
                            break;
                        }
                        if ( [n isEqualToString:@"mixer"] )
                        {
                            cat = 11;
                            break;
                        }
                        if ( [n isEqualToString:@"soda"] )
                        {
                            cat = 10;
                            //break;
                        }
                        if ( [n isEqualToString:@"juice"] )
                        {
                            cat = 11;
                            //break;
                        }
                        if ( [n isEqualToString:@"gin"] )
                        {
                            cat = 2;
                            break;
                        }
                        if ( [n isEqualToString:@"rum"] )
                        {
                            cat = 3;
                            break;
                        }
                        if ( [n isEqualToString:@"cider"] )
                        {
                            cat = 10;
                            //break;
                        }
                        if ( [n isEqualToString:@"tequila"] )
                        {
                            cat = 6;
                            break;
                        }
                        if ( [n isEqualToString:@"syrup"] )
                        {
                            cat = 11;
                            break;
                        }
                        if ( [n isEqualToString:@"puree"] )
                        {
                            cat = 17;
                            break;
                        }
                        if ( [n isEqualToString:@"wine"] )
                        {
                            cat = 9;
                            //break;
                        }
                        if ( [n isEqualToString:@"vermouth"] )
                        {
                            cat = 9;
                            break;
                        }
                        if ( [n isEqualToString:@"jello"] )
                        {
                            cat = 17;
                            break;
                        }
                        if ( [n isEqualToString:@"jell-o"] )
                        {
                            cat = 17;
                            break;
                        }
                        if ( [n isEqualToString:@"coca-cola"] )
                        {
                            cat = 10;
                            break;
                        }
                        if ( [n isEqualToString:@"cola"] )
                        {
                            cat = 10;
                            //break;
                        }
                        if ( [n isEqualToString:@"egg"] )
                        {
                            cat = 16;
                            break;
                        }
                        if ( [n isEqualToString:@"energy"] )
                        {
                            cat = 10;
                            break;
                        }
                        if ( [n isEqualToString:@"nectar"] )
                        {
                            cat = 17;
                            break;
                        }
                        if ( [n isEqualToString:@"kool-aid"] )
                        {
                            cat = 11;
                            break;
                        }
                        if ( [n isEqualToString:@"schweppes"] )
                        {
                            cat = 10;
                            break;
                        }
                        if ( [n isEqualToString:@"port"] )
                        {
                            cat = 9;
                            break;
                        }
                        if ( [n isEqualToString:@"sambuca"] )
                        {
                            cat = 8;
                            break;
                        }
                        if ( [n isEqualToString:@"sherbet"] )
                        {
                            cat = 12;
                            break;
                        }
                        if ( [n isEqualToString:@"bitters"] )
                        {
                            cat = 15;
                            break;
                        }
                        if ( [n isEqualToString:@"tropicana"] )
                        {
                            cat = 11;
                            break;
                        }
                        if ( [n isEqualToString:@"v8"] )
                        {
                            cat = 11;
                            break;
                        }
                        if ( [n isEqualToString:@"armagnac"] )
                        {
                            cat = 5;
                            break;
                        }
                        if ( [n isEqualToString:@"nuts"] )
                        {
                            cat = 14;
                            break;
                        }
                        if ( [n isEqualToString:@"sake"] )
                        {
                            cat = 9;
                            break;
                        }
                        if ( [n isEqualToString:@"sherry"] )
                        {
                            cat = 8;
                            break;
                        }
                        if ( [n isEqualToString:@"sauce"] )
                        {
                            cat = 15;
                            break;
                        }
                    }
                }
                if ( cat > 0 )
                {
                    sqlite3_stmt *	sql_statement = nil;
                    const char * sql = "UPDATE ingredients SET category_id=? WHERE record_id=?";
                    if (sqlite3_prepare_v2( sqlDatabaseRef, sql, -1, &sql_statement, NULL ) == SQLITE_OK)
                    {
                        sqlite3_bind_int( sql_statement, 1, cat );
                        sqlite3_bind_int64( sql_statement, 2, recid );
                        if (SQLITE_ERROR == sqlite3_step( sql_statement ) )
                        {
                            // Error...
                            NSLog( @"Error: failed to update ingredients record with message '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
                            
                        }
                        sqlite3_finalize( sql_statement );
                    }
                }
            }
        }
    }
    sqlite3_finalize( statement );
}



- (BOOL) dumpIngredientsToCSV:(NSString *)filename
{
    @autoreleasepool
    {
        // Preparing a statement compiles the SQL query into a byte-code program in the SQLite library.
        const char *	sql = "SELECT item, used, options, enabled, enabled_default, category_id FROM ingredients ORDER BY item ASC";
        sqlite3_stmt *	statement = NULL;
        NSString * strData = @"";
        if ( sqlite3_prepare_v2(  sqlDatabaseRef, sql, -1, &statement, NULL) == SQLITE_OK )
        {
            // We "step" through the results - once for each row
            while ( sqlite3_step(statement) == SQLITE_ROW )
            {
                const unsigned char * name = sqlite3_column_text( statement, 0 );
                int used = sqlite3_column_int( statement, 1 );
                int options = sqlite3_column_int( statement, 2 );
                int enabled = sqlite3_column_int( statement, 3 );
                int enabled_default = sqlite3_column_int( statement, 4 );
                int cat = sqlite3_column_int( statement, 5 );
                
                NSString * strRow = [NSString stringWithFormat:@"%s,%d,%d,%d,%d,%d\n", name, used, options, enabled, enabled_default, cat];
                strData = [strData stringByAppendingString:strRow];
            }
        }
        sqlite3_finalize( statement );
        if ( [strData length] > 0 )
        {
            NSError * error = nil;
            if ( ![strData writeToFile:filename atomically:YES encoding:(NSUTF8StringEncoding) error:&error] )
            {
                NSLog( @"Can't save ingredients %@", error );
                return NO;
            }
        }
    }
    return YES;
}


BOOL isInArray( NSArray * array, sqlite3_int64 recid )
{
    for ( NSNumber * num in array )
    {
        if ( [num longLongValue] == recid )
        {
            NSLog( @"duplicate ingredient: %lld", recid );
            return TRUE;
        }
    }
    return FALSE;
}

- (BOOL) importCategoriesFromCSV:(NSString *)filename
{
    FILE *	file = fopen( [filename UTF8String], "r" );
    if ( NULL == file )
        return NO;
    
    NSUInteger      column = 0;
    BOOL            endoffile = NO;
    BOOL            endofrow = NO;
    NSString *      name = nil;
    int             cat = 0;
    
    while ( ! endoffile )
    {
        @autoreleasepool
        {
            NSString * strToken = [self getNextToken:file isUnicode:NO isEndOfRow:&endofrow isEndOfFile:&endoffile];
            if ( strToken == nil )
                break;
            
            NSCharacterSet * charset = [NSCharacterSet characterSetWithCharactersInString:@"\r\n| \t,"];
            if ( [strToken length] > 0 )
            {
                NSString * token = [strToken stringByTrimmingCharactersInSet:charset];
                if ( [token length] > 0 )
                {
                    switch ( column )
                    {
                        case 0 :
                            name = token;
                            break;
                            
                        case 5 :
                            cat = (int)[token integerValue];
                            NSLog( @"Val: '%d', str = '%@'", cat, token );
                            break;
                            
                        default:
                            break;
                    }
                }
                column++;
                if ( endofrow )
                {
                    column = 0;
                    if ( name != nil )
                    {
                        sqlite3_stmt *	sql_statement = nil;
                        const char * sql = "UPDATE ingredients SET category_id=? WHERE item=?";
                        if (sqlite3_prepare_v2( sqlDatabaseRef, sql, -1, &sql_statement, NULL ) == SQLITE_OK)
                        {
                            sqlite3_bind_int( sql_statement, 1, cat );
                            sqlite3_bind_text( sql_statement, 2, [name UTF8String],  -1, SQLITE_TRANSIENT );
                            if (SQLITE_ERROR == sqlite3_step( sql_statement ) )
                            {
                                // Error...
                                NSLog( @"Error: failed to update ingredients record with message '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
                                
                            }
                            sqlite3_finalize( sql_statement );
                        }
                    }
                }
            }
        }
    }
    fclose( file );
    
    return YES;
}

- (BOOL) importFromCSV:(NSString *)filename toDatabase:(NSString *)db_file
{
    FILE *	file = fopen( [filename UTF8String], "r" );
    if ( NULL == file )
    {
        NSLog(@"Cant open CSV file %@", filename);
        return NO;
    }
    // First, test for existence.
    NSFileManager *    fileManager = [NSFileManager defaultManager];
    BOOL res = [fileManager fileExistsAtPath:db_file];
    if (res)
    {
        NSLog(@"Database file %@ already exists", db_file);
        return NO;
    }
    
    sqlDatabaseRef = [self createDatabase:db_file];
    if (NULL == sqlDatabaseRef)
        return NO;

    NSUInteger      column = 0;
    BOOL            endoffile = NO;
    MyData *        mydata = nil;
    BOOL            result = YES;
    BOOL            endofrow = NO;
    int             non_alc = 0;
    int             alc = 0;
    int             row = 0;
    
    while ( ! endoffile )
    {
        @autoreleasepool
        {
            NSString * strToken = [self getNextToken:file isUnicode:NO isEndOfRow:&endofrow isEndOfFile:&endoffile];
            if ( strToken == nil )
                break;
        
            if ( mydata == nil )
            {
                // create a new note
                mydata = [[MyData alloc] init];
                if ( mydata == nil )
                {
                    result = NO;
                    break;
                }
            }
            
            NSCharacterSet * charset = [NSCharacterSet characterSetWithCharactersInString:@"\r\n| \t,"];
            if ( [strToken length] > 0 )
            {
                NSString * token = [strToken stringByTrimmingCharactersInSet:charset];
                if ( [token length] > 0 )
                {
                    token = [NSString stringWithFormat:@"%@%@", [[token uppercaseString]substringToIndex:1], [token substringFromIndex:1]];
                    switch ( column )
                    {
                        case 1 :
                            mydata.name = token;
                            break;
                            
                        case 2 :
                            mydata.category = token;
                            break;

                        case 3 :
                            mydata.alcohol = token;
                            break;
                            
                        case 4 :
                            mydata.glass = token;
                            break;
                            
                        case 5 :
                            mydata.ingr = token;
                            break;
                            
                        case 6 :
                            mydata.instr = token;
                            break;
                            
                        case 7 :
                            mydata.shop = token;
                            // mydata.shop = [mydata.shop stringByReplacingOccurrencesOfString:@"(R)" withString:@""];
                            break;
                            
                        default:
                            break;
                    }
                }
                column++;
                if ( endofrow )
                {
                    row++;
                    if (column > 8)
                    {
                        NSLog(@"Too many columns in row %d!!!", row);
                    }
                    column = 0;
                    if ( mydata.name == nil || mydata.ingr == nil || mydata.shop == nil || mydata.category == nil || mydata.glass == nil )
                    {
                        NSLog(@"Missing data, skipping row: %d", row);
                        mydata = nil;
                        continue;
                    }

                    BOOL alcoholic = YES;
                    BOOL enabled = YES;
                    if ( [mydata.alcohol isEqualToString:@"Alcoholic"] )
                    {
                        alc++;
                    }
                    else if ( [mydata.alcohol isEqualToString:@"Optional"] )
                    {
                        enabled = NO;
                    }
                    else
                    {
                        non_alc++;
                        alcoholic = NO;
                    }
                    
                    sqlite3_int64 category_id = [self addCategory:mydata.category];
                    sqlite3_int64 glass_id = [self addGlass:mydata.glass];

                    NSArray * shoplist = [mydata.shop componentsSeparatedByString:@"|"];
                    if ( [shoplist count] < 1 )
                    {
                        NSLog(@"Missing data, skipping row: %d", row);
                        mydata = nil;
                        continue;
                    }

                    NSArray * ingrlist  = [mydata.ingr componentsSeparatedByString:@"|"];
                    NSMutableString * ingredients = [[NSMutableString alloc] initWithString:@"<ul>"];
                    for ( NSString * ingr in ingrlist )
                    {
                        if ( [ingr length] < 2 )
                            continue;
                        NSString * i = [NSString stringWithFormat:@"%@%@", [[ingr uppercaseString]substringToIndex:1], [ingr substringFromIndex:1]];
                        [ingredients appendFormat:@"<li>%@</li>\n", i];
                    }
                    [ingredients appendString:@"</ul>"];
                    
                    NSMutableArray *  itemArray = [[NSMutableArray alloc] init];
                    NSMutableString * itemString = [[NSMutableString alloc] init];
                    for ( NSString * item in shoplist )
                    {
                        if ( [item length] < 2 )
                            continue;
                        NSString * i = [NSString stringWithFormat:@"%@%@", [[item uppercaseString] substringToIndex:1], [item substringFromIndex:1]];
                        sqlite3_int64 item_id = [self addShoppingItem:i enabled:enabled];
                        if ( item_id >= 0 && (! isInArray( itemArray, item_id )) )
                        {
                            if ( [itemString length] > 0 )
                                [itemString appendString:@", "];
                            [itemString appendString:i];
                            [itemArray addObject:[NSNumber numberWithLongLong:item_id]];
                        }
                    }
                    
                    if ( [itemArray count] < 1 )
                    {
                        NSLog(@"No shopping items; skipping row: %d", row);
                        mydata = NULL;
                        continue;
                    }
                    
                    sqlite3_stmt *	sql_statement = nil;
                    // does not exist, add new
                    const char * sql_hard = "insert into harddrinks (name, ingredients, instructions, shopping, shopping_ids, shopcount, enabled, category_id, glass_id, unlocked, user_id) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
                    const char * sql_soft = "insert into softdrinks (name, ingredients, instructions, shopping, shopping_ids, shopcount, enabled, category_id, glass_id, unlocked, user_id) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
                    if (sqlite3_prepare_v2( sqlDatabaseRef, alcoholic ? sql_hard : sql_soft, -1, &sql_statement, NULL ) != SQLITE_OK)
                    {
                        NSLog( @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
                        return NO;
                    }
                    int index = 1;
                    NSError * error;
                    
                    sqlite3_bind_text( sql_statement, index++, [mydata.name UTF8String],  -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text( sql_statement, index++, [ingredients UTF8String],  -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text( sql_statement, index++, [mydata.instr UTF8String],  -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text( sql_statement, index++, [itemString UTF8String],  -1, SQLITE_TRANSIENT);
                    
                    NSData * data = [NSKeyedArchiver archivedDataWithRootObject:itemArray requiringSecureCoding:NO error:&error];
                    if (NULL == data)
                    {
                        NSLog(@"cant generate data from array; skipping row: %d", row);
                        mydata = NULL;
                        continue;
                    }
                    sqlite3_bind_blob(sql_statement, index++, [data bytes], (int)[data length], SQLITE_STATIC);
                    sqlite3_bind_int( sql_statement, index++, (int)[itemArray count] );
                    
                    sqlite3_bind_int( sql_statement, index++, enabled );
                    sqlite3_bind_int64( sql_statement, index++, category_id );
                    sqlite3_bind_int64( sql_statement, index++, glass_id );
                    sqlite3_bind_int( sql_statement, index++, 0 );
                    sqlite3_bind_int64( sql_statement, index++, 0 );
                    
                    //execute
                    int success = sqlite3_step(sql_statement);
                    
                    // sqlite3_int64 record_id = (success != SQLITE_ERROR) ? sqlite3_last_insert_rowid( sqlDatabaseRef ) : (-1);
                    // NSLog( @"Record: %lld (%@)", record_id, alcoholic ? @"alcohol" : @"non-alcohol" );
                    
                    // sqlite3_reset(sql_statement); //once we're near optimization stage we will start creating static statements in the Database class
                    // and finalize them
                    sqlite3_finalize(sql_statement);
                    if ( SQLITE_ERROR == success )
                    {
                        NSLog( @"Error: unable to add new recipe  record '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
                        return NO;
                    }
                    mydata = nil;
                }
            }
        }
    }
    fclose(file);
    
    [self autosetCategories];

    sqlite3_int64 count1 = [self getItemCount:@"glasses" filter:nil];
    sqlite3_int64 count2 = [self getItemCount:@"categories" filter:nil];
    sqlite3_int64 count3 = [self getItemCount:@"ingredients" filter:nil];
    sqlite3_int64 count5 = [self getItemCount:@"ingredients" filter:@"enabled=0"];
    
    NSLog( @"Import complete: alc: %d   non-alc: %d", alc, non_alc );
    NSLog( @"glasses: %lld  categories: %lld  ingredients: %lld disabled ingredients: %lld-", count1, count2, count3, count5 );
    
    [self updateGlassCounts];
    [self updateCategoryCounts];
    return YES;
}

-(unichar) getchar:(FILE *)file isUnicode:(BOOL)unicode
{
    unichar ch = 0;
    if ( unicode )
    {
        if ( fread( &ch, 1, 2, file ) < 1 )
            ch = 0;
    }
    else
    {
        unsigned char c = 0;
        if ( fread( &c, 1, 1, file ) > 0 )
            ch = c;
    }
    return ch;
}

-(void) putback:(FILE *)file isUnicode:(BOOL)unicode
{
    if ( unicode )
        fseek( file, -2, SEEK_CUR );
    else
        fseek( file, -1, SEEK_CUR );
}


-(NSString *)getNextToken:(FILE *)file isUnicode:(BOOL)unicode isEndOfRow:(BOOL *)endofrow isEndOfFile:(BOOL *)endoffile
{
    NSMutableString * strToken = [[NSMutableString alloc] init];
    Boolean bQuotes = NO;
    *endofrow = NO;
    *endoffile = NO;
    unichar ch1, ch = 0;
    
    while ( (ch = [self getchar:file isUnicode:NO]) )
    {
        if ( ch == '\\' )
        {
            ch1 = [self getchar:file isUnicode:unicode];
            if ( ch1 == '\r' || ch1 == '\n' )
            {
                if ( [strToken length] < 1 || [strToken characterAtIndex:[strToken length]-1] != '\n' )
                    [strToken appendString:@"\n"];
            }
            else if ( ch1 != '\"')
            {
                [self putback:file isUnicode:unicode];
            }
            continue;
        }
        if ( bQuotes )
        {
            if ( ch == '\r' )
                continue;
            else if ( ch == '\"' )
            {
                ch1 = [self getchar:file isUnicode:unicode];
                if ( ch1 == '\"' )
                {
                    [strToken appendString:@"\""];
                }
                else
                {
                    [self putback:file isUnicode:unicode];
                    bQuotes = NO;
                }
            }
            else
            {
                [strToken appendString:[NSString stringWithCharacters:&ch length:1]];
            }
        }
        else
        {
            if ( ch == '\r' )
            {
                // ignore \r
                *endofrow = YES;
                break;
            }
            else if ( ch == '\n' )
            {
                // end of row
                *endofrow = YES;
                break;
            }
            else if ( ch == '\"' )
                bQuotes = YES;
            else if ( ch == ',' )
                break;		// end of column
            else
                [strToken appendString:[NSString stringWithCharacters:&ch length:1]];
        }
    }
    if ( ch == 0 )
    {
        *endofrow = YES;
        *endoffile = YES;
    }
    return strToken;
}

- (void) updateGlassCounts
{
    const char * sql = "SELECT grecord_id, glass glass FROM glasses";
    sqlite3_stmt *	statement = NULL;
    if ( sqlite3_prepare_v2(  sqlDatabaseRef, sql, -1, &statement, NULL) == SQLITE_OK )
    {
        while ( sqlite3_step(statement) == SQLITE_ROW )
        {
            sqlite3_int64   rec_id = sqlite3_column_int64( statement, 0 );
            NSString *      filter = [NSString stringWithFormat:@"glass_id=%lld", rec_id];
            sqlite3_int64   count = [self getItemCount:@"harddrinks" filter:filter];
            count += [self getItemCount:@"softdrinks" filter:filter];
            
            const unsigned char * name = sqlite3_column_text( statement, 1 );
            NSLog( @"Glass %lld (%@)   count %lld", rec_id, [NSString stringWithUTF8String:(const char *)name], count );
            
            if ( count > 0 )
            {
                sqlite3_stmt *	sql_statement = nil;
                const char * sql = "UPDATE glasses SET count=? WHERE grecord_id=?";
                if (sqlite3_prepare_v2( sqlDatabaseRef, sql, -1, &sql_statement, NULL ) == SQLITE_OK)
                {
                    sqlite3_bind_int64( sql_statement, 1, count );
                    sqlite3_bind_int64( sql_statement, 2, rec_id );
                    if (SQLITE_ERROR == sqlite3_step( sql_statement ) )
                    {
                        // Error...
                        NSLog( @"Error: failed to update glasses record with message '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
                        
                    }
                    sqlite3_finalize( sql_statement );
                }
            }
        }
    }
    else
    {
        NSLog( @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
    }
    sqlite3_finalize( statement );
}

- (void) updateCategoryCounts
{
    const char * sql = "SELECT crecord_id, category FROM categories";
    sqlite3_stmt *	statement = NULL;
    if ( sqlite3_prepare_v2(  sqlDatabaseRef, sql, -1, &statement, NULL) == SQLITE_OK )
    {
        while ( sqlite3_step(statement) == SQLITE_ROW )
        {
            sqlite3_int64   rec_id = sqlite3_column_int64( statement, 0 );
            NSString *      filter = [NSString stringWithFormat:@"category_id=%lld", rec_id];
            sqlite3_int64   count = [self getItemCount:@"harddrinks" filter:filter];
            count += [self getItemCount:@"softdrinks" filter:filter];
            
            const unsigned char * name = sqlite3_column_text( statement, 1 );
            NSLog( @"Category %lld (%@)   count %lld", rec_id, [NSString stringWithUTF8String:(const char *)name], count );

            if ( count > 0 )
            {
                sqlite3_stmt *	sql_statement = nil;
                const char * sql = "UPDATE categories SET count=? WHERE crecord_id=?";
                if (sqlite3_prepare_v2( sqlDatabaseRef, sql, -1, &sql_statement, NULL ) == SQLITE_OK)
                {
                    sqlite3_bind_int64( sql_statement, 1, count );
                    sqlite3_bind_int64( sql_statement, 2, rec_id );
                    if (SQLITE_ERROR == sqlite3_step( sql_statement ) )
                    {
                        // Error...
                        NSLog( @"Error: failed to update categories record with message '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
                        
                    }
                    sqlite3_finalize( sql_statement );
                }
            }
        }
    }
    else
    {
        NSLog( @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
    }
    sqlite3_finalize( statement );
}

#endif // IMPORT_FROM_CSV

@end

/*
 EMPTY DATABASE STRUCTURE:
 
 CREATE TABLE harddrinks( record_id integer PRIMARY KEY NOT NULL, name text, ingredients text, instructions text, rating integer, comments text, user_id integer, shopping text, category_id integer, shopcount integer, glass_id integer, shopping_ids blob, enabled boolean, unlocked boolean, FOREIGN KEY(glass_id) REFERENCES glasses(grecord_id), FOREIGN KEY(category_id) REFERENCES categories(crecord_id) );
 CREATE TABLE softdrinks( record_id integer PRIMARY KEY NOT NULL, name text, ingredients text, instructions text, rating integer, comments text, user_id integer, shopping text, category_id integer, shopcount integer, glass_id integer, shopping_ids blob, enabled boolean, unlocked boolean, FOREIGN KEY(glass_id) REFERENCES glasses(grecord_id), FOREIGN KEY(category_id) REFERENCES categories(crecord_id) );
 CREATE TABLE glasses( grecord_id integer PRIMARY KEY NOT NULL, glass text, count integer );
 CREATE TABLE categories( crecord_id integer PRIMARY KEY NOT NULL, category text, count integer );
 CREATE TABLE ingredients( record_id integer PRIMARY KEY NOT NULL, item text, used integer, options integer, enabled boolean, enabled_default boolean, category_id integer );
 
 CREATE TABLE ingredient_types ( 'record_id' INTEGER PRIMARY KEY, category TEXT, category_id integer );
 INSERT INTO ingredient_types (category, category_id) VALUES ('Vodka', 1);
 INSERT INTO ingredient_types (category, category_id) VALUES ('Gin', 2);
 INSERT INTO ingredient_types (category, category_id) VALUES ('Rum', 3);
 INSERT INTO ingredient_types (category, category_id) VALUES ('Whiskey', 4);
 INSERT INTO ingredient_types (category, category_id) VALUES ('Brandy / Cognac', 5);
 INSERT INTO ingredient_types (category, category_id) VALUES ('Tequila', 6);
 INSERT INTO ingredient_types (category, category_id) VALUES ('Schnapps', 7);
 INSERT INTO ingredient_types (category, category_id) VALUES ('Liqueur', 8);
 INSERT INTO ingredient_types (category, category_id) VALUES ('Other Liquors', 19);
 INSERT INTO ingredient_types (category, category_id) VALUES ('Wine / Port / Vermouth', 9);
 INSERT INTO ingredient_types (category, category_id) VALUES ('Beer / Malt / Cooler', 13);
 INSERT INTO ingredient_types (category, category_id) VALUES ('Juice / Syrup / Mix', 11);
 INSERT INTO ingredient_types (category, category_id) VALUES ('Soda / Soft Drinks', 10);
 INSERT INTO ingredient_types (category, category_id) VALUES ('Milk / Cream / Ice Cream', 12);
 INSERT INTO ingredient_types (category, category_id) VALUES ('Coffee / Tea / Cocoa', 18);
 INSERT INTO ingredient_types (category, category_id) VALUES ('Fruit / Berries / Nuts', 14);
 INSERT INTO ingredient_types (category, category_id) VALUES ('Jello / Puree / Sweetener', 17);
 INSERT INTO ingredient_types (category, category_id) VALUES ('Garnish / Spice / Sauce', 15);
 INSERT INTO ingredient_types (category, category_id) VALUES ('Miscellaneous', 16);

 
 */


/*
 SOME USEFUL DATA
 
 2015-01-03 19:36:17.100 shaker[61060:10640271] Alc - 16107   non-alc - 195
 2015-01-03 19:36:17.100 shaker[61060:10640271] glasses (39)  categories (11)  ingredients (2016) disabled ingredients (1299)
 2015-01-03 19:36:17.111 shaker[61060:10640271] Glass 1 (Any Glass)   count 1079
 2015-01-03 19:36:17.143 shaker[61060:10640271] Glass 2 (Cocktail glass)   count 3430
 2015-01-03 19:36:17.156 shaker[61060:10640271] Glass 3 (Old-fashioned glass)   count 1751
 2015-01-03 19:36:17.183 shaker[61060:10640271] Glass 4 (Shot glass)   count 2378
 2015-01-03 19:36:17.195 shaker[61060:10640271] Glass 5 (Highball glass)   count 2975
 2015-01-03 19:36:17.208 shaker[61060:10640271] Glass 6 (Collins glass)   count 1428
 2015-01-03 19:36:17.228 shaker[61060:10640271] Glass 7 (Beer mug)   count 314
 2015-01-03 19:36:17.241 shaker[61060:10640271] Glass 8 (White wine glass)   count 128
 2015-01-03 19:36:17.253 shaker[61060:10640271] Glass 9 (Coffee mug)   count 126
 2015-01-03 19:36:17.265 shaker[61060:10640271] Glass 10 (Margarita Glass)   count 195
 2015-01-03 19:36:17.278 shaker[61060:10640271] Glass 11 (Champagne flute)   count 232
 2015-01-03 19:36:17.290 shaker[61060:10640271] Glass 12 (Mason jar)   count 112
 2015-01-03 19:36:17.303 shaker[61060:10640271] Glass 13 (Irish coffee cup)   count 170
 2015-01-03 19:36:17.316 shaker[61060:10640271] Glass 14 (Hurricane glass)   count 606
 2015-01-03 19:36:17.328 shaker[61060:10640271] Glass 15 (Beer pilsner)   count 66
 2015-01-03 19:36:17.340 shaker[61060:10640271] Glass 16 (Punch bowl)   count 121
 2015-01-03 19:36:17.353 shaker[61060:10640271] Glass 17 (Whiskey sour glass)   count 103
 2015-01-03 19:36:17.366 shaker[61060:10640271] Glass 18 (Red wine glass)   count 72
 2015-01-03 19:36:17.377 shaker[61060:10640271] Glass 19 (Brandy snifter)   count 106
 2015-01-03 19:36:17.389 shaker[61060:10640271] Glass 20 (Pousse cafe glass)   count 35
 2015-01-03 19:36:17.401 shaker[61060:10640271] Glass 21 (Parfait glass)   count 94
 2015-01-03 19:36:17.414 shaker[61060:10640271] Glass 22 (Cordial glass)   count 93
 2015-01-03 19:36:17.426 shaker[61060:10640271] Glass 23 (Pint glass)   count 83
 2015-01-03 19:36:17.437 shaker[61060:10640271] Glass 24 (Sherry glass)   count 16
 2015-01-03 19:36:17.449 shaker[61060:10640271] Glass 25 (Pitcher)   count 63
 2015-01-03 19:36:17.463 shaker[61060:10640271] Glass 26 (Cup)   count 132
 2015-01-03 19:36:17.475 shaker[61060:10640271] Glass 27 (Bucket)   count 4
 2015-01-03 19:36:17.487 shaker[61060:10640271] Glass 28 (Test tube)   count 7
 2015-01-03 19:36:17.499 shaker[61060:10640271] Glass 29 (Sour Glass)   count 86
 2015-01-03 19:36:17.512 shaker[61060:10640271] Glass 30 (Wine Goblet)   count 83
 2015-01-03 19:36:17.529 shaker[61060:10640271] Glass 31 (Aperitif Glass)   count 13
 2015-01-03 19:36:17.542 shaker[61060:10640271] Glass 32 (Mug)   count 33
 2015-01-03 19:36:17.555 shaker[61060:10640271] Glass 33 (Bottle)   count 12
 2015-01-03 19:36:17.587 shaker[61060:10640271] Glass 34 (Coupe glass)   count 8
 2015-01-03 19:36:17.599 shaker[61060:10640271] Glass 35 (Pina Colada Glass)   count 68
 2015-01-03 19:36:17.611 shaker[61060:10640271] Glass 36 (Cooler)   count 4
 2015-01-03 19:36:17.635 shaker[61060:10640271] Glass 37 (Champagne Saucer)   count 90
 2015-01-03 19:36:17.648 shaker[61060:10640271] Glass 38 (Champagne Tulip)   count 8
 2015-01-03 19:36:17.661 shaker[61060:10640271] Glass 39 (Jug)   count 12
 2015-01-03 19:36:17.673 shaker[61060:10640271] Category 1 (Beer)   count 59
 2015-01-03 19:36:17.692 shaker[61060:10640271] Category 2 (Cocktail)   count 9997
 2015-01-03 19:36:17.704 shaker[61060:10640271] Category 3 (Shot)   count 2861
 2015-01-03 19:36:17.717 shaker[61060:10640271] Category 4 (Milk / Float / Shake)   count 146
 2015-01-03 19:36:17.728 shaker[61060:10640271] Category 5 (Ordinary Drink)   count 2297
 2015-01-03 19:36:17.747 shaker[61060:10640271] Category 6 (Coffee / Tea)   count 109
 2015-01-03 19:36:17.760 shaker[61060:10640271] Category 7 (Punch / Party Drink)   count 385
 2015-01-03 19:36:17.771 shaker[61060:10640271] Category 8 (Other/Unknown)   count 326
 2015-01-03 19:36:17.783 shaker[61060:10640271] Category 9 (Homemade Liqueur)   count 52
 2015-01-03 19:36:17.802 shaker[61060:10640271] Category 10 (Soft Drink / Soda)   count 71
 2015-01-03 19:36:17.815 shaker[61060:10640271] Category 11 (Cocoa)   count 33

 */


