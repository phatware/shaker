//
//  NSFileManager+Folder.h
//  shaker
//
//  Created by Stanislav Miasnikov on 7/5/15.
//  Copyright (c) 2015 PhatWare Corp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (FolderAdditions)

+ (NSString *) documentsPath;
+ (NSString *) sharedPath;
+ (BOOL) moveToShared:(NSString *)fileName error:(NSError **)error;

@end
