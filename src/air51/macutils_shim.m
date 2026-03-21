#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <unistd.h>

#import "FlashRuntimeExtensions.h"

static NSString *fre_string_arg(FREObject object) {
    if (object == NULL) {
        return nil;
    }

    const uint8_t *value = NULL;
    uint32_t length = 0;
    if (FREGetObjectAsUTF8(object, &length, &value) != 0 || value == NULL) {
        return nil;
    }

    return [[NSString alloc] initWithBytes:value length:length encoding:NSUTF8StringEncoding];
}

static NSArray<NSString *> *fre_string_array_arg(FREObject object) {
    uint32_t length = 0;
    if (object == NULL || FREGetArrayLength(object, &length) != 0) {
        return @[];
    }

    NSMutableArray<NSString *> *values = [NSMutableArray arrayWithCapacity:length];
    for (uint32_t i = 0; i < length; i++) {
        FREObject element = NULL;
        if (FREGetArrayElementAt(object, i, &element) != 0) {
            continue;
        }

        NSString *value = fre_string_arg(element);
        if (value.length > 0) {
            [values addObject:value];
        }
    }

    return values;
}

static FREObject fre_bool(BOOL value) {
    FREObject object = NULL;
    FRENewObjectFromBool(value ? 1U : 0U, &object);
    return object;
}

static FREObject fre_string(NSString *value) {
    if (value == nil) {
        value = @"";
    }

    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    FREObject object = NULL;
    FRENewObjectFromUTF8((uint32_t)data.length, data.bytes, &object);
    return object;
}

static FREObject fre_string_array(NSArray<NSString *> *values) {
    FREObject array = NULL;
    FRENewObject((const uint8_t *)"Array", 0, NULL, &array, NULL);
    FRESetArrayLength(array, (uint32_t)values.count);

    for (uint32_t i = 0; i < values.count; i++) {
        FRESetArrayElementAt(array, i, fre_string(values[i]));
    }

    return array;
}

static BOOL is_writable_path(NSString *path) {
    if (path.length == 0) {
        return NO;
    }

    NSString *standardized = path.stringByStandardizingPath;
    const char *fsPath = standardized.fileSystemRepresentation;
    if (access(fsPath, W_OK) == 0) {
        return YES;
    }

    NSString *parent = standardized.stringByDeletingLastPathComponent;
    if (parent.length == 0 || [parent isEqualToString:standardized]) {
        return NO;
    }

    return access(parent.fileSystemRepresentation, W_OK) == 0;
}

static void dispatch_status(FREContext ctx, NSString *code, NSString *level) {
    const uint8_t *codeBytes = (const uint8_t *)code.UTF8String;
    const uint8_t *levelBytes = (const uint8_t *)(level ?: @"").UTF8String;
    FREDispatchStatusEventAsync(ctx, codeBytes, levelBytes);
}

static FREObject IsSandboxed(FREContext ctx, void *functionData, uint32_t argc, FREObject argv[]) {
    (void)ctx;
    (void)functionData;
    (void)argc;
    (void)argv;
    return fre_bool(NO);
}

static FREObject IsPathWriteable(FREContext ctx, void *functionData, uint32_t argc, FREObject argv[]) {
    (void)ctx;
    (void)functionData;
    NSString *path = argc > 0 ? fre_string_arg(argv[0]) : nil;
    return fre_bool(is_writable_path(path));
}

static FREObject ListFilenamesInDirectory(FREContext ctx, void *functionData, uint32_t argc, FREObject argv[]) {
    (void)ctx;
    (void)functionData;
    NSString *path = argc > 0 ? fre_string_arg(argv[0]) : nil;
    if (path.length == 0) {
        return fre_string_array(@[]);
    }

    NSError *error = nil;
    NSArray<NSString *> *entries = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    if (entries == nil || error != nil) {
        return fre_string_array(@[]);
    }

    return fre_string_array(entries);
}

static FREObject BrowseForFileOpen(FREContext ctx, void *functionData, uint32_t argc, FREObject argv[]) {
    (void)functionData;

    NSArray<NSString *> *allowedTypes = argc > 0 ? fre_string_array_arg(argv[0]) : @[];
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = NO;
    panel.canCreateDirectories = NO;
    if (allowedTypes.count > 0) {
        panel.allowedFileTypes = allowedTypes;
    }

    NSInteger result = [panel runModal];
    if (result == NSModalResponseOK && panel.URL != nil) {
        dispatch_status(ctx, @"FILE_SELECT", panel.URL.path);
        return fre_bool(YES);
    }

    dispatch_status(ctx, @"FILE_CANCEL", @"");
    return fre_bool(NO);
}

static FREObject ObtainWriteAccess(FREContext ctx, void *functionData, uint32_t argc, FREObject argv[]) {
    (void)functionData;

    NSString *requestedPath = argc > 0 ? fre_string_arg(argv[0]) : nil;
    if (is_writable_path(requestedPath)) {
        dispatch_status(ctx, @"FILE_SELECT", requestedPath ?: @"");
        return fre_bool(YES);
    }

    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = NO;
    panel.canChooseDirectories = YES;
    panel.canCreateDirectories = YES;
    panel.prompt = @"Allow";
    panel.message = requestedPath.length > 0
        ? [NSString stringWithFormat:@"Select a folder that should be writable for YNAB.\nRequested path: %@", requestedPath]
        : @"Select a folder that should be writable for YNAB.";

    NSInteger result = [panel runModal];
    if (result == NSModalResponseOK && panel.URL != nil) {
        dispatch_status(ctx, @"FILE_SELECT", panel.URL.path);
        return fre_bool(YES);
    }

    dispatch_status(ctx, @"FILE_CANCEL", @"");
    return fre_bool(NO);
}

static FREObject RelaunchApp(FREContext ctx, void *functionData, uint32_t argc, FREObject argv[]) {
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

static FREObject CheckAppStoreReceipt(FREContext ctx, void *functionData, uint32_t argc, FREObject argv[]) {
    (void)ctx;
    (void)functionData;
    (void)argc;
    (void)argv;

    NSString *receiptPath = [[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:@"Contents/_MASReceipt/receipt"];
    BOOL hasReceipt = receiptPath.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:receiptPath];
    return fre_bool(hasReceipt);
}

static FREObject EnableFullScreenMode(FREContext ctx, void *functionData, uint32_t argc, FREObject argv[]) {
    (void)ctx;
    (void)functionData;
    (void)argc;
    (void)argv;
    return fre_bool(YES);
}

static void MacUtilsContextFinalizer(FREContext ctx) {
    (void)ctx;
}

static void MacUtilsContextInitializer(void *extData, const uint8_t *ctxType, FREContext ctx,
                                       uint32_t *numFunctionsToSet, const FRENamedFunction **functionsToSet) {
    (void)extData;
    (void)ctxType;
    (void)ctx;

    static FRENamedFunction functions[] = {
        {(const uint8_t *)"BrowseForFileOpen", NULL, &BrowseForFileOpen},
        {(const uint8_t *)"CheckAppStoreReceipt", NULL, &CheckAppStoreReceipt},
        {(const uint8_t *)"EnableFullScreenMode", NULL, &EnableFullScreenMode},
        {(const uint8_t *)"IsPathWriteable", NULL, &IsPathWriteable},
        {(const uint8_t *)"IsSandboxed", NULL, &IsSandboxed},
        {(const uint8_t *)"ListFilenamesInDirectory", NULL, &ListFilenamesInDirectory},
        {(const uint8_t *)"ObtainWriteAccess", NULL, &ObtainWriteAccess},
        {(const uint8_t *)"RelaunchApp", NULL, &RelaunchApp},
    };

    *numFunctionsToSet = (uint32_t)(sizeof(functions) / sizeof(functions[0]));
    *functionsToSet = functions;
}

void NativeExtensionsInitializer(void **extDataToSet, FREContextInitializer *ctxInitializerToSet,
                                 FREContextFinalizer *ctxFinalizerToSet) {
    *extDataToSet = NULL;
    *ctxInitializerToSet = &MacUtilsContextInitializer;
    *ctxFinalizerToSet = &MacUtilsContextFinalizer;
}

void NativeExtensionsFinalizer(void *extData) {
    (void)extData;
}
