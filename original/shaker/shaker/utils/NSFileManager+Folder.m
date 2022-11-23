//
//  NSFileManager+Folder.m
//  shaker
//
//  Created by Stanislav Miasnikov on 7/5/15.
//  Copyright (c) 2015 PhatWare Corp. All rights reserved.
//

#import "NSFileManager+Folder.h"

@implementation NSFileManager (FolderAdditions)

+ (NSString *) documentsPath
{
    NSArray *   paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *  documentsPath = [paths objectAtIndex:0];
    return documentsPath;
}

+ (NSString *) sharedPath
{
    NSString * ShakerPadUbiqID = @"group.com.phunkware.shaker";
    NSURL * containerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:ShakerPadUbiqID];
    return [containerURL path];
}

+ (BOOL) moveToShared:(NSString *)fileName error:(NSError **)error
{
    NSString * from = [NSFileManager documentsPath];
    from = [from stringByAppendingPathComponent:fileName];
    NSString * to = [NSFileManager sharedPath];
    to = [to stringByAppendingPathComponent:fileName];
    return [[NSFileManager defaultManager] moveItemAtPath:from toPath:to error:error];
}

@end
