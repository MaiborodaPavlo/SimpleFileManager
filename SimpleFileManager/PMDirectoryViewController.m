//
//  PMDirectoryViewController.m
//  SimpleFileManager
//
//  Created by Pavel on 24.01.2018.
//  Copyright © 2018 Pavel Maiboroda. All rights reserved.
//

#import "PMDirectoryViewController.h"

@interface PMDirectoryViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (strong, nonatomic) NSArray *contents;

@property (strong, nonatomic) NSString *folderName;
@property (strong, nonatomic) NSString *selectedPath;

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
    
    self.navigationItem.title = [self.path lastPathComponent];
    
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (!self.path) {
        self.path = @"/Users/pavel/Documents";
    }
    
    // убираем скрытые файлы
    [self hideHiddenFiles];
    [self sortContent];
    
}

#pragma mark - Private Methods

- (void) sortContent {
    
    NSArray *sortedArray = [self.contents sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        
        if ([self isFile: obj1] && [self isFile: obj2]) {
            return [obj1 compare: obj2];
        } else if ([self isFile: obj1] && ![self isFile: obj2]) {
            return NSOrderedDescending;
        } else {
            return ![obj1 compare: obj2];
        }
    }];
    
    self.contents = [NSMutableArray arrayWithArray:sortedArray];
    
}

- (void) hideHiddenFiles {
    
    NSMutableArray *temp = [NSMutableArray array];
    
    for (NSString *fileName in self.contents) {
        if ([fileName rangeOfString:@"."].location != 0) {
            [temp addObject: fileName];
        }
    }
    self.contents = temp;
    
}

- (BOOL) isDirectoryAtIndexPath: (NSIndexPath *) indexPath {
    
    NSString *fileName = [self.contents objectAtIndex: indexPath.row];
    NSString *filePath = [self.path stringByAppendingPathComponent: fileName];
    
    BOOL isDirectory = NO;
    [[NSFileManager defaultManager] fileExistsAtPath: filePath isDirectory: &isDirectory];
    
    return isDirectory;
}

- (BOOL) isFile: (NSString *) fileName {
    
    BOOL isFile = NO;
    
    NSString *path = [self.path stringByAppendingPathComponent: fileName];
    
    [[NSFileManager defaultManager] fileExistsAtPath: path isDirectory: &isFile];
    
    return !isFile;
}

- (NSString *) fileSizeFromValue: (unsigned long long) value {
    
    static NSString *units[] = {@"B", @"KB", @"MB", @"GB", @"TB"};
    static int unitsCount = 5;
    
    int index = 0;
    
    double fileSize = (double) value;
    
    while (fileSize > 1024 && index < unitsCount) {
        fileSize /= 1024;
        index++;
    }
    
    return [NSString stringWithFormat: @"%.2f %@", fileSize, units[index]];
}

- (unsigned long long)sizeOfFolder:(NSString *)folderPath {
    
    unsigned long long int result = 0;
    
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:nil];
    
    for (NSString *fileSystemItem in array) {
        BOOL directory = NO;
        [[NSFileManager defaultManager] fileExistsAtPath:[folderPath stringByAppendingPathComponent:fileSystemItem] isDirectory:&directory];
        if (!directory) {
            result += [[[[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:fileSystemItem] error:nil] objectForKey:NSFileSize] unsignedIntegerValue];
        }
        else {
            result += [self sizeOfFolder:[folderPath stringByAppendingPathComponent:fileSystemItem]];
        }
    }
    
    return result;
}

#pragma mark - Actions


- (IBAction) actionAlertSheetMenu: (UIBarButtonItem *) sender {
    
    // Alert Sheet
    UIAlertController *alertSheet = [UIAlertController alertControllerWithTitle: nil message: nil preferredStyle: UIAlertControllerStyleActionSheet];
    
    // Back to root button
    if ([self.navigationController.viewControllers count] > 1) {
        
        UIAlertAction *backToRoot = [UIAlertAction actionWithTitle: @"Back to root" style: UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            [self.navigationController popToRootViewControllerAnimated: YES];
        }];
        [alertSheet addAction: backToRoot];
    }
    
    // Create new folder button
    UIAlertAction *createFolder = [UIAlertAction actionWithTitle: @"Create new folder" style: UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle: @"Create new folder" message: @"Enter new folder name" preferredStyle: UIAlertControllerStyleAlert];
        
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"New folder name";
            textField.delegate = self;
        }];
        
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
                             {
                                 if (alert.textFields[0].text) {
                                     
                                     NSString *path = [self.path stringByAppendingPathComponent: alert.textFields[0].text];
                                     [[NSFileManager defaultManager] createDirectoryAtPath: path
                                                               withIntermediateDirectories: YES
                                                                                attributes: nil
                                                                                     error: nil];
                                     
                                     self.contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: self.path
                                                                                                         error: nil];
                                     
                                     [self hideHiddenFiles];
                                     [self sortContent];
                                     
                                     [self.tableView reloadData];
                                 }
                             }];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];

        [alert addAction:cancel];
        [alert addAction:ok];
        
        [self presentViewController: alert animated:YES completion:nil];
    }];
    
    [alertSheet addAction: createFolder];

    // Cancel button
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    
    [alertSheet addAction:cancel];

    [self presentViewController: alertSheet animated:YES completion:nil];
    
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
        
        NSString *path = [self.path stringByAppendingPathComponent: fileName];

        cell.detailTextLabel.text = [self fileSizeFromValue: [self sizeOfFolder: path]];
        
        return cell;
    } else {
        
        NSString *path = [self.path stringByAppendingPathComponent: fileName];
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath: path error: nil];
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: fileIdentifier];
        cell.textLabel.text = fileName;

        cell.detailTextLabel.text = [self fileSizeFromValue: [attributes fileSize]];
        
        return cell;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        NSString *fileName = [self.contents objectAtIndex: indexPath.row];
        NSString *path = [self.path stringByAppendingPathComponent: fileName];
        
        [[NSFileManager defaultManager] removeItemAtPath: path error: nil];
        
        self.contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: self.path
                                                                            error: nil];
        [self hideHiddenFiles];
        [self sortContent];
        
        // Обновление таблицы
        
        [tableView reloadData];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath: indexPath animated: YES];
    
    if ([self isDirectoryAtIndexPath: indexPath]) {
        
        NSString *fileName = [self.contents objectAtIndex: indexPath.row];
        NSString *path = [self.path stringByAppendingPathComponent: fileName];
        
        self.selectedPath = path;
        [self performSegueWithIdentifier: @"navigateDeep" sender: nil];
    }
}

#pragma mark - Segue

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    PMDirectoryViewController *vc = segue.destinationViewController;
    vc.path = self.selectedPath;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSCharacterSet * set = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ0123456789"] invertedSet];
    if ([string rangeOfCharacterFromSet:set].location != NSNotFound) {
        return NO;
    } else {
        return YES;
    }
}

@end
