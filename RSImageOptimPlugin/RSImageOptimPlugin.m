//
//  RSImageOptimPlugin.m
//  RSImageOptimPlugin
//
//  Created by R0CKSTAR on 4/9/14.
//  Copyright (c) 2014 P.D.Q. All rights reserved.
//

#import "RSImageOptimPlugin.h"
#import "RSWorkspaceController.h"
#import "IDEFoundation.h"

static RSImageOptimPlugin *sharedPlugin;

@interface RSImageOptimPlugin()

@property (nonatomic, strong) NSBundle *bundle;
@property (nonatomic, strong) NSArray *imageExtensions;
@property (nonatomic, strong) NSArray *excludes;

@end

static NSString *const kRSImageOptimPlugin               = @"com.pdq.rsimageoptimplugin";
static NSString *const kRSImageOptimPluginAutoKey        = @"com.pdq.rsimageoptimplugin.auto";
static NSString *const kRSImageOptimExcludePathExtension = @"conf";
static NSString *const kRSImageOptimExcludeFileName      = @"exclude";

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
        _imageExtensions = @[@"png", @"PNG",
                             @"jpg", @"JPG", @"jpeg", @"JPEG",
                             @"gif", @"GIF"];
    }
    return _imageExtensions;
}

- (NSArray *)excludes
{
    if (!_excludes) {
        NSString *pathString = [RSWorkspaceController currentWorkspaceDirectoryPath];
        if (pathString) {
            NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:pathString];
            NSString *filePathString = nil;
            while ((filePathString = [enumerator nextObject])) {
                if ([kRSImageOptimExcludePathExtension isEqualToString:[[filePathString pathExtension] lowercaseString]]
                    && [[filePathString lowercaseString] rangeOfString:kRSImageOptimExcludeFileName].length > 0) {
                    NSError *error = nil;
                    NSString *contentsOfFile = [NSString stringWithContentsOfFile:filePathString encoding:NSUTF8StringEncoding error:&error];
                    if (!error) {
                        NSArray *list = [contentsOfFile componentsSeparatedByString:@"#"];
                        if (list && [list count] > 0) {
                            _excludes = list;
                        }
                    }
                }
            }
        }
    }
    return _excludes;
}

- (void)doImageOptimWithPathString:(NSString *)pathString
{
    BOOL isExcluded = NO;
    if (self.excludes) {
        for (NSString *exclude in self.excludes) {
            if ([[pathString lowercaseString] rangeOfString:[exclude lowercaseString]].length > 0) {
                isExcluded = YES;
                break;
            }
        }
    }
    if (!isExcluded) {
        NSURL *fileURL = [NSURL fileURLWithPath:pathString];
        NSString *applicationBundlePathString = [self.bundle pathForAuxiliaryExecutable:@"ImageOptim.app"];
        NSString *executablePathString = [NSString stringWithFormat:@"%@%@", applicationBundlePathString, @"/Contents/MacOS/ImageOptim"];
        [NSTask launchedTaskWithLaunchPath:executablePathString arguments:@[[fileURL path]]];
    }
}

- (void)imageOptimInWorkspace
{
    NSString *pathString = [RSWorkspaceController currentWorkspaceDirectoryPath];
    if (pathString) {
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:pathString];
        NSString *filePathString = nil;
        BOOL currentWorkspaceHasImages = NO;
        while ((filePathString = [enumerator nextObject])) {
            if ([self.imageExtensions containsObject:[filePathString pathExtension]]) {
                currentWorkspaceHasImages = YES;
                break;
            }
        }
        if (currentWorkspaceHasImages) {
            [self doImageOptimWithPathString:pathString];
        } else {
            NSAlert *alert = [NSAlert alertWithMessageText:@"No image files in your current workspace." defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
            [alert runModal];
        }
    } else {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Open an Xcode project or workspace first." defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
        [alert runModal];
    }
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
        
        __weak __typeof(self)weakself = self;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"File"];
            if (menuItem) {
                [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
                NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"ImageOptim" action:@selector(imageOptimInWorkspace) keyEquivalent:@""];
                [actionMenuItem setTarget:self];
                [[menuItem submenu] addItem:actionMenuItem];
                
                NSMenuItem *autoMenuItem = [[NSMenuItem alloc] initWithTitle:@"Enable Auto ImageOptim" action:@selector(switch:) keyEquivalent:@""];
                [autoMenuItem setState:[[[NSUserDefaults standardUserDefaults] objectForKey:kRSImageOptimPluginAutoKey] boolValue] ? NSOnState : NSOffState];
                [autoMenuItem setTarget:weakself];
                [[menuItem submenu] addItem:autoMenuItem];
            }
        }];
        
        [self startListen];
    }
    return self;
}

- (void)dealloc
{
    [self stopListen];
}

@end
