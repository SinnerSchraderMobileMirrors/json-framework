//
//  TweetStreamViewController.m
//  TweetStream
//
//  Created by Stig Brautaset on 24/05/2011.
//  Copyright 2011 Stig Brautaset. All rights reserved.
//

#import "TweetStreamViewController.h"
#import <SBJson/SBJson.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>

@interface TweetStreamViewController ()

@property (nonatomic) ACAccountStore *accountStore;

@end

@implementation TweetStreamViewController


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {

    [super viewDidLoad];

    ACAccountStore *accountStore = ACAccountStore.new;
    ACAccountType *at = [accountStore accountTypeWithAccountTypeIdentifier: ACAccountTypeIdentifierTwitter];

    [accountStore requestAccessToAccountsWithType: at options: nil completion: ^(BOOL granted, NSError *error) {

        if (granted) {

            [NSOperationQueue.mainQueue addOperationWithBlock: ^{

                if (accountStore.accounts.count) {

                    self.accountStore = accountStore;

                    username.text = [@"@" stringByAppendingString: [accountStore.accounts[0] username]];
                    goButton.enabled = YES;
                }
            }];
        }
        else { NSLog(@"Error: %@", error.userInfo); }
    }];
}

- (void)viewDidUnload {
    [super viewDidUnload];    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark Actions

- (IBAction)go {

    // Create a parser that returns a tweet at a time
    parser = [[SBJsonChunkParser alloc] initWithBlock:^(id dict) {
        tweet.text = dict[@"text"];
    } errorHandler:^(NSError *e) {
        tweet.text = [NSString stringWithFormat: @"The parser encountered an error: [%@]", [e localizedDescription]];
    }];

    // Normally it's an error if JSON is followed by anything but
    // whitespace. Setting this means that the parser will be
    // expecting the stream to contain multiple whitespace-separated
    // JSON documents.
    parser.supportManyDocuments = YES;

    NSURL *url = [NSURL URLWithString: @"https://stream.twitter.com/1.1/statuses/sample.json"];
    SLRequest *request = [SLRequest requestForServiceType: SLServiceTypeTwitter
                                            requestMethod: SLRequestMethodGET
                                                      URL: url
                                               parameters: nil];
    request.account = self.accountStore.accounts[0];

    theConnection = [[NSURLConnection alloc] initWithRequest: [request preparedURLRequest]
                                                    delegate: self];
}

#pragma mark NSURLConnectionDelegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	NSLog(@"Connection didReceiveResponse: %@ - %@", response, [response MIMEType]);
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	NSLog(@"Connection didReceiveAuthenticationChallenge: %@", challenge);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	NSLog(@"Connection didReceiveData of length: %u", data.length);
	
	// Parse the new chunk of data. The parser will append it to
	// its internal buffer, then parse from where it left off in
	// the last chunk.
	SBJsonParserStatus status = [parser parse:data];
	
	if (status == SBJsonParserError) {
        @throw @"BAIL";
        
	} else if (status == SBJsonParserWaitingForData) {
		NSLog(@"Parser waiting for more data");
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
}


@end
