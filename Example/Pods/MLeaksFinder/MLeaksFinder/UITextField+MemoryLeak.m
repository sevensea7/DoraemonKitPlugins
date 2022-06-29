//
//  UITextField+MemoryLeak.m
//  MLeaksFinder
//
//  Created by 七海 on 2022/6/29.
//  Copyright © 2022 zeposhe. All rights reserved.
//

#import "UITextField+MemoryLeak.h"

@implementation UITextField (MemoryLeak)

- (BOOL)willDealloc {
    return NO;
}

@end
