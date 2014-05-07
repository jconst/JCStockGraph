//
//  MBProgressHUD+Customizations.m
//  Benzinga
//
//  Created by Joseph Constantakis on 8/13/13.
//  Copyright (c) 2013 Benzinga. All rights reserved.
//

#import "MBProgressHUD+Customizations.h"
#import "UIView+FrameAccessor.h"

@implementation MBProgressHUD (Customizations)

- (void)setTextColor:(UIColor *)textColor
{
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[UILabel class]])
            ((UILabel *) subview).textColor = textColor;
    }
}

- (UIColor *)textColor
{
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[UILabel class]])
            return ((UILabel *) subview).textColor;
    }
    return [UIColor whiteColor];
}

- (void)setIndicatorBackgroundColor:(UIColor *)indicatorBackgroundColor
{
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[MBRoundProgressView class]])
            ((MBRoundProgressView *) subview).backgroundTintColor = indicatorBackgroundColor;
    }
}

- (UIColor *)indicatorBackgroundColor
{
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[MBRoundProgressView class]])
            return ((MBRoundProgressView *) subview).backgroundTintColor;
    }
    return [UIColor whiteColor];
}

- (void)setIndicatorSize:(CGSize)indicatorSize
{
    UIView *indicator = [self performSelector:@selector(indicator)];
    if (indicator) {
        indicator.size = indicatorSize;
    }
}

- (CGSize)indicatorSize
{
    UIView *indicator = [self performSelector:@selector(indicator)];
    if (indicator) {
        return indicator.size;
    }
    return CGSizeZero;
}

@end
