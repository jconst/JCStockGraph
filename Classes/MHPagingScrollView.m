
#import "MHPagingScrollView.h"

@interface MHPage : NSObject

@property (nonatomic, strong) UIView *view;
@property (nonatomic, assign) NSUInteger index;

@end

@implementation MHPage

@end

@implementation MHPagingScrollView
{
	NSMutableSet *_recycledPages;
	NSMutableSet *_visiblePages;
	NSUInteger _firstVisiblePageIndexBeforeRotation;  // for autorotation
	CGFloat _percentScrolledIntoFirstVisiblePage;
}

- (void)commonInit
{
	_recycledPages = [[NSMutableSet alloc] init];
	_visiblePages  = [[NSMutableSet alloc] init];

	self.pagingEnabled = YES;
	self.showsVerticalScrollIndicator = NO;
	self.showsHorizontalScrollIndicator = NO;
	self.contentOffset = CGPointZero;
}

- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame]))
	{
		[self commonInit];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder]))
	{
		[self commonInit];
	}
	return self;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
	// This allows for touch handling outside of the scroll view's bounds.

	CGPoint parentLocation = [self convertPoint:point toView:self.superview];

	CGRect responseRect = self.frame;
	responseRect.origin.x -= _previewInsets.left;
	responseRect.origin.y -= _previewInsets.top;
	responseRect.size.width += (_previewInsets.left + _previewInsets.right);
	responseRect.size.height += (_previewInsets.top + _previewInsets.bottom);

	return CGRectContainsPoint(responseRect, parentLocation);
}

- (void)selectPageAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    [self setContentOffset:CGPointMake(self.bounds.size.width * index, 0) animated:animated];
}

- (NSUInteger)indexOfSelectedPage
{
	CGFloat width = self.bounds.size.width;
	int currentPage = (self.contentOffset.x + width/2.0f) / width;
	return currentPage;
}

- (NSUInteger)numberOfPages
{
	return [_pagingDelegate numberOfPagesInPagingScrollView:self];
}

- (CGSize)contentSizeForPagingScrollView
{
	CGRect rect = self.bounds;
	return CGSizeMake(rect.size.width * [self numberOfPages], rect.size.height);
}

- (BOOL)isDisplayingPageForIndex:(NSUInteger)index
{
	for (MHPage *page in _visiblePages)
	{
		if (page.index == index)
			return YES;
	}
	return NO;
}

- (UIView *)dequeueReusablePage
{
	MHPage *page = [_recycledPages anyObject];
	if (page != nil)
	{
		UIView *view = page.view;
		[_recycledPages removeObject:page];
		return view;
	}
	return nil;
}

- (CGRect)frameForPageAtIndex:(NSUInteger)index
{
	CGRect rect = self.bounds;
	rect.origin.x = rect.size.width * index;
	return rect;
}

- (void)tilePages 
{
	CGRect visibleBounds = self.bounds;
	CGFloat pageWidth = CGRectGetWidth(visibleBounds);
	visibleBounds.origin.x -= _previewInsets.left;
	visibleBounds.size.width += (_previewInsets.left + _previewInsets.right);

	int firstNeededPageIndex = floorf(CGRectGetMinX(visibleBounds) / pageWidth);
	int lastNeededPageIndex = floorf((CGRectGetMaxX(visibleBounds) - 1.0f) / pageWidth);
	firstNeededPageIndex = MAX(firstNeededPageIndex, 0);
	lastNeededPageIndex = MIN(lastNeededPageIndex, (int)[self numberOfPages] - 1);

	for (MHPage *page in _visiblePages)
	{
		if ((int)page.index < firstNeededPageIndex || (int)page.index > lastNeededPageIndex)
		{
			[_recycledPages addObject:page];
			[page.view removeFromSuperview];
		}
	}

	[_visiblePages minusSet:_recycledPages];

	for (int i = firstNeededPageIndex; i <= lastNeededPageIndex; ++i)
	{
		if (![self isDisplayingPageForIndex:i])
		{
			UIView *pageView = [_pagingDelegate pagingScrollView:self pageForIndex:i];
			pageView.frame = [self frameForPageAtIndex:i];
			pageView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
			[self addSubview:pageView];

			MHPage *page = [[MHPage alloc] init];
			page.index = i;
			page.view = pageView;
			[_visiblePages addObject:page];
		}
	}
}

- (void)reloadPages
{
	self.contentSize = [self contentSizeForPagingScrollView];
	[self tilePages];
}

- (void)scrollViewDidScroll
{
	[self tilePages];
}

- (void)beforeRotation
{
	CGFloat offset = self.contentOffset.x;
	CGFloat pageWidth = self.bounds.size.width;

	if (offset >= 0)
		_firstVisiblePageIndexBeforeRotation = floorf(offset / pageWidth);
	else
		_firstVisiblePageIndexBeforeRotation = 0;

	_percentScrolledIntoFirstVisiblePage = offset / pageWidth - _firstVisiblePageIndexBeforeRotation;
}

- (void)afterRotation
{
	self.contentSize = [self contentSizeForPagingScrollView];

	for (MHPage *page in _visiblePages)
		page.view.frame = [self frameForPageAtIndex:page.index];

	CGFloat pageWidth = self.bounds.size.width;
	CGFloat newOffset = (_firstVisiblePageIndexBeforeRotation + _percentScrolledIntoFirstVisiblePage) * pageWidth;
	self.contentOffset = CGPointMake(newOffset, 0);
}

- (void)didReceiveMemoryWarning
{
	[_recycledPages removeAllObjects];
}

@end
