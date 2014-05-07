//
//  MBProgressHUD+Customizations.h
//  Benzinga
//
//  Created by Joseph Constantakis on 8/13/13.
//  Copyright (c) 2013 Benzinga. All rights reserved.
//

#import "MBProgressHUD.h"

@interface MBProgressHUD (Cusomizations)

@property (weak, nonatomic) UIColor *textColor;
@property (weak, nonatomic) UIColor *indicatorBackgroundColor;
@property (nonatomic) CGSize indicatorSize;

- (UIView *)indicator;

@end
