//
//  PMDirectoryViewController.h
//  SimpleFileManager
//
//  Created by Pavel on 24.01.2018.
//  Copyright © 2018 Pavel Maiboroda. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PMDirectoryViewController : UITableViewController

@property (strong, nonatomic) NSString *path;

- (IBAction) actionAlertSheetMenu: (UIBarButtonItem *) sender;

@end
