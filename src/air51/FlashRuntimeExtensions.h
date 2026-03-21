#ifndef FLASH_RUNTIME_EXTENSIONS_H
#define FLASH_RUNTIME_EXTENSIONS_H

#include <stdint.h>

typedef uint32_t FREResult;
typedef void *FREContext;
typedef void *FREObject;

typedef FREObject (*FREFunction)(FREContext ctx, void *functionData, uint32_t argc, FREObject argv[]);

typedef struct FRENamedFunction {
    const uint8_t *name;
    void *functionData;
    FREFunction function;
} FRENamedFunction;

typedef void (*FREContextInitializer)(void *extData, const uint8_t *ctxType, FREContext ctx,
                                      uint32_t *numFunctionsToSet, const FRENamedFunction **functionsToSet);
typedef void (*FREContextFinalizer)(FREContext ctx);

FREResult FREDispatchStatusEventAsync(FREContext ctx, const uint8_t *code, const uint8_t *level);
FREResult FREGetArrayElementAt(FREObject array, uint32_t index, FREObject *value);
FREResult FREGetArrayLength(FREObject array, uint32_t *length);
FREResult FREGetObjectAsBool(FREObject object, uint32_t *value);
FREResult FREGetObjectAsUTF8(FREObject object, uint32_t *length, const uint8_t **value);
FREResult FRENewObject(const uint8_t *className, uint32_t argc, FREObject argv[],
                       FREObject *object, FREObject *thrownException);
FREResult FRENewObjectFromBool(uint32_t value, FREObject *object);
FREResult FRENewObjectFromUTF8(uint32_t length, const uint8_t *value, FREObject *object);
FREResult FRESetArrayElementAt(FREObject array, uint32_t index, FREObject value);
FREResult FRESetArrayLength(FREObject array, uint32_t length);

#endif
