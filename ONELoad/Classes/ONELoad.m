//
//  ONELoad.m
//  Pods
//
//  Created by Bradley on 2020/9/15.
//

#import "ONELoad.h"

#import <objc/runtime.h>
#import <dlfcn.h>
#import <mach-o/ldsyms.h>
#include <limits.h>
#include <mach-o/dyld.h>
#include <mach-o/nlist.h>
#include <string.h>

#define TIMESTAMP_NUMBER(interval)  [NSNumber numberWithLongLong:interval*1000*1000]

unsigned int cccount;
const char **classes;

@implementation ONELoad

+ (void)load {

    _loadInfoArray = [[NSMutableArray alloc] init];

    CFAbsoluteTime time1 =CFAbsoluteTimeGetCurrent();

    int imageCount = (int)_dyld_image_count();

    for(int iImg = 0; iImg < imageCount; iImg++) {
        const char* path = _dyld_get_image_name((unsigned)iImg);
        NSString *imagePath = [NSString stringWithUTF8String:path];

        NSBundle* mainBundle = [NSBundle mainBundle];
        NSString* bundlePath = [mainBundle bundlePath];

        if ([imagePath containsString:bundlePath] && ![imagePath containsString:@".dylib"]) {
            classes = objc_copyClassNamesForImage(path, &cccount);

            for (int i = 0; i < cccount; i++) {
                NSString *className = [NSString stringWithCString:classes[i] encoding:NSUTF8StringEncoding];
                if ([className isEqualToString:NSStringFromClass([ONELoad class])]) {
                    continue;
                }
                if (![className isEqualToString:@""] && className) {
                    Class class = object_getClass(NSClassFromString(className));
                    
                    SEL originalSelector = @selector(load);
                    SEL swizzledSelector = @selector(LDAPM_Load);
                    
                    Method originalMethod = class_getClassMethod(class, originalSelector);
                    Method swizzledMethod = class_getClassMethod([ONELoad class], swizzledSelector);;
                    IMP imp = method_getImplementation(swizzledMethod);
                    method_setImplementation(originalMethod, imp);
    
                }
            }
        }
    }

    CFAbsoluteTime time2 =CFAbsoluteTimeGetCurrent();
     NSLog(@"Hook Time:%f",(time2 - time1) * 1000);
}

+ (void)LDAPM_Load {

    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

    CFAbsoluteTime end =CFAbsoluteTimeGetCurrent();
    // 时间精度 us
    NSDictionary *infoDic = @{@"st":TIMESTAMP_NUMBER(start),
                              @"et":TIMESTAMP_NUMBER(end),
                              @"name":NSStringFromClass([self class])
                              };

    [_loadInfoArray addObject:infoDic];
}

@end
