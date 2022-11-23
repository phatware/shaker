//
//  main.m
//  shakerdb
//
//  Created by Stan Miasnikov on 11/11/22.
//

#import <Foundation/Foundation.h>
#import "CoctailsDatabase.h"

int main(int argc, const char * argv[])
{
    @autoreleasepool
    {
        CoctailsDatabase * db = [[CoctailsDatabase alloc] init];
        
        if (argc < 2)
        {
            printf("Usage: shakerdb <infile.csv> [outfile.sql]\n");
            return -1;
        }
        
        NSString * db_file;
        NSString * csv_file = [NSString stringWithUTF8String:argv[1]];
        if (argc > 2)
        {
            db_file = [NSString stringWithUTF8String:argv[2]];
        }
        else
        {
            db_file = [csv_file stringByDeletingPathExtension];
            db_file = [db_file stringByAppendingPathExtension:@"sql"];
        }
        
        BOOL res = [db importFromCSV:csv_file toDatabase:db_file];
        if (res)
            printf("Import completed successfully!\n");
        else
            printf("Import completed with error!\n");
    }
    return 0;
}
