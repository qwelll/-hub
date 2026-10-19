#import <UIKit/UIKit.h>
#import <objc/runtime.h>
extern "C" void MSHookMessageEx(Class cls, SEL selector, IMP replacement, IMP *original);
#include <stdio.h>
#include <stdarg.h>
#include <math.h>

// Only SpringBoard / volume controller. Never hook UIKit globally.
static Class VolumeClass;
static __thread unsigned ContextDepth;
static const void *WideStateKey = &WideStateKey;
static void Log(NSString *format, ...) {
    va_list ap; va_start(ap, format);
    NSString *text = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end(ap);
    FILE *f = fopen("/var/mobile/Library/Accessibility/volumehudexpanded.log", "a");
    if (f) { fprintf(f, "%s %s\n", NSDate.date.description.UTF8String, text.UTF8String); fclose(f); }
}
static BOOL IsVolume(id obj) { return VolumeClass && [obj isKindOfClass:VolumeClass]; }
static CGSize VHEStateSize(id obj, NSInteger state) {
    SEL sel = NSSelectorFromString(@"sizeForState:");
    return ((CGSize (*)(id, SEL, NSInteger))[obj methodForSelector:sel])(obj, sel, state);
}
static BOOL Wide(CGSize s) {
    CGFloat w = MIN(s.width, s.height), h = MAX(s.width, s.height);
    return isfinite(w) && isfinite(h) && w >= 25 && h >= 60;
}
static BOOL Narrow(CGSize s) {
    CGFloat w = MIN(s.width, s.height), h = MAX(s.width, s.height);
    return isfinite(w) && isfinite(h) && w > 0 && w <= 20 && h >= 60;
}
static void (*OrigContext)(id, SEL);
static void Context(id self, SEL cmd) {
    if (!IsVolume(self)) { OrigContext(self, cmd); return; }
    ++ContextDepth;
    @try { OrigContext(self, cmd); }
    @finally { --ContextDepth; }
}
static void (*OrigTransition)(id, SEL, NSInteger, BOOL, id);
static void Transition(id self, SEL cmd, NSInteger state, BOOL animated, id completion) {
    if (IsVolume(self)) {
        CGSize size = VHEStateSize(self, state);
        NSNumber *wide = objc_getAssociatedObject(self, WideStateKey);
        // The initial expanded presentation happens OUTSIDE button context on 17.2.1.
        // Learn it on presentation, before contextual button updates arrive.
        if (!wide && state > 0 && Wide(size)) {
            wide = @(state);
            objc_setAssociatedObject(self, WideStateKey, wide, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            Log(@"learn expanded state=%ld size=%@", (long)state, NSStringFromCGSize(size));
        }
        if (ContextDepth && state > 0 && wide && Narrow(size)) {
            Log(@"block compact state=%ld size=%@ -> expanded=%@", (long)state, NSStringFromCGSize(size), wide);
            state = wide.integerValue;
        } else {
            Log(@"transition state=%ld size=%@ buttonContext=%u", (long)state, NSStringFromCGSize(size), ContextDepth);
        }
    }
    // Keep system completion callbacks and timers intact, including dismissal.
    OrigTransition(self, cmd, state, animated, completion);
}
__attribute__((constructor)) static void Start(void) {
    @autoreleasepool {
        if (![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.springboard"]) return;
        VolumeClass = NSClassFromString(@"SBElasticVolumeViewController");
        Class base = NSClassFromString(@"SBElasticValueViewController");
        SEL context = NSSelectorFromString(@"transitionStateContextuallyForValueChangeEvent");
        SEL transition = NSSelectorFromString(@"transitionToState:animated:completion:");
        if (!VolumeClass || !base || !class_getInstanceMethod(base, context) ||
            !class_getInstanceMethod(base, transition) || !class_getInstanceMethod(base, NSSelectorFromString(@"sizeForState:"))) {
            Log(@"v0.1.1 unsupported runtime; NO hooks installed"); return;
        }
        MSHookMessageEx(base, context, (IMP)Context, (IMP *)&OrigContext);
        MSHookMessageEx(base, transition, (IMP)Transition, (IMP *)&OrigTransition);
        Log(@"v0.1.1 installed on %@", NSProcessInfo.processInfo.operatingSystemVersionString);
    }
}
