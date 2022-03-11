//
//  GContentsManager.m
//  KTmPlayer
//
//  Created by 김현준 on 2017. 7. 13..
//  Copyright © 2017년 wally. All rights reserved.
//

#import "GContentsManager.h"
#import "NSData+AESCrypto.h"

static NSString *MusicFolder = @"Music Folder";
static NSString *FOLDER_NAME = @"MusicSaveFile";

@implementation GContentsManager

NSString *DesktopPath() {
    NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDesktopDirectory, NSUserDomainMask, YES);
    NSString *desktopPath = [paths objectAtIndex:0];
    return desktopPath;
}

NSString *GetFilePath(NSString *fileNameString,NSString *extension) {
    
    NSString *extensionStr = extension?extension:@"";
    NSArray *paths = NSSearchPathForDirectoriesInDomains(MyAppDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    CreateFolderWithPath([NSString stringWithFormat:@"%@/%@",documentsDirectory,FOLDER_NAME]);
    
    return [NSString stringWithFormat:@"%@/%@/%@.%@",documentsDirectory,FOLDER_NAME,fileNameString,extensionStr];
}

NSMutableArray *FindSongPathsFromFolder(NSString *path) {
    NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path
                                                                        error:NULL];
    NSMutableArray *files = [NSMutableArray new];
    for (NSString *destName in dirs) {
        NSString *depthPath = [NSString stringWithFormat:@"%@/%@",path,destName];
        
        if ([destName rangeOfString:@"DS_Store"].location != NSNotFound) {
            continue;
        }
        
        NSString *extension = [[destName pathExtension] lowercaseString];
        if ([extension isEqual:@"mp3"] ||
            /*[extension isEqual:@"aac"] ||*/
            [extension isEqual:@"flac"]) {
            [files addObject:depthPath];
        }else{
            [files addObjectsFromArray:FindSongPathsFromFolder(depthPath)];
        }
    }
    
    return files;
}

NSString *ConvertFileNameWithPath(NSString *path) {
    
    if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
        NSURL *tempPath = [NSURL fileURLWithPath:path];
        NSString *extension = [[tempPath pathExtension] lowercaseString];
        extension = [NSString stringWithFormat:@".%@",extension];
        path = [path stringByReplacingOccurrencesOfString:extension withString:@""];
        
        //999개 중첩이 있을경우 까지만 예외처리..
        if (path.length > 3) {
            NSString *lastStr = [path substringWithRange:NSMakeRange(path.length-4, 4)];
            if ([lastStr rangeOfString:@" "].location != NSNotFound) {
                NSString *cntStr = [[lastStr componentsSeparatedByString:@" "] lastObject];
                NSInteger cnt = cntStr.integerValue;
                cnt++;
                lastStr = [NSString stringWithFormat:@"%@",@(cnt)];
                path = [path stringByReplacingCharactersInRange:NSMakeRange(path.length-cntStr.length, cntStr.length) withString:lastStr];
                
            }else{
                path = [path stringByAppendingString:@" 2"];
            }
            path = [path stringByAppendingString:extension];
            
            return ConvertFileNameWithPath(path);
        }
    }
    
    return path;
}

NSString *CreateDirectoryFolderPath(NSString *fileNameString) {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(MyAppDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *path = [NSString stringWithFormat:@"%@/%@",documentsDirectory,FOLDER_NAME];
    CreateFolderWithPath(path);
    
    path = [NSString stringWithFormat:@"%@/%@/%@",documentsDirectory,FOLDER_NAME,fileNameString];
    CreateFolderWithPath(path);
    
    return path;
}

BOOL CreateFolderWithPath(NSString *path) {
    BOOL isSuccess = YES;
    
    if (![[NSFileManager defaultManager]fileExistsAtPath:path]) {
        
        NSError *err;
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&err];
        
        if (err)isSuccess = NO;
    }
    
    return isSuccess;
}

BOOL CreateFileWithPath(NSString *path,id data) {
    BOOL isSuccess = NO;
    
    if (![[NSFileManager defaultManager]fileExistsAtPath:path]) {
        [[NSFileManager defaultManager]createFileAtPath:path contents:nil attributes:nil];
    }
    
    isSuccess = [data writeToFile:path atomically:YES];
    return isSuccess;
}

__attribute__((overloadable)) BOOL RemoveContentsFolder(void) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(MyAppDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *path = [NSString stringWithFormat:@"%@/%@",documentsDirectory,FOLDER_NAME];
    
    return RemoveFileWithPath(path);
}

__attribute__((overloadable)) BOOL RemoveContentsFolder(NSString *path) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(MyAppDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *totalPath = [NSString stringWithFormat:@"%@/%@/%@",documentsDirectory,FOLDER_NAME,path];
    
    return RemoveFileWithPath(totalPath);
}

BOOL RemoveFileWithPath(NSString *path) {
    BOOL isSuccess = NO;
    
    if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
        NSError *err = nil;
        [[NSFileManager defaultManager]removeItemAtPath:path error:&err];
        
        if (!err) {
            isSuccess = YES;
        }
    }
    
    NSString *LOG = [NSString stringWithFormat:@"\
                     DELETE FILE : %@\n\
                     PATH : %@",isSuccess?@"성공":@"실패",path];
    NSLog(@"LOG_LOCALFILE : %@",LOG);
    
    return isSuccess;
}

#pragma mark - Archiving
BOOL SaveArchiving(NSObject *obj,Class class,NSString *path) {
    BOOL isSuccess = NO;
    {
        @try {
            NSString *className = NSStringFromClass(class);
            
            NSMutableData *data = [NSMutableData new];
            NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
            [archiver encodeObject:obj forKey:className];
            [archiver finishEncoding];
            data = [[data dataEncrypt] mutableCopy];
            isSuccess = CreateFileWithPath(path,data);
        } @catch (NSException *exception) {
            isSuccess = NO;
        }
    }
    
    NSString *LOG = [NSString stringWithFormat:@"\
                     SAVE FILE : %@\n\
                     PATH : %@",isSuccess?@"성공":@"실패",path];
    NSLog(@"LOG_LOCALFILE : %@",LOG);
    return isSuccess;
}

id LoadArchiving(Class class,NSString *path) {
    
    NSString *className = NSStringFromClass(class);
    
    NSData *archiveData = [NSData dataWithContentsOfFile:path];
    archiveData = [archiveData dataDecrypt];
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:archiveData];
    
    NSObject *obj = [unarchiver decodeObjectForKey:className];
    id resultObj = obj;
    if ([obj isKindOfClass:[NSArray class]]) {
        resultObj = [NSArray arrayWithArray:(NSArray *)obj].mutableCopy;
    }
    
    if ([obj isKindOfClass:[NSDictionary class]]) {
        resultObj = [NSDictionary dictionaryWithDictionary:(NSDictionary *)obj].mutableCopy;
    }
    
    [unarchiver finishDecoding];
    
    return resultObj;
}

@end
