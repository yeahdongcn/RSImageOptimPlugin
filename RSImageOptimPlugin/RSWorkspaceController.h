//
//  RSWorkspaceController.h
//  RSImageOptimPlugin
//
//  Created by R0CKSTAR on 4/9/14.
//  Copyright (c) 2014 P.D.Q. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IDEWorkspaceWindowController;

@interface RSWorkspaceController : NSObject

+ (NSString *)pathForFileNameInCurrentWorkspace:(NSString *)fileName;

+ (NSString *)currentWorkspaceDirectoryPath;

@end
