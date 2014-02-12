//
//  ViewController.m
//  OnigiriAlert
//
//  Created by Hiroyuki Onishi on 2/12/14.
//  Copyright (c) 2014 Hiroyuki Onishi. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (weak, nonatomic) IBOutlet UILabel *liveStatusLabel;

@end

@implementation ViewController

#pragma mark - Object Lifecycle

-(void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self updateLiveStatus];
}

-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// #pragma mark - Property Methods
// #pragma mark - [ClassName] Overrides
// #pragma mark - [ProtocolName] Methods
// #pragma mark - Public Interface

#pragma mark - Internal Methods

-(void)updateLiveStatus
{
    [self.activityIndicatorView startAnimating];
    
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.activityIndicatorView stopAnimating];
        self.liveStatusLabel.text = @"live status here";
    });
}

@end
