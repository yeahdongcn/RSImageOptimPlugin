//
//  RSImageOptimPlugin.m
//  RSImageOptimPlugin
//
//  Created by R0CKSTAR on 4/9/14.
//  Copyright (c) 2014 P.D.Q. All rights reserved.
//

#import "RSImageOptimPlugin.h"

#import "IDEFoundation.h"

#import "RSWorkspaceController.h"

static RSImageOptimPlugin *sharedPlugin;

@interface RSImageOptimPlugin()

@property (nonatomic, strong) NSBundle *bundle;

@end

static NSString *const kRSImageOptimPlugin        = @"com.pdq.rsimageoptimplugin";
static NSString *const kRSImageOptimPluginAutoKey = @"com.pdq.rsimageoptimplugin.auto";

@implementation RSImageOptimPlugin

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static id sharedPlugin = nil;
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[self alloc] initWithBundle:plugin];
        });
    }
}

- (void)doImageOptimWithPath:(NSString *)path
{
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    NSWorkspace * ws = [NSWorkspace sharedWorkspace];
    [ws openFile:[fileURL path] withApplication:@"ImageOptim"];
}

- (void)imageOptimInWorkspace
{
    [self doImageOptimWithPath:[RSWorkspaceController currentWorkspaceDirectoryPath]];
}

- (void)notificationListener:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"PBXBuildFileWasAddedToBuildPhaseNotification"]) {
        NSString *description = [[[notification userInfo] objectForKey:@"PBXBuildFile"] description];
        description = [description stringByReplacingOccurrencesOfString:@"<" withString:@""];
        description = [description stringByReplacingOccurrencesOfString:@">" withString:@""];
        NSArray *components = [description componentsSeparatedByString:@":"];
        NSString *fileName = [components lastObject];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            sleep(2);
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *filePath = [RSWorkspaceController pathForFileNameInCurrentWorkspace:fileName];
                if (filePath) {
                    [self doImageOptimWithPath:filePath];
                }
            });
        });
    } else if ([[notification name] isEqualToString:@"DVTModelObjectGraphObjectsDidChangeNotificationName"]) {
        NSDictionary *userInfo = [notification userInfo];
        NSString *filePath = nil;
        NSSet *insertedObjects = [userInfo objectForKey:@"DVTModelObjectGraphInsertedObjectsKeyName"];
        for (id insertedObject in insertedObjects.allObjects) {
            if ([insertedObject isKindOfClass:NSClassFromString(@"IDESourceControlWorkingTreeGroup")]) {
                IDESourceControlWorkingTreeGroup *group = insertedObject;
                NSString *pathString = group.filePath.pathString;
                if ([[pathString pathExtension] isEqualToString:@"imageset"]) {
                    filePath = pathString;
                    break;
                }
            }
        }
        if (!filePath) {
            NSSet *updatedObjects = [userInfo objectForKey:@"DVTModelObjectGraphUpdatedObjectsKeyName"];
            for (id updatedObject in updatedObjects.allObjects) {
                if ([updatedObject isKindOfClass:NSClassFromString(@"IDESourceControlWorkingTreeGroup")]) {
                    IDESourceControlWorkingTreeGroup *group = updatedObject;
                    NSString *pathString = group.filePath.pathString;
                    if ([[pathString pathExtension] isEqualToString:@"imageset"]) {
                        filePath = pathString;
                        break;
                    }
                }
            }
        }
        if (filePath) {
            [self doImageOptimWithPath:filePath];
        }
    }
}

- (void)startListen
{
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:kRSImageOptimPluginAutoKey] boolValue]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(notificationListener:)
                                                     name:@"PBXBuildFileWasAddedToBuildPhaseNotification" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(notificationListener:)
                                                     name:@"DVTModelObjectGraphObjectsDidChangeNotificationName" object:nil];
        
        NSLog(@"%@ %@", kRSImageOptimPlugin, @" start");
    }
}

- (void)stopListen
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PBXBuildFileWasAddedToBuildPhaseNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DVTModelObjectGraphObjectsDidChangeNotificationName" object:nil];
    
    NSLog(@"%@ %@", kRSImageOptimPlugin, @" stop");
}

- (void)switch:(NSMenuItem *)item
{
    BOOL currentState = [[[NSUserDefaults standardUserDefaults] objectForKey:kRSImageOptimPluginAutoKey] boolValue];
    currentState = !currentState;
    
    // Change menu item state
    [item setState:currentState ? NSOnState : NSOffState];
    
    // Save state to user defaults
    [[NSUserDefaults standardUserDefaults] setObject:@(currentState) forKey:kRSImageOptimPluginAutoKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (currentState) {
        [self startListen];
    } else {
        [self stopListen];
    }
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init]) {
        self.bundle = plugin;
        
        NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"File"];
        if (menuItem) {
            [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
            NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"ImageOptim" action:@selector(imageOptimInWorkspace) keyEquivalent:@""];
            [actionMenuItem setTarget:self];
            [[menuItem submenu] addItem:actionMenuItem];
            
            NSMenuItem *autoMenuItem = [[NSMenuItem alloc] initWithTitle:@"Enable Auto ImageOptim" action:@selector(switch:) keyEquivalent:@""];
            [autoMenuItem setState:[[[NSUserDefaults standardUserDefaults] objectForKey:kRSImageOptimPluginAutoKey] boolValue] ? NSOnState : NSOffState];
            [autoMenuItem setTarget:self];
            [[menuItem submenu] addItem:autoMenuItem];
        }
        
        [self startListen];
    }
    return self;
}

- (void)dealloc
{
    [self stopListen];
}

@end
