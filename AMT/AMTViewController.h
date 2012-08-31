//
//  AMTViewController.h
//  AMT
//
//  Created by Mischa Spiegelmock on 8/31/12.
//  Copyright (c) 2012 int80. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NSDictionary+URLEncoding.h"

typedef void (^basicCallback)(void);

@interface AMTViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UITextField *pinField;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property BOOL isAuthenticated;

- (IBAction)unlock:(id)sender;

@end
