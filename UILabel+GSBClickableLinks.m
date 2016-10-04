//
//  UILabel+GSBClickableLinks.m
//  Xiph
//
//  Created by Gareth Bestor on 5/10/16.
//  Copyright © 2016 tiritea. All rights reserved.
//
//  Adapted from http://stackoverflow.com/questions/21349725

#import "UILabel+GSBClickableLinks.h"
#import <objc/runtime.h>

static const void *INDEX;
static const void *TAP;

@implementation UILabel (GSBClickableLinks)

- (void)setEnableLinks:(BOOL)enableLinks
{
    UITapGestureRecognizer *tap = objc_getAssociatedObject(self, &TAP); // retreive tap
    if (enableLinks && !tap) { // add a gestureRegonzier to the UILabel to detect taps
        tap = [UITapGestureRecognizer.alloc initWithTarget:self action:@selector(openLink)];
        tap.delegate = self;
        [self addGestureRecognizer:tap];
        objc_setAssociatedObject(self, &TAP, tap, OBJC_ASSOCIATION_RETAIN_NONATOMIC); // save tap
    }
    self.userInteractionEnabled = enableLinks; // note - when false UILAbel wont receive taps, hence disable links
}

- (BOOL)enableLinks
{
    return (BOOL)objc_getAssociatedObject(self, &TAP); // ie tap != nil
}

// First check whether user tapped on a link within the attributedText of the label.
// If so, then the our label's gestureRecogizer will subsequently fire, and open the corresponding NSLinkAttributeName.
// If not, then the tap will get passed along, eg to the enclosing UITableViewCell...
// Note: save which character in the attributedText was clicked so that we dont have to redo everything again in openLink.
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer != objc_getAssociatedObject(self, &TAP)) return YES; // dont block other gestures (eg swipe)
    
    // Re-layout the attributedText to find out what was tapped
    NSTextContainer *textContainer = [NSTextContainer.alloc initWithSize:self.frame.size];
    textContainer.lineFragmentPadding = 0;
    textContainer.maximumNumberOfLines = self.numberOfLines;
    textContainer.lineBreakMode = self.lineBreakMode;
    NSLayoutManager *layoutManager = NSLayoutManager.new;
    [layoutManager addTextContainer:textContainer];
    NSTextStorage *textStorage = [NSTextStorage.alloc initWithAttributedString:self.attributedText];
    [textStorage addLayoutManager:layoutManager];
    
    NSUInteger index = [layoutManager characterIndexForPoint:[gestureRecognizer locationInView:self]
                                             inTextContainer:textContainer
                    fractionOfDistanceBetweenInsertionPoints:NULL];
    objc_setAssociatedObject(self, &INDEX, @(index), OBJC_ASSOCIATION_RETAIN_NONATOMIC); // save index
    
    return (BOOL)[self.attributedText attribute:NSLinkAttributeName atIndex:index effectiveRange:NULL]; // tapped on part of a link?
}

- (void)openLink
{
    NSUInteger index = [objc_getAssociatedObject(self, &INDEX) unsignedIntegerValue]; // retrieve index
    NSURL *url = [self.attributedText attribute:NSLinkAttributeName atIndex:index effectiveRange:NULL];
    if (url && [UIApplication.sharedApplication canOpenURL:url]) [UIApplication.sharedApplication openURL:url];
}

@end
