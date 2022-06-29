//
//  UISearchController+MemoryLeak.m
//  MLeaksFinder
//
//  Created by 七海 on 2022/6/29.
//  Copyright © 2022 zeposhe. All rights reserved.
//

#import "UISearchController+MemoryLeak.h"

@implementation UISearchController (MemoryLeak)

- (BOOL)willDealloc {
    return NO;
}

@end
