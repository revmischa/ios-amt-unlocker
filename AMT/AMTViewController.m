//
//  AMTViewController.m
//  AMT
//
//  Created by Mischa Spiegelmock on 8/31/12.
//  Copyright (c) 2012 int80. All rights reserved.
//

#import "AMTViewController.h"

@implementation AMTViewController
@synthesize pinField;
@synthesize passwordField, statusLabel, usernameField, isAuthenticated;

- (void)viewDidLoad {
    [super viewDidLoad];
	
    // load saved prefs
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSString *savedUsername = [prefs stringForKey:@"username"];
    if (savedUsername)
        usernameField.text = savedUsername;
    NSString *savedPassword = [prefs stringForKey:@"password"];
    if (savedPassword)
        passwordField.text = savedPassword;
    NSString *savedPIN = [prefs stringForKey:@"doorPIN"];
    if (savedPIN)
        pinField.text = savedPIN;
    
    // see if we are already authenticated
    isAuthenticated = NO;
    if (savedUsername && savedUsername.length && savedPassword && savedPassword.length) {
        [self authenticate:^{
            [self setStatus:@"You are authenticated."];
        }];
    }
}

- (void)viewDidUnload {
    [self setUsernameField:nil];
    [self setPasswordField:nil];
    [self setStatusLabel:nil];
    [self setPinField:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)setStatus:(NSString *)msg {
    statusLabel.text = msg;
}

- (IBAction)unlock:(id)sender {
    // go away keyboard
    [usernameField resignFirstResponder];
    [passwordField resignFirstResponder];
    
    // save username and password
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    [prefs setObject:usernameField.text forKey:@"username"];
    [prefs setObject:passwordField.text forKey:@"password"];
    [prefs setObject:pinField.text forKey:@"doorPIN"];
    [prefs synchronize];
    
    if (isAuthenticated) {
        [self _unlock];
    } else {
        [self authenticate:^{
            [self _unlock];
        }];
    }
}

- (void)authenticate:(basicCallback)successCallback {
    // get l/p
    NSString *username = usernameField.text;
    NSString *password = passwordField.text;
    if (! username.length && ! password.length) {
        [self setStatus:@"Missing username or password"];
        return;
    }
    
    [self setStatus:@"Authenticating..."];
    
    // start request
    NSURL *drupalLoginURL = [NSURL URLWithString:@"http://acemonstertoys.org/node?destination=node"];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            username, @"name",
                            password, @"pass",
                            @"Log in", @"op",
                            @"http://acemonstertoys.org/openid/authenticate?destination=node", @"openid.return_to",
                            @"user_login_block", @"form_id",
                            @"form-4d6478bc67a79eda5e36c01499ba4c88", @"form_build_id",
                            nil];
    
    // build request
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:drupalLoginURL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:20.0];
    req.HTTPMethod = @"POST";
    req.HTTPBody = [[params urlEncodedString] dataUsingEncoding:NSUTF8StringEncoding];
    
    // send request
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *res, NSData *data, NSError *err) {
        // got response
        // check for session cookie
        NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:drupalLoginURL];
        for (NSHTTPCookie *cookie in cookies) {
//            NSLog(@"cookie: %@", cookie);
            if ([cookie.name isEqualToString:@"DRUPAL_UID"]) {
                NSLog(@"found drupal UID: %@", cookie.value);
                isAuthenticated = YES;
                if (successCallback)
                    successCallback();
                return;
            }
        }
        
        // failed to find cookie
        isAuthenticated = NO;
        [self setStatus:@"Authentication failed."];
    }];
}

// send request to unlock door
- (void)_unlock {
    // get door PIN
    NSString *doorPIN = pinField.text;
    if (! doorPIN.length) {
        [self setStatus:@"Door PIN needed."];
        return;
    }
    
    [self setStatus:@"Unlocking door..."];
    NSURL *unlockURL = [NSURL URLWithString:@"http://acemonstertoys.org/membership"];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            doorPIN, @"doorcode",
                            @"Open Door", @"forceit",
                            nil];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:unlockURL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:20.0];
    req.HTTPMethod = @"POST";
    req.HTTPBody = [[params urlEncodedString] dataUsingEncoding:NSUTF8StringEncoding];
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *res, NSData *data, NSError *err) {
        
        NSString *responseString = [NSString stringWithUTF8String:[data bytes]];
        NSLog(@"%@", responseString);
        [self setStatus:@"PIN sent."];
    }];
}

// handle form fields
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == usernameField) {
        // go to password field
        [passwordField becomeFirstResponder];
    } else if (textField == passwordField) {
        if (pinField.text.length == 0)
            [pinField becomeFirstResponder];
        else
            [self unlock:textField];
    } else if (textField == pinField) {
        [self unlock:textField];
    }
    
    return YES;
}

@end
