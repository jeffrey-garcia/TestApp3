//
//  WebviewController.m
//  TestApp3
//
//  Created by jeffrey on 26/3/15.
//  Copyright (c) 2015 jeffrey. All rights reserved.
//

#import "WebviewController.h"

@interface WebviewController ()

@end

@implementation WebviewController

UIWebView *webView;

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"viewDidDisappear");
    
    // make sure to remove a key-value observer!!
    [self removeJavaScriptObserver];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSLog(@"viewDidLoad");
    
    //Change self.view.bounds to a smaller CGRect if you don't want it to take up the whole screen
    webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    
    //Set the delegate
    webView.delegate = self;
    
    //Set the webview as invisible
    webView.hidden = YES;
    //webView.hidden = NO;
    
    //Set the webview to auto-resize with its parent view
    self.view.autoresizesSubviews = YES;
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    //Add to the UI
    [self.view addSubview:webView];
    
    //Register KVO to JavaScript
    [self createJavaScriptObserver];
}

- (void)viewDidAppear:(BOOL)animated
{
    // get localized path for file from app bundle
    NSString *path;
    NSBundle *mainBundle = [NSBundle mainBundle];
    path = [mainBundle pathForResource:@"test" ofType:@"html"];
    
    // make a file: URL out of the path
    NSURL *theUrl = [NSURL fileURLWithPath:path];
    [webView loadRequest:[NSURLRequest requestWithURL:theUrl]];
    
    // need to do this every time this view appears so that the "home" link keeps working
    //[webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.google.com.hk"]]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    // make sure to remove a key-value observer!!
    [self removeJavaScriptObserver];
}

// webview delegate methods support
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"scheme = %@",[[request URL] scheme]);
    
    // intercept the webview URL
    NSURL *reqURL = [request URL];
    NSString *urlString = [reqURL absoluteString];
    
    NSLog(@"WebView:ShouldStartLoadWithRequest with url: %@", urlString);
    NSLog(@"URL scheme: %@",[reqURL scheme]);
   	NSLog(@"URL host: %@",[reqURL host]);
    NSLog(@"NavigationType: %li",(long)navigationType);
    
    if ([[reqURL scheme] isEqualToString:@"hsbc"]) {
        NSDictionary *functionParserParams = [self getParams:request];
        NSDictionary *functionParams = [NSDictionary dictionaryWithDictionary:functionParserParams];
        
        // aysn notify to process NonHTTPRequest after 1/10 sec.
        [self performSelector:@selector(processNonHTTPRequest:) withObject:functionParams afterDelay:0.1];
        return NO;
    }
    
    return YES;
}

// webview delegate methods support
- (void)webViewDidStartLoad:(UIWebView *)webView
{
    NSLog(@"webviewDidStartLoad");
}

// webview delegate methods support
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"webViewDidFinishLoad");
}

// webview delegate methods support
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"webView didFailLoadWithError");
}

- (NSDictionary *)getParams:(NSURLRequest*)request
{
    
    NSString *urlString = [[request URL] absoluteString];
    urlString = [urlString substringWithRange:NSMakeRange([@"hsbc://" length],[urlString length] - [@"hsbc://" length])];
    urlString = [self urlDecode:urlString];
    NSLog(@"decoded URL String to process: %@", urlString);
    
    NSMutableDictionary *paramDictionary = [self parseUrlString:urlString];
    
    return paramDictionary;
}

- (NSString *)urlDecode:(NSString *)str
{
    NSString *url = (NSString *) CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                                                              (CFStringRef) str,
                                                                                                              CFSTR(""),
                                                                                                              kCFStringEncodingUTF8));
    return url;
}

- (NSMutableDictionary *)parseUrlString:(NSString*)message
{
    NSArray *params = [message componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&="]];
    
    NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];
    for (int i=0; i+1 < [params count]; i = i+2) {
        [mutableDictionary setObject:[[params objectAtIndex:i+1] stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding] forKey:[params objectAtIndex:i]];
    }
    
    return mutableDictionary;
}

- (void)processNonHTTPRequest:(NSDictionary *)functionParams
{
    NSString *functionName = [functionParams valueForKey:@"function"];
    NSLog(@"Hook API called: %@", functionName);
    NSLog(@"Parameters: %@", [functionParams description]);
    
    if ([functionName isEqualToString:@"openInApp"])
    {
        [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.google.com.hk"]]];
        return;
    }
    
    if ([functionName isEqualToString:@"disableBtn"])
    {
        NSString *objectTag = [functionParams objectForKey:@"objectTag"];
        NSLog(@"object Tag: %@", objectTag);
        [self disableBtnByTag: [NSNumber numberWithInteger:objectTag.intValue]];
        return;
    }
}

// IBAction
- (IBAction)btnClicked:(id)sender
{
    NSLog(@"sender: %@", sender);
    
    // Make sure it's a UIButton
    if ([sender isKindOfClass:[UIButton class]]) {
        NSString *title = [(UIButton *)sender currentTitle];
        NSLog(@"title: %@", title);
        long tag = [sender tag];
        NSLog(@"Button Tag is : %ld", tag);
        
        NSString *jsCall = [NSString stringWithFormat: @"btnClickedWithTag(%ld)", tag];
        [webView stringByEvaluatingJavaScriptFromString:jsCall];
    }
}

- (void) disableBtnByTag:(NSNumber *)tag
{
    id sender = [self.view viewWithTag:tag.intValue];
    NSLog(@"sender: %@", sender);
    
    // Make sure it's a UIButton
    if ([sender isKindOfClass:[UIButton class]]) {
        NSLog(@"disabling UI button...");
        
        // cast to UIButton
//        UIButton *theBtn = (UIButton *)[self.view viewWithTag:tag.intValue];
//        theBtn.enabled = NO;
//        theBtn.hidden = YES;
        
        // Does not require direct referecning of UIButton's instance !!
        [sender setValue:[NSNumber numberWithBool:YES] forKey:@"hidden"];
    }
}

//=== Key-Value-Observing ===//
- (void) createJavaScriptObserver
{
    NSLog(@"createJavaScriptObserver");
    
    //id sender = [self.view viewWithTag:1];
    id sender = [self.view viewWithTag:2];
    
    // Register the WebViewController as the observer to be notified for changes, the KeyPath must be KVC-Compliant
    //[sender addObserver:self forKeyPath:@"hidden" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    [sender addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
}

- (void) removeJavaScriptObserver
{
    NSLog(@"removeJavaScriptObserver");
    //id sender = [self.view viewWithTag:1];
    id sender = [self.view viewWithTag:2];
    
    //[sender removeObserver:self forKeyPath:@"hidden"];
    [sender removeObserver:self forKeyPath:@"text"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"observeValueForKeyPath: %@", keyPath);
    // custom implementation
    // be sure to call the superclass' implementation
    // if the superclass implements it
    if ([keyPath isEqualToString: @"hidden"]) {
        long tag = [object tag];
        NSLog(@"Object Tag is : %ld", tag);
        
        NSString *jsCall = [NSString stringWithFormat: @"onTextFieldChanged(%ld)", tag];
        [webView stringByEvaluatingJavaScriptFromString:jsCall];
        
    } else if ([keyPath isEqualToString: @"text"]) {
        long tag = [object tag];
        NSLog(@"Object Tag is : %ld", tag);
        
        NSString *jsCall = [NSString stringWithFormat: @"onTextFieldChanged(%ld)", tag];
        [webView stringByEvaluatingJavaScriptFromString:jsCall];
        
    } else {
        /*
         Be sure to call the superclass's implementation *if it implements it*.
         NSObject does not implement the method.
         */
        [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
    }
}
// === End of Key-Value-Observer ===//

@end

