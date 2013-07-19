//
//  DMCircularScrollView.m
//  DMCircularScrollView
//
//  Created by Daniele Margutti on 8/16/12.
//  Copyright (c) 2012 Daniele Margutti. All rights reserved.
//

#import "DMCircularScrollView.h"
#import <QuartzCore/QuartzCore.h>

#pragma mark - DMCircularScrollView

@interface DMCircularScrollView() <UIScrollViewDelegate> {
    UIScrollView*                               scrollView;
    
    // Block Handlers
    DMCircularScrollViewDataSource              dataSource;
    DMCircularScrollViewPageChanged             handlerPageChange;
    
    NSUInteger                                  previousPageIndex;
    NSUInteger                                  currentPageIndex;
    NSUInteger                                  totalPages;
    
    NSMutableArray*                             tempRepresentations;    // temp cached representation of your UIViews (if needed)
    UITapGestureRecognizer *                    singleTapGesture;
}

@property (nonatomic,readonly)  NSUInteger      visiblePageCount;
@property (nonatomic,readonly)  CGSize          pageSize;

- (NSMutableArray *) viewsFromIndex:(NSUInteger) centralIndex preloadOffset:(NSUInteger) offsetLeftRight;
- (NSMutableArray *) circularPageIndexesFrom:(NSInteger) currentIndex byAddingOffset:(NSInteger) offset;
- (void) relayoutPageItems:(NSUInteger) forceSetPage;

@end

@implementation DMCircularScrollView

@synthesize pageSize,pageWidth;
@synthesize currentPageIndex,visiblePageCount;
@synthesize handlePageChange = handlerPageChange;
@synthesize allowTapToChangePage;

#pragma  mark - Initialization Routines

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        tempRepresentations = [[NSMutableArray alloc] init];
        previousPageIndex = 0;
        
        self.clipsToBounds = YES;
        
        scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
        scrollView.pagingEnabled = YES;
        scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        scrollView.clipsToBounds = NO;
        scrollView.showsHorizontalScrollIndicator = NO;
        scrollView.delegate = self;
        
        if (self.displayBorder)
        {
            scrollView.layer.borderColor = [UIColor greenColor].CGColor;
            scrollView.layer.borderWidth = 2;
        }
        
        scrollView.backgroundColor = [UIColor blueColor];
        self.backgroundColor = [UIColor cyanColor];
        
        self.pageWidth = 50;
        self.currentPageIndex = 0;
        self.allowTapToChangePage = YES;
        
        [self addSubview:scrollView];
    }
    return self;
}

- (UIView *) viewAtLocation:(CGPoint) touchLocation {
    for (UIView *subView in scrollView.subviews)
        if (CGRectContainsPoint(subView.frame, touchLocation))
            return subView;
    return nil;
}


- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event {
    UIView* child = nil;
    // Allows subviews of the scrollview receiving touches
    if ((child = [super hitTest:point withEvent:event]) == self)
        return scrollView;
    return child;
}


- (void) setAllowTapToChangePage:(BOOL)nallowTapToChangePage {
    allowTapToChangePage = nallowTapToChangePage;
    
    [scrollView removeGestureRecognizer:singleTapGesture];
    if (singleTapGesture == nil) {
        singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGestureCaptured:)];
        singleTapGesture.cancelsTouchesInView = NO;
    }
    if (allowTapToChangePage)   [scrollView addGestureRecognizer:singleTapGesture];
}


#pragma mark - Properties

- (CGSize) pageSize {
    return CGSizeMake(self.pageWidth,self.frame.size.height);
}

- (void) setPageWidth:(CGFloat)ppageWidth {
    if (ppageWidth != pageWidth) {
        pageWidth = ppageWidth;
        [self reloadData];
    }
}

- (void) setPageCount:(NSUInteger)npageCount withDataSource:(DMCircularScrollViewDataSource)ndataSource {
    totalPages = npageCount;
    dataSource = ndataSource;
    [self reloadData];
}

- (void) setCurrentPageIndex:(NSUInteger)ncurrentPageIndex {
    if (ncurrentPageIndex != currentPageIndex && ncurrentPageIndex < totalPages)
        [self relayoutPageItems:ncurrentPageIndex];
}

- (NSUInteger) currentPageIndex {
    CGPoint middlePoint = CGPointMake(scrollView.contentOffset.x+self.pageSize.width/2,
                                      scrollView.contentOffset.y+self.pageSize.height/2);
    UIView *currentPageView = [self viewAtLocation:middlePoint];
    return currentPageView.tag;
}

- (NSUInteger) visiblePageCount {
    return ((self.frame.size.width/self.pageSize.width)-1);
}

#pragma mark - Handle Tap To Change Page

- (void)singleTapGestureCaptured:(UITapGestureRecognizer *)gesture {
    UIView *pickedView = [self viewAtLocation:[gesture locationInView:scrollView]];
    [scrollView setContentOffset:CGPointMake(pickedView.frame.origin.x, 0) animated:YES];
}

#pragma mark - Delegate Helper Methods

- (void) delegateSelector:(SEL)selector toDelegateWithArgument:(id)arg
{
    if (self.scrollViewDelegate && [self.scrollViewDelegate respondsToSelector:selector])
    {
        // Disable the 'leaky performSelector' warning from arc
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.scrollViewDelegate performSelector:selector withObject:arg];
#pragma clang diagnostic pop
    }
}

- (void) delegateSelector:(SEL)selector toDelegateWithArgument:(id)arg andArgument:(id)arg2
{
    if (self.scrollViewDelegate && [self.scrollViewDelegate respondsToSelector:selector])
    {
        // Disable the 'leaky performSelector' warning from arc
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.scrollViewDelegate performSelector:selector withObject:arg withObject:arg2];
#pragma clang diagnostic pop
    }
}

#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)sv {
    [self relayoutPageItems:NSUIntegerMax];
    [self delegateSelector:@selector(scrollViewDidEndScrollingAnimation:) toDelegateWithArgument:sv];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)sv
{
    [self relayoutPageItems:NSUIntegerMax];
    [self delegateSelector:@selector(scrollViewDidEndDecelerating:) toDelegateWithArgument:sv];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)sv willDecelerate:(BOOL)decelerate
{
    if (self.scrollViewDelegate && [self.scrollViewDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)])
    {
        [self.scrollViewDelegate scrollViewDidEndDragging:sv willDecelerate:decelerate];
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)sv withView:(UIView *)view atScale:(float)scale
{
    if (self.scrollViewDelegate && [self.scrollViewDelegate respondsToSelector:@selector(scrollViewDidEndZooming:withView:atScale:)])
    {
        [self.scrollViewDelegate scrollViewDidEndZooming:sv withView:view atScale:scale];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)sv
{
    [self delegateSelector:@selector(scrollViewDidScroll:) toDelegateWithArgument:sv];
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)sv
{
    [self delegateSelector:@selector(scrollViewDidScrollToTop:) toDelegateWithArgument:sv];
}

- (void)scrollViewDidZoom:(UIScrollView *)sv
{
    [self delegateSelector:@selector(scrollViewDidZoom:) toDelegateWithArgument:sv];
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)sv
{
    if (self.scrollViewDelegate && [self.scrollViewDelegate respondsToSelector:@selector(scrollViewShouldScrollToTop:)])
    {
        return [self.scrollViewDelegate scrollViewShouldScrollToTop:sv];
    }
    return YES;
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)sv
{
    [self delegateSelector:@selector(scrollViewWillBeginDecelerating:) toDelegateWithArgument:sv];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)sv
{
    [self delegateSelector:@selector(scrollViewWillBeginDragging:) toDelegateWithArgument:sv];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)sv withView:(UIView *)view
{
    [self delegateSelector:@selector(scrollViewWillBeginZooming:withView:) toDelegateWithArgument:sv andArgument:view];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)sv withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if (self.scrollViewDelegate && [self.scrollViewDelegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)])
    {
        [self.scrollViewDelegate scrollViewWillEndDragging:sv withVelocity:velocity targetContentOffset:targetContentOffset];
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)sv
{
    if (self.scrollViewDelegate && [self.scrollViewDelegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)])
    {
        return [self.scrollViewDelegate viewForZoomingInScrollView:sv];
    }
    return nil;
}

#pragma mark - Layout Managment

- (void) layoutSubviews {
    [super layoutSubviews];
    scrollView.frame = CGRectMake(((self.frame.size.width-self.pageSize.width)/2.0f),
                                  0,
                                  self.pageSize.width,
                                  self.frame.size.height);
}

- (void) reloadData {
    NSUInteger visiblePages = ceilf(self.frame.size.width/self.pageSize.width);

    // We need to check to see if self.frame.size.width is evenly divisible
    // by the pageSize width. If true then we want one more visible
    // page. 
    if (fmodf(self.frame.size.width, self.pageSize.width) == 0)
    {
        visiblePages += 1;
    }

    [scrollView setContentSize:CGSizeMake(self.pageSize.width*visiblePages, scrollView.frame.size.height)];
    
    if (dataSource != nil) {
        [scrollView setContentOffset:CGPointMake(self.pageSize.width, 0.0f)];
        [self relayoutPageItems:NSUIntegerMax];
    }
}

#pragma mark - Internal Use

- (NSMutableArray *) circularPageIndexesFrom:(NSInteger) currentIndex byAddingOffset:(NSInteger) offset {
    NSMutableArray *indexValues = [[NSMutableArray alloc] init];
    NSInteger remainingOffset = abs(offset);
    NSInteger value = currentIndex;
    NSInteger singleStepOffset =(offset < 0 ? -1 : 1);
    
    while (remainingOffset > 0) {
        for (NSUInteger k = 0; k < abs(offset); ++k) {
            if ((value + singleStepOffset) < 0)                 value = (totalPages-1);
            else if ((value + singleStepOffset) >= totalPages)  value = 0;
            else                                                value += singleStepOffset;
            
            remainingOffset -= 1;
            
            if (offset < 0) [indexValues insertObject:[NSNumber numberWithInt:value] atIndex:0];
            else            [indexValues addObject:[NSNumber numberWithInt:value]];
        }
    }
    return indexValues;
}

- (NSMutableArray *) viewsFromIndex:(NSUInteger) centralIndex preloadOffset:(NSUInteger) offsetLeftRight {
    NSMutableArray *viewsList = [[NSMutableArray alloc] initWithCapacity:(offsetLeftRight*2)+1];
    NSMutableArray *indexesList = [self circularPageIndexesFrom:centralIndex byAddingOffset:-offsetLeftRight];
    [indexesList addObject:[NSNumber numberWithInt:centralIndex]];
    [indexesList addObjectsFromArray:[self circularPageIndexesFrom:centralIndex byAddingOffset:offsetLeftRight]];
    
    [indexesList enumerateObjectsUsingBlock:^(NSNumber* viewIndex, NSUInteger idx, BOOL *stop) {
        NSUInteger indexOfView = [viewIndex intValue];
        
        UIView *targetView = dataSource(indexOfView);
        targetView.tag = indexOfView;
        if (([viewsList containsObject:targetView] == NO && indexOfView != centralIndex) ||
            (centralIndex == indexOfView && idx == offsetLeftRight))
            [viewsList addObject:targetView];
        else {
            UIImageView *tempDuplicateRepr = [[UIImageView alloc] initWithImage:[self imageWithView:targetView]];
            [tempRepresentations addObject:tempDuplicateRepr];
            tempDuplicateRepr.tag = indexOfView;
            [viewsList addObject:tempDuplicateRepr];
        }
    }];
    
    /*
     ###    Debug purpose only
     */
    /*  NSMutableString *buff = [[NSMutableString alloc] init];
     [viewsList enumerateObjectsUsingBlock:^(UIView* obj, NSUInteger idx, BOOL *stop) {
     [buff appendFormat:@"%d%@,",obj.tag,([obj isKindOfClass:[UIImageView class]] ? @"*":@"")];
     }];
     NSLog(@"%@",buff);
     */
    return viewsList;
}

- (void) relayoutPageItems:(NSUInteger) forceSetPage {
    NSUInteger pageToSet = (forceSetPage != NSUIntegerMax ? forceSetPage : self.currentPageIndex);
    
    currentPageIndex = pageToSet;
    
    [tempRepresentations makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [tempRepresentations removeAllObjects];
    
    if (handlerPageChange != nil)
        handlerPageChange(currentPageIndex,previousPageIndex);
    
    NSUInteger visiblePagesPerSide = ceilf(floor(self.frame.size.width/self.pageSize.width)/2.0f);
    NSUInteger pagesToCachePerSide = visiblePagesPerSide*2;
    
    NSArray *viewsToLoad = [self viewsFromIndex:pageToSet preloadOffset:pagesToCachePerSide];//(visiblePagesPerSide+1)];
    
    [scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    CGFloat offset_x = -((self.pageSize.width*pagesToCachePerSide)-self.pageSize.width);
    //NSLog(@"pages per side: %d. cache on left/right = %d",visiblePagesPerSide,pagesToCachePerSide);
    //NSLog(@"start at = -(%0.fx%d) = %0.f",self.pageSize.width,pagesToCachePerSide,offset_x);
    
    for (UIView *targetView in viewsToLoad) {
        targetView.frame = CGRectMake(offset_x, 0, self.pageSize.width, self.pageSize.height);
        [scrollView addSubview:targetView];
        //  NSLog(@"   [%d] = x,y={%0.f,%0.f} \t\tw,h={%0.f,%0.f}",targetView.tag,targetView.frame.origin.x,targetView.frame.origin.y,targetView.frame.size.width,targetView.frame.size.height);
        offset_x+=self.pageSize.width;
    }
    [scrollView setContentOffset:CGPointMake(self.pageSize.width, 0.0f)];
    
    previousPageIndex = self.currentPageIndex;
}

- (UIImage *) imageWithView:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}


@end