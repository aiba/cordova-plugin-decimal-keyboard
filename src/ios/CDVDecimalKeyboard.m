#import <WebKit/WebKit.h>

#import "CDVDecimalKeyboard.h"

@implementation CDVDecimalKeyboard

UIView* ui;
CGRect decimalButtonRect;
UIButton *decimalButton;
BOOL isAppInBackground=NO;

- (void)pluginInitialize {
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(keyboardWillAppear:)
                                                 name: UIKeyboardWillShowNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(keyboardWillDisappear:)
                                                 name: UIKeyboardWillHideNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    
}
- (void) appWillResignActive: (NSNotification*) n{
    isAppInBackground = YES;
    NSLog(@"appWillResignActive");
    [self removeDecimalButton];
}

- (void) appDidBecomeActive: (NSNotification*) n{
    if(isAppInBackground==YES){
        isAppInBackground = NO;
        [self processKeyboardShownEvent];
        
    }
}

- (void) keyboardWillDisappear: (NSNotification*) n{
    NSLog(@"keyboardWillDisappear");
    [self removeDecimalButton];
}

-(void) setDecimalChar {
    [self evaluateJavaScript:@"DecimalKeyboard.getDecimalChar();"
           completionHandler:^(NSString * _Nullable response, NSError * _Nullable error) {
               if (response) {
                   [decimalButton setTitle:response forState:UIControlStateNormal];
               }
           }];
}

- (void) addDecimalButton{
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        return ; /* Device is iPad and this code works only in iPhone*/
    }
    decimalButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self setDecimalChar];
    [decimalButton setTitleColor:[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0] forState:UIControlStateNormal];
    decimalButton.titleLabel.font = [UIFont systemFontOfSize:40.0];
    [decimalButton addTarget:self action:@selector(buttonPressed:)
            forControlEvents:UIControlEventTouchUpInside];
    [decimalButton addTarget:self action:@selector(buttonTapped:)
            forControlEvents:UIControlEventTouchDown];
    [decimalButton addTarget:self action:@selector(buttonPressCancel:)
            forControlEvents:UIControlEventTouchUpOutside];
    
    
    decimalButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [decimalButton setTitleEdgeInsets:UIEdgeInsetsMake(-20.0f, 0.0f, 0.0f, 0.0f)];
    [decimalButton setBackgroundColor: [UIColor colorWithRed:0/255.0 green:0/255.0 blue:218/255.0 alpha:1.0]];
    
    // locate keyboard view
    UIWindow* tempWindow = nil;
    NSArray* openWindows = [[UIApplication sharedApplication] windows];
    
    for(UIWindow* object in openWindows){
        if([[object description] hasPrefix:@"<UIRemoteKeyboardWindow"] == YES){
            tempWindow = object;
        }
    }
    
    if(tempWindow ==nil){
        //for ios 8
        for(UIWindow* object in openWindows){
            if([[object description] hasPrefix:@"<UITextEffectsWindow"] == YES){
                tempWindow = object;
            }
        }
    }
    
    UIView* keyboard;
    for(int i=0; i<[tempWindow.subviews count]; i++) {
        keyboard = [tempWindow.subviews objectAtIndex:i];
        decimalButtonRect = CGRectMake(0.0, 0.0, 0.0, 0.0);
        [self calculateDecimalButtonRect:keyboard];
        NSLog(@"Positioning decimalButton at %@", NSStringFromCGRect(decimalButtonRect));
        decimalButton.frame = decimalButtonRect;
        [ui addSubview:decimalButton];
    }
}
- (void) removeDecimalButton{
    NSLog(@"Removing decimal button");
    [decimalButton removeFromSuperview];
    decimalButton=nil;
}
- (void) deleteDecimalButton{
    NSLog(@"Deleting decimal button");
    [decimalButton removeFromSuperview];
    decimalButton=nil;
}
BOOL isDifferentKeyboardShown=NO;

- (void) keyboardWillAppear: (NSNotification*) n{
    NSLog(@"keyboardWillAppear");
    NSDictionary* info = [n userInfo];
    NSNumber* value = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    double dValue = [value doubleValue];
    
    if (0.0 <= dValue) {
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * dValue);
        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
            [self processKeyboardShownEvent];
        });
    }
}

- (void) processKeyboardShownEvent{
    [self isTextAndDecimal:^(BOOL isDecimalKeyRequired) {
        // create custom button
        if(decimalButton == nil){
            if(isDecimalKeyRequired){
                [self addDecimalButton];
            }
        }else{
            if(isDecimalKeyRequired){
                decimalButton.hidden=NO;
                [self setDecimalChar];
            }else{
                NSLog(@"isDecimalKeyRequired false");
                [self removeDecimalButton];
            }
        }
    }];
}

- (void)buttonPressed:(UIButton *)button {
    [decimalButton setBackgroundColor: [UIColor colorWithRed:210/255.0 green:213/255.0 blue:218/255.0 alpha:1.0]];
    [self evaluateJavaScript:@"DecimalKeyboard.addDecimal();" completionHandler:nil];
}

- (void)buttonTapped:(UIButton *)button {
    [decimalButton setBackgroundColor: [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0]];
}
- (void)buttonPressCancel:(UIButton *)button{
    [decimalButton setBackgroundColor: [UIColor colorWithRed:210/255.0 green:213/255.0 blue:218/255.0 alpha:1.0]];
}

- (void) isTextAndDecimal:(void (^)(BOOL isTextAndDecimal))completionHandler {
    [self evaluateJavaScript:@"DecimalKeyboard.getActiveElementType();"
           completionHandler:^(NSString * _Nullable response, NSError * _Nullable error) {
               BOOL isText = [response isEqual:@"text"];
               
               if (isText) {
                   [self evaluateJavaScript:@"DecimalKeyboard.isDecimal();"
                          completionHandler:^(NSString * _Nullable response, NSError * _Nullable error) {
                              BOOL isDecimal = [response isEqual:@"true"] || [response isEqual:@"1"];
                              BOOL isTextAndDecimal = isText && isDecimal;
                              completionHandler(isTextAndDecimal);
                          }];
               } else {
                   completionHandler(NO);
               }
           }];
}

- (void)calculateDecimalButtonRect:(UIView *)view {
    
    // Get the subviews of the view
    NSArray *subviews = [view subviews];
    
    // Return if there are no subviews
    if ([subviews count] == 0) return; // COUNT CHECK LINE
    
    for (UIView *subview in subviews) {
        if([[subview description] hasPrefix:@"<UIKBKeyplaneView"] == YES) {
            ui = subview;
            for(UIView *nView in ui.subviews) {
                if([[nView description] hasPrefix:@"<UIKBKeyView"] == YES) {
                    //all keys of same size;
                    if (decimalButtonRect.size.width == 0) {
                        // Initialize by copying button frame
                        decimalButtonRect = nView.frame;
                    } else {
                        decimalButtonRect.origin.x = MIN(decimalButtonRect.origin.x, nView.frame.origin.x);
                        decimalButtonRect.origin.y = MAX(decimalButtonRect.origin.y, nView.frame.origin.y);
                        decimalButtonRect.size.height = MAX(decimalButtonRect.size.height, nView.frame.size.height);
                        decimalButtonRect.size.width = MAX(decimalButtonRect.size.width, nView.frame.size.width);
                    }
                }
            }
        }
        [self calculateDecimalButtonRect:subview];
    }
}

- (void) evaluateJavaScript:(NSString *)script
          completionHandler:(void (^ _Nullable)(NSString * _Nullable response, NSError * _Nullable error))completionHandler {
    
    if ([self.webView isKindOfClass:UIWebView.class]) {
        UIWebView *webview = (UIWebView*)self.webView;
        NSString *response = [webview stringByEvaluatingJavaScriptFromString:script];
        if (completionHandler) completionHandler(response, nil);
    }
    
    else if ([self.webView isKindOfClass:WKWebView.class]) {
        WKWebView *webview = (WKWebView*)self.webView;
        [webview evaluateJavaScript:script completionHandler:^(id result, NSError *error) {
            if (completionHandler) {
                if (error) completionHandler(nil, error);
                else completionHandler([NSString stringWithFormat:@"%@", result], nil);
            }
        }];
    }
    
}

@end

