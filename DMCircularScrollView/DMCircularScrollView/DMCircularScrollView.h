//
//  DMCircularScrollView.h
//  DMCircularScrollView
//
//  Created by Daniele Margutti on 8/16/12.
//  Copyright (c) 2012 Daniele Margutti. All rights reserved.
//

#import <UIKit/UIKit.h>

// Data Source Handler
typedef UIView *(^DMCircularScrollViewDataSource)(NSUInteger pageIndex);
// Page Change Delegate Handler
typedef void(^DMCircularScrollViewPageChanged)(NSUInteger currentPageIndex,NSUInteger previousPageIndex);

@interface DMCircularScrollView : UIView {
    
}

@property (nonatomic,assign)    CGFloat                             pageWidth;              // Single page width (picker is centered)
@property (nonatomic,assign)    NSUInteger                          currentPageIndex;       // Current page index
                                                                                            //  remember:   DMCircularScrollView uses tag property
                                                                                            //              of UIVIew, so don't touch it.

@property (nonatomic,assign)    BOOL                                allowTapToChangePage;   // Allows single tap on scroll view side to change next/prev
@property (nonatomic,assign)    BOOL                                displayBorder;          // Display a green border around the scrollView
@property (copy)                DMCircularScrollViewPageChanged     handlePageChange;       // Block to catch page change event

@property (nonatomic, assign)   id                                  scrollViewDelegate;     // Delegate for passing through UIScrollView delegate calls

// Use this to setup DMCircularScrollView
- (void) setPageCount:(NSUInteger) pageCount withDataSource:(DMCircularScrollViewDataSource) dataSource;

// Probability you don't need of it never
- (void) reloadData;

@end