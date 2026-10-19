#import <UIKit/UIKit.h>
#import <objc/runtime.h>
extern "C" void MSHookMessageEx(Class cls, SEL selector, IMP replacement, IMP *original);
#include <math.h>

// Only SpringBoard / volume controller. Never hook UIKit globally.
static Class VolumeClass;
static __thread unsigned ContextDepth;
static const void *WideStateKey = &WideStateKey;
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
    if (state > 0 && IsVolume(self)) {
        NSNumber *wide = objc_getAssociatedObject(self, WideStateKey);
        // Initial presentation is outside button context on iOS 17.2.1.
        // Once learned, unrelated transitions need no size query.
        if (!wide || ContextDepth) {
            CGSize size = VHEStateSize(self, state);
            if (!wide && Wide(size)) {
                wide = @(state);
                objc_setAssociatedObject(self, WideStateKey, wide, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            if (ContextDepth && wide && Narrow(size)) state = wide.integerValue;
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
            return;
        }
        MSHookMessageEx(base, context, (IMP)Context, (IMP *)&OrigContext);
        MSHookMessageEx(base, transition, (IMP)Transition, (IMP *)&OrigTransition);
    }
}
