//
//  PMDirectoryViewController.m
//  SimpleFileManager
//
//  Created by Pavel on 24.01.2018.
//  Copyright © 2018 Pavel Maiboroda. All rights reserved.
//

#import "PMDirectoryViewController.h"

@interface PMDirectoryViewController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) NSArray *contents;

@end

@implementation PMDirectoryViewController

- (void) setPath: (NSString *) path {
    
    _path = path;
    
    NSError *error = nil;
    
    self.contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: self.path
                                                                        error: &error];
    
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
    }
    
    [self.tableView reloadData];
    
    self.navigationItem.title = [self.path lastPathComponent];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (!self.path) {
        self.path = @"/Users/pavel/Documents";
    }
    
}

#pragma mark - Private Methods

- (BOOL) isDirectoryAtIndexPath: (NSIndexPath *) indexPath {
    
    NSString *fileName = [self.contents objectAtIndex: indexPath.row];
    NSString *filePath = [self.path stringByAppendingPathComponent: fileName];
    
    BOOL isDirectory = NO;
    [[NSFileManager defaultManager] fileExistsAtPath: filePath isDirectory: &isDirectory];
    
    return isDirectory;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return [self.contents count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *folderIdentifier = @"FolderCell";
    static NSString *fileIdentifier = @"FileCell";
    
    NSString *fileName = [self.contents objectAtIndex: indexPath.row];

    if ([self isDirectoryAtIndexPath: indexPath]) {
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: folderIdentifier];
        cell.textLabel.text = fileName;
        
        return cell;
    } else {
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: fileIdentifier];
        cell.textLabel.text = fileName;
        
        return cell;
    }
    
    return nil;
    
}

@end
