//
//  UIView+FrameAccessor.m
//  FrameAccessor
//
//  Created by Alex Denisov on 18.03.12.
//  Copyright (c) 2012 CoreInvader. All rights reserved.
//

#import "UIView+FrameAccessor.h"

@implementation UIView (FrameAccessor)

- (CGPoint)origin {
   return self.frame.origin;
}

- (void)setOrigin:(CGPoint)newOrigin {
    CGRect newFrame = self.frame;
    newFrame.origin = newOrigin;
    self.frame      = newFrame;
}

- (CGSize)size {
    return self.frame.size;
}

- (void)setSize:(CGSize)newSize {
    CGRect newFrame = self.frame;
    newFrame.size   = newSize;
    self.frame      = newFrame;
}

- (CGFloat)x {
    return self.frame.origin.x;
}

- (void)setX:(CGFloat)newX {
    CGRect newFrame   = self.frame;
    newFrame.origin.x = newX;
    self.frame        = newFrame;
}

- (CGFloat)y {
    return self.frame.origin.y;
}

- (void)setY:(CGFloat)newY {
    CGRect newFrame   = self.frame;
    newFrame.origin.y = newY;
    self.frame        = newFrame;
}

- (CGFloat)height {
    return self.frame.size.height;
}

- (void)setHeight:(CGFloat)newHeight {
    CGRect newFrame      = self.frame;
    newFrame.size.height = newHeight;
    self.frame           = newFrame;
}

- (CGFloat)width {
    return self.frame.size.width;
}

- (void)setWidth:(CGFloat)newWidth {
    CGRect newFrame     = self.frame;
    newFrame.size.width = newWidth;
    self.frame          = newFrame;
}

- (CGFloat)bottom {
    return self.frame.origin.y + self.frame.size.height;
}
- (void)setBottom:(CGFloat)newBottom
{
    CGRect newFrame   = self.frame;
    newFrame.origin.y = newBottom - self.size.height;
    self.frame        = newFrame;
}
- (CGFloat)right {
    return self.frame.origin.x + self.frame.size.width;
}
- (void)setRight:(CGFloat)newRight
{
    CGRect newFrame   = self.frame;
    newFrame.origin.x = newRight - self.size.width;
    self.frame        = newFrame;
}
@end
