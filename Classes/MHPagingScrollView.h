
@class MHPagingScrollView;

/*
 * Delegate protocol for MHPagingScrollView.
 */
@protocol MHPagingScrollViewDelegate <NSObject>

/*
 * Asks the delegate to return the number of pages.
 */
- (NSUInteger)numberOfPagesInPagingScrollView:(MHPagingScrollView *)pagingScrollView;

/*
 * Asks the delegate for a page to insert. The delegate should ask for a
 * reusable view using dequeueReusablePageView.
 */
- (UIView *)pagingScrollView:(MHPagingScrollView *)pagingScrollView pageForIndex:(NSUInteger)index;

@end

/*
 * A paging scroll view that employs a reusable page mechanism like UITableView.
 *
 * MHPagingScrollView allows you to show partial previews of the pages to the
 * left and right of the current page. The bounds of the scroll view always 
 * correspond to a single page. To allow these previews, make the scroll view
 * smaller to make room for the preview pages and set the previewInsets
 * property.
 */
@interface MHPagingScrollView : UIScrollView

/* The delegate for paging events. */
@property (nonatomic, weak) IBOutlet id <MHPagingScrollViewDelegate> pagingDelegate;

/* The width of the preview pages. */
@property (nonatomic, assign) UIEdgeInsets previewInsets;

/*
 * Makes the page at the requested index visible.
 */
- (void)selectPageAtIndex:(NSUInteger)index animated:(BOOL)animated;

/*
 * Returns the index of the page that is currently visible.
 */
- (NSUInteger)indexOfSelectedPage;

/*
 * Returns a reusable UIView object.
 */
- (UIView *)dequeueReusablePage;

/*
 * Reloads the pages. Call this method when the number of pages has changed.
 */
- (void)reloadPages;

/*
 * Call this from your view controller's UIScrollViewDelegate.
 */
- (void)scrollViewDidScroll;

/*
 * Call this from your view controller's willRotateToInterfaceOrientation if
 * you want to support autorotation.
 */
- (void)beforeRotation;

/*
 * Call this from your view controller's willAnimateRotationToInterfaceOrientation
 * if you want to support autorotation.
 */
- (void)afterRotation;

/*
 * Call this from your view controller's didReceiveMemoryWarning.
 */
- (void)didReceiveMemoryWarning;

@end
