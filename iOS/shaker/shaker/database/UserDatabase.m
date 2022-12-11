//
//  UserDatabase.m
//  shaker
//
//  Created by Stanislav Miasnikov on 12/15/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import "UserDatabase.h"
#import "NSFileManager+Folder.h"

@interface UserDatabase()
{
    BOOL            modified;
    sqlite3 *       sqlDatabaseRef;
    sqlite3_int64   record_count;
}

@property (nonatomic, strong) NSString * databasename;

@end

@implementation UserDatabase

// Creates a writable copy of the bundled default database in the application Documents directory.
- (BOOL)createEditableCopyOfDatabaseIfNeeded
{
    NSFileManager *	fileManager = [NSFileManager defaultManager];
    NSError *		error = nil;
    BOOL res = [fileManager fileExistsAtPath:self.databasename];
//    if ( !res )
//    {
//        NSString *  documentsPath = [NSFileManager documentsPath];
//        NSString *  name = [documentsPath stringByAppendingPathComponent:@"user.sql"];
//        res = [fileManager fileExistsAtPath:name];
//        if ( res )
//        {
//            res = [NSFileManager moveToShared:@"user.sql" error:&error];
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
        NSString *	defaultDatabase = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"user.sql"];
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
    NSString *      strSql = [NSString stringWithFormat:@"select count(*) from %@", tableName];
    
    if ( filter != nil )
    {
        strSql = [NSString stringWithFormat:@"%@ where %@", strSql, filter];
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

// Open the database connection and retrieve minimal information for all objects.
- (Boolean) initializeDatabase
{
    self.databasename = [[NSFileManager documentsPath] stringByAppendingPathComponent:@"user.sql"];
    if( ! [self createEditableCopyOfDatabaseIfNeeded] )
        return NO;
    // Open the database. The database was prepared outside the application.
    sqlDatabaseRef = NULL;
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
    
    record_count = [self getItemCount:@"userdata" filter:nil];
    // initialize user data
    return YES;
}

- (void) dealloc
{
    self.databasename = nil;
    if ( sqlDatabaseRef )
        sqlite3_close( sqlDatabaseRef );
    sqlDatabaseRef = NULL;
}

- (sqlite3_int64) createNewUserRecord:(sqlite3_int64)coctail_id
{
    sqlite3_int64 record_id = 0;
    sqlite3_stmt *	sql_statement = nil;
    
    // does not exist, add new
    const char * sql = "INSERT INTO userdata (visible, coctail_id) VALUES (?, ?)";
    if (sqlite3_prepare_v2( sqlDatabaseRef, sql, -1, &sql_statement, NULL ) != SQLITE_OK)
    {
        NSLog( @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
        return NO;
    }
    sqlite3_bind_int( sql_statement, 1, 1 );
    sqlite3_bind_int64( sql_statement, 2, coctail_id );
    int success = sqlite3_step(sql_statement);
    
    record_id = (success != SQLITE_ERROR) ? sqlite3_last_insert_rowid( sqlDatabaseRef ) : 0;
    sqlite3_finalize(sql_statement);
    if ( SQLITE_ERROR == success )
    {
        NSLog( @"Error: unable to add new recipe  record '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
    }
    return record_id;
}

#ifdef IMAGE_SUPPORT
- (UIImage *) getPhoto:(sqlite3_int64)record_id
{
    const char *	sql = [[NSString stringWithFormat:@"SELECT photo FROM userdata WHERE record_id = %lld",
                            record_id] UTF8String];
    
    sqlite3_stmt *	statement = NULL;
    UIImage * image = nil;
    
    if ( sqlite3_prepare_v2(  sqlDatabaseRef, sql, -1, &statement, NULL) == SQLITE_OK )
    {
        if ( sqlite3_step(statement) == SQLITE_ROW )
        {
            const void * data_ptr = sqlite3_column_blob( statement, 0 );
            int data_len = sqlite3_column_bytes( statement, 0 );
            if ( data_ptr != NULL && data_len > 0 )
            {
                NSData * imagedata = [NSData dataWithBytes:data_ptr length:data_len];
                if ( imagedata )
                {
                    image = [UIImage imageWithData:imagedata];
                }
            }
        }
        sqlite3_finalize( statement );
    }
    return image;
}
#endif

- (NSDictionary *) getUserRecord:(sqlite3_int64)record_id noImage:(BOOL)noImage
{
    const char *	sql = [[NSString stringWithFormat:@"SELECT note, rating, favorite, visible, coctail_id%@ FROM userdata WHERE record_id = %lld", noImage ? @"" : @", photo",
                            record_id] UTF8String];
    
    sqlite3_stmt *	statement = NULL;
    
    NSMutableDictionary * result = nil;
    const unsigned char * value;
    
    if ( sqlite3_prepare_v2(  sqlDatabaseRef, sql, -1, &statement, NULL) == SQLITE_OK )
    {
        if ( sqlite3_step(statement) == SQLITE_ROW )
        {
            result = [[NSMutableDictionary alloc] init];
            value = sqlite3_column_text( statement, 0 );
            if ( value != NULL )
                [result setObject:[NSString stringWithUTF8String:(const char *)value] forKey:@"note"];
            [result setObject:[NSNumber numberWithInt:sqlite3_column_int( statement, 1 )] forKey:@"userrating"];
            [result setObject:[NSNumber numberWithBool:sqlite3_column_int( statement, 2 )==0 ? NO : YES] forKey:@"favorite"];
            [result setObject:[NSNumber numberWithBool:sqlite3_column_int( statement, 3 )==0 ? NO : YES] forKey:@"visible"];
            [result setObject:[NSNumber numberWithLongLong:sqlite3_column_int64( statement, 4 )] forKey:@"coctail_id"];
#ifdef IMAGE_SUPPORT
            if ( ! noImage )
            {
                const void * data_ptr = sqlite3_column_blob( statement, 5 );
                int data_len = sqlite3_column_bytes( statement, 5 );
                if ( data_ptr != NULL && data_len > 0 )
                {
                    NSData * imagedata = [NSData dataWithBytes:data_ptr length:data_len];
                    if ( imagedata )
                    {
                        UIImage * image = [UIImage imageWithData:imagedata];
                        if ( image )
                            [result setObject:image forKey:@"photo"];
                    }
                }
            }
#endif //
        }
        sqlite3_finalize( statement );
    }
    return (NSDictionary *)result;
}

- (BOOL) updateUserRecord:(sqlite3_int64)record_id note:(NSString *)note rating:(int)rating visible:(BOOL)visible
{
    BOOL result = NO;
    sqlite3_stmt *	statement = NULL;
    const char * sql = "UPDATE userdata SET note=?, rating=?, visible=? WHERE record_id=?";
    if (sqlite3_prepare_v2( sqlDatabaseRef, sql, -1, &statement, NULL ) == SQLITE_OK)
    {
        sqlite3_bind_text( statement, 1, (note== nil) ? "" : [note UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int( statement, 2, rating );
        sqlite3_bind_int( statement, 3, visible ? 1 : 0 );
        sqlite3_bind_int64( statement, 4, record_id );
        if (SQLITE_ERROR == sqlite3_step( statement ) )
        {
            // Error...
            NSLog( @"Error: failed to update ingredients record with message '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
        }
        else
        {
            result = YES;
        }
        sqlite3_finalize( statement );
    }
    return result;
}

- (BOOL) updateUserPhoto:(NSData *)photo record:(sqlite3_int64)record_id
{
    BOOL result = NO;
    sqlite3_stmt *	statement = NULL;
    const char * sql = "UPDATE userdata SET photo=? WHERE record_id=?";
    if (sqlite3_prepare_v2( sqlDatabaseRef, sql, -1, &statement, NULL ) == SQLITE_OK)
    {
        if ( photo != nil )
        {
            if (sqlite3_bind_blob( statement, 1, [photo bytes], (int)[photo length], SQLITE_STATIC) == SQLITE_OK)
            {
            }
        }
        else
        {
            sqlite3_bind_blob( statement, 1, NULL, 0, SQLITE_STATIC);
        }
        sqlite3_bind_int64( statement, 2, record_id );
        if (SQLITE_ERROR == sqlite3_step( statement ) )
        {
            // Error...
            NSLog( @"Error: failed to update ingredients record with message '%s'.", sqlite3_errmsg( sqlDatabaseRef ) );
        }
        else
        {
            result = YES;
        }
        sqlite3_finalize( statement );
    }
    return result;
}

@end


/*

 CREATE TABLE userpreferences( record_id integer PRIMARY KEY NOT NULL, flags integer );
 CREATE TABLE userdata( record_id integer PRIMARY KEY NOT NULL, note text, rating integer, favorite boolean, visible integer, photo blob, drawing blob, coctail_id integer );

*/
