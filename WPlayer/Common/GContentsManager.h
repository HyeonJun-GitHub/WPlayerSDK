//
//  GContentsManager.h
//  KTmPlayer
//
//  Created by 김현준 on 2017. 7. 13..
//  Copyright © 2017년 wally. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSSearchPathDirectory MyAppDirectory = NSCachesDirectory;

@interface GContentsManager : NSObject

#pragma mark - File
NSString *DesktopPath(void);
NSString *GetFilePath(NSString *fileNameString,NSString *extension);
NSMutableArray *FindSongPathsFromFolder(NSString *path);

BOOL CreateFileWithPath(NSString *path,id data);


/**
 동일 파일 체크 후 이름 변경( 카운트) 0,2~ 999 까지
 @param path 파일 전체경로
 @return 변경된 경로
 */
NSString *ConvertFileNameWithPath(NSString *path);
NSString *CreateDirectoryFolderPath(NSString *fileNameString);
BOOL RemoveFileWithPath(NSString *path);
__attribute__((overloadable)) BOOL RemoveContentsFolder(void);
__attribute__((overloadable)) BOOL RemoveContentsFolder(NSString *path);
#pragma mark - Archiving
BOOL SaveArchiving(NSObject *obj,Class class,NSString *path);
id LoadArchiving(Class class,NSString *path);
@end
