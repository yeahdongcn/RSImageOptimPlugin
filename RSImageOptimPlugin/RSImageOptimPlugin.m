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

@property (nonatomic, strong) NSArray *imageExtensions;

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

- (NSArray *)imageExtensions
{
    if (!_imageExtensions) {
        NSMutableArray *extensions = [NSMutableArray array];
        [extensions addObjectsFromArray:@[@"png", @"PNG"]];
        [extensions addObjectsFromArray:@[@"jpg", @"JPG", @"jpeg", @"JPEG"]];
        [extensions addObjectsFromArray:@[@"gif", @"GIF"]];
        _imageExtensions = [NSArray arrayWithArray:extensions];
    }
    return _imageExtensions;
}

- (void)doImageOptimWithPathString:(NSString *)pathString
{
    NSURL *fileURL = [NSURL fileURLWithPath:pathString];
    NSWorkspace * ws = [NSWorkspace sharedWorkspace];
    [ws openFile:[fileURL path] withApplication:@"ImageOptim"];
}

- (void)imageOptimInWorkspace
{
    [self doImageOptimWithPathString:[RSWorkspaceController currentWorkspaceDirectoryPath]];
}

- (BOOL)isPathStringValid:(NSString *)pathString
{
    return (pathString && [self.imageExtensions containsObject:[pathString pathExtension]]);
}

- (NSString *)extractPathString:(NSSet *)objects
{
    for (id object in objects.allObjects) {
        if ([object isKindOfClass:NSClassFromString(@"IDESourceControlWorkingTreeGroup")]) {
            IDESourceControlWorkingTreeGroup *group = object;
            NSString *pathString = group.filePath.pathString;
            if ([self isPathStringValid:pathString]) {
                return pathString;
            }
        } else if ([object isKindOfClass:NSClassFromString(@"IDESourceControlWorkingTreeItem")]) {
            IDESourceControlWorkingTreeItem *item = object;
            NSString *pathString = item.filePath.pathString;
            if ([self isPathStringValid:pathString]) {
                return pathString;
            }
        }
    }
    return nil;
}

- (void)observeNotification:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"DVTModelObjectGraphObjectsDidChangeNotificationName"]) {
        NSDictionary *userInfo = [notification userInfo];
        NSSet *insertedObjects = userInfo[@"DVTModelObjectGraphInsertedObjectsKeyName"];
        NSString *pathString = [self extractPathString:insertedObjects];
        if (!pathString) {
            NSSet *updatedObjects = userInfo[@"DVTModelObjectGraphUpdatedObjectsKeyName"];
            pathString = [self extractPathString:updatedObjects];
        }
        if (pathString) {
            [self doImageOptimWithPathString:pathString];
        }
    }
}

- (void)startListen
{
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:kRSImageOptimPluginAutoKey] boolValue]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(observeNotification:)
                                                     name:@"DVTModelObjectGraphObjectsDidChangeNotificationName" object:nil];
        
        NSLog(@"%@ %@", kRSImageOptimPlugin, @" started <<<<<<");
    }
}

- (void)stopListen
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DVTModelObjectGraphObjectsDidChangeNotificationName" object:nil];
    
    NSLog(@"%@ %@", kRSImageOptimPlugin, @" stopped >>>>>>");
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
