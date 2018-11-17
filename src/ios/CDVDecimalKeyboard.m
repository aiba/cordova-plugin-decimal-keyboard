#import <WebKit/WebKit.h>

#import "CDVDecimalKeyboard.h"

@implementation CDVDecimalKeyboard

UIView* keyPlane; // view to which we will add button
CGRect decimalButtonRect;
UIColor* decimalButtonBGColor;
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
    decimalButtonBGColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.0];
}

- (void) appWillResignActive: (NSNotification*) n{
    isAppInBackground = YES;
    [self removeDecimalButton];
}

- (void) appDidBecomeActive: (NSNotification*) n{
    if(isAppInBackground==YES){
        isAppInBackground = NO;
        [self processKeyboardShownEvent];
        
    }
}

- (void) keyboardWillDisappear: (NSNotification*) n {
    [self removeDecimalButton];
}

- (void) setDecimalChar {
    [self evaluateJavaScript:@"DecimalKeyboard.getDecimalChar();"
           completionHandler:^(NSString * _Nullable response, NSError * _Nullable error) {
               if (response) {
                   [decimalButton setTitle:response forState:UIControlStateNormal];
               }
           }];
}

- (void) addDecimalButton {
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        return ; /* Device is iPad and this code works only in iPhone*/
    }
    decimalButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self setDecimalChar];
    [decimalButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    decimalButton.titleLabel.font = [UIFont systemFontOfSize:40.0];
    [decimalButton addTarget:self action:@selector(buttonPressed:)
            forControlEvents:UIControlEventTouchUpInside];
    [decimalButton addTarget:self action:@selector(buttonTapped:)
            forControlEvents:UIControlEventTouchDown];
    [decimalButton addTarget:self action:@selector(buttonPressCancel:)
            forControlEvents:UIControlEventTouchUpOutside];
    
    decimalButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [decimalButton setTitleEdgeInsets:UIEdgeInsetsMake(-20.0f, 0.0f, 0.0f, 0.0f)];
    [decimalButton setBackgroundColor:decimalButtonBGColor];
    
    decimalButton.layer.cornerRadius = 10;
    decimalButton.clipsToBounds = YES;
    
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
        [keyPlane addSubview:decimalButton];
    }
}

- (void) removeDecimalButton{
    [decimalButton removeFromSuperview];
    decimalButton=nil;
}

- (void) keyboardWillAppear: (NSNotification*) n{
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
                [self removeDecimalButton];
            }
        }
    }];
}

- (void)buttonPressed:(UIButton *)button {
    [decimalButton setBackgroundColor: decimalButtonBGColor];
    [self evaluateJavaScript:@"DecimalKeyboard.addDecimal();" completionHandler:nil];
}

- (void)buttonTapped:(UIButton *)button {
    [decimalButton setBackgroundColor:UIColor.whiteColor];
}
- (void)buttonPressCancel:(UIButton *)button{
    [decimalButton setBackgroundColor:decimalButtonBGColor];
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
    for (UIView *subview in [view subviews]) {
        if([[subview description] hasPrefix:@"<UIKBKeyplaneView"] == YES) {
            keyPlane = subview;
            for(UIView *v in subview.subviews) {
                if([[v description] hasPrefix:@"<UIKBKeyView"] == YES) {
                    if (decimalButtonRect.size.width == 0) {
                        decimalButtonRect = v.frame;  // Initialize by copying button frame
                    } else {
                        decimalButtonRect.origin.x = MIN(decimalButtonRect.origin.x, v.frame.origin.x);
                        decimalButtonRect.origin.y = MAX(decimalButtonRect.origin.y, v.frame.origin.y);
                        decimalButtonRect.size.height = MAX(decimalButtonRect.size.height, v.frame.size.height);
                        decimalButtonRect.size.width = MAX(decimalButtonRect.size.width, v.frame.size.width);
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
