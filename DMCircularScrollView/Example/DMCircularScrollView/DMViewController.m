//
//  DMViewController.m
//  DMCircularScrollView
//
//  Created by Daniele Margutti on 8/16/12.
//  Copyright (c) 2012 Daniele Margutti. All rights reserved.
//

#import "DMViewController.h"

@interface DMViewController () {    
     NSArray*    threePageScroller_Views;
     NSArray*    longScroller_Views;
}

- (NSMutableArray *) generateSampleUIViews:(NSUInteger) number width:(CGFloat) wd;

- (IBAction)btn_goWeb:(id)sender;

@end

@implementation DMViewController

- (IBAction)btn_goWeb:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.danielemargutti.com"]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Long Scrollview
    longScrollView = [[DMCircularScrollView alloc] initWithFrame:CGRectMake(10, 120, 300, 100)];
    longScroller_Views = [self generateSampleUIViews:15 width:35];
    longScrollView.pageWidth = 35;
    
    [longScrollView setPageCount:[longScroller_Views count]
                           withDataSource:^UIView *(NSUInteger pageIndex) {
                               return [longScroller_Views objectAtIndex:pageIndex];
                           }];
    
    // Short 3-page Scrollview
    threePageScrollView = [[DMCircularScrollView alloc] initWithFrame:CGRectMake(10,270,300,100)];
    threePageScrollView.pageWidth = 100;
    threePageScroller_Views = [self generateSampleUIViews:3 width:100];
    [threePageScrollView setPageCount:[threePageScroller_Views count]
              withDataSource:^UIView *(NSUInteger pageIndex) {
                  return [threePageScroller_Views objectAtIndex:pageIndex];
              }];
    
    // How to handle page events change
    /*scrollView.handlePageChange =  ^(NSUInteger currentPageIndex,NSUInteger previousPageIndex) {
        NSLog(@"PAGE HAS CHANGED. CURRENT PAGE IS %d (prev=%d)",currentPageIndex,previousPageIndex);
     };*/
   
    [self.view addSubview:longScrollView];
    [self.view addSubview:threePageScrollView];
    
}

+ (UIColor *) randomColor
{
	CGFloat red =  (CGFloat)random()/(CGFloat)RAND_MAX;
	CGFloat blue = (CGFloat)random()/(CGFloat)RAND_MAX;
	CGFloat green = (CGFloat)random()/(CGFloat)RAND_MAX;
	return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

- (NSMutableArray *) generateSampleUIViews:(NSUInteger) number width:(CGFloat) wd {
    NSMutableArray *views_list = [[NSMutableArray alloc] init];
    
    for (NSUInteger k = 0; k < 8; k++) {
        UIView *back_view = [[UIView alloc] initWithFrame:CGRectMake(0,0, wd, 100)];
       
        UIButton*btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:[NSString stringWithFormat:@"%d",k] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:40];
        [btn setFrame:back_view.bounds];
        [btn addTarget:self action:@selector(btn_tapButton:) forControlEvents:UIControlEventTouchUpInside];
        [btn setUserInteractionEnabled:YES];
        
        back_view.backgroundColor = [DMViewController randomColor];

        [back_view addSubview:btn];
        [views_list addObject: back_view];
    }
    return views_list;
}

- (void) btn_tapButton:(UIButton *) btn {
    UIAlertView *a = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Tapped page %@!",[btn titleForState:UIControlStateNormal]]
                                                message:@"Good, I really like it! Touch me again!"
                                               delegate:nil
                                      cancelButtonTitle:@"Sure!" otherButtonTitles:nil];
    [a show];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
