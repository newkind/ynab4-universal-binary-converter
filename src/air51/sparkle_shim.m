#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

#import "FlashRuntimeExtensions.h"

static FREObject fre_bool(BOOL value) {
    FREObject object = NULL;
    FRENewObjectFromBool(value ? 1U : 0U, &object);
    return object;
}

static FREObject RestartApp(FREContext ctx, void *functionData, uint32_t argc, FREObject argv[]) {
    (void)ctx;
    (void)functionData;
    (void)argc;
    (void)argv;

    NSString *bundlePath = [NSBundle mainBundle].bundlePath;
    if (bundlePath.length > 0) {
        [[NSWorkspace sharedWorkspace] openFile:bundlePath];
    }
    [NSApp terminate:nil];
    return fre_bool(YES);
}

static FREObject NoopTrue(FREContext ctx, void *functionData, uint32_t argc, FREObject argv[]) {
    (void)ctx;
    (void)functionData;
    (void)argc;
    (void)argv;
    return fre_bool(YES);
}

static void SparkleContextFinalizer(FREContext ctx) {
    (void)ctx;
}

static void SparkleContextInitializer(void *extData, const uint8_t *ctxType, FREContext ctx,
                                      uint32_t *numFunctionsToSet, const FRENamedFunction **functionsToSet) {
    (void)extData;
    (void)ctxType;
    (void)ctx;

    static FRENamedFunction functions[] = {
        {(const uint8_t *)"BringSparkleWindowToFront", NULL, &NoopTrue},
        {(const uint8_t *)"CheckForUpdates", NULL, &NoopTrue},
        {(const uint8_t *)"CheckForUpdatesInBackground", NULL, &NoopTrue},
        {(const uint8_t *)"ResetUpdateCycle", NULL, &NoopTrue},
        {(const uint8_t *)"RestartApp", NULL, &RestartApp},
        {(const uint8_t *)"SetFeedURL", NULL, &NoopTrue},
        {(const uint8_t *)"StartSparkleAndCheckForUpdates", NULL, &NoopTrue},
    };

    *numFunctionsToSet = (uint32_t)(sizeof(functions) / sizeof(functions[0]));
    *functionsToSet = functions;
}

void NativeExtensionsInitializer(void **extDataToSet, FREContextInitializer *ctxInitializerToSet,
                                 FREContextFinalizer *ctxFinalizerToSet) {
    *extDataToSet = NULL;
    *ctxInitializerToSet = &SparkleContextInitializer;
    *ctxFinalizerToSet = &SparkleContextFinalizer;
}

void NativeExtensionsFinalizer(void *extData) {
    (void)extData;
}
