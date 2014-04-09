//
//  RSWorkspaceController.m
//  RSImageOptimPlugin
//
//  Created by R0CKSTAR on 4/9/14.
//  Copyright (c) 2014 P.D.Q. All rights reserved.
//

#import "RSWorkspaceController.h"

#import "IDEKit.h"

/* the signature in IDEFoundation.h is incorrect (oudated?) for xcode5
 * @see https://github.com/questbeat/Lin/blob/master/Lin/Lin.m
 */
@interface IDEIndex (fix)

- (id)filesContaining:(id)arg1 anchorStart:(BOOL)arg2 anchorEnd:(BOOL)arg3 subsequence:(BOOL)arg4 ignoreCase:(BOOL)arg5 cancelWhen:(id)arg6;

@end

@implementation RSWorkspaceController

+ (IDEWorkspaceWindowController *)keyWindowController
{
    NSArray *workspaceWindowControllers = [NSClassFromString(@"IDEWorkspaceWindowController") valueForKey:@"workspaceWindowControllers"];
    for (IDEWorkspaceWindowController *controller in workspaceWindowControllers)
    {
        if (controller.window.isKeyWindow)
        {
            return controller;
        }
    }
    return nil;
}

+ (id)workspaceForKeyWindow
{
    return [[self keyWindowController] valueForKey:@"_workspace"];
}

+ (NSString *)pathForFileNameInCurrentWorkspace:(NSString *)fileName
{
    IDEWorkspace *workspace = [self workspaceForKeyWindow];
    
    if (workspace == nil)
    {
        return nil;
    }
    
    IDEIndexCollection *indexCollection = [workspace.index filesContaining:fileName anchorStart:NO anchorEnd:NO subsequence:NO ignoreCase:NO cancelWhen:nil];
    
    for(DVTFilePath *filePath in indexCollection)
    {
        return filePath.pathString;
    }
    
    return nil;
}

+ (NSString *)currentWorkspaceDirectoryPath
{
    IDEWorkspace *workspace = [self workspaceForKeyWindow];
    NSString *workspacePath = [workspace.representingFilePath pathString];
    return [workspacePath stringByDeletingLastPathComponent];
}

@end
