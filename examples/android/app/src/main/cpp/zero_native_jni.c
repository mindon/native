#include <jni.h>
#include <stdint.h>
#include <string.h>

#include "zero_native.h"

JNIEXPORT jlong JNICALL Java_dev_zero_1native_examples_android_MainActivity_nativeCreate(JNIEnv *env, jobject self) {
    (void)env;
    (void)self;
    return (jlong)zero_native_app_create();
}

JNIEXPORT void JNICALL Java_dev_zero_1native_examples_android_MainActivity_nativeDestroy(JNIEnv *env, jobject self, jlong app) {
    (void)env;
    (void)self;
    zero_native_app_destroy((void *)app);
}

JNIEXPORT void JNICALL Java_dev_zero_1native_examples_android_MainActivity_nativeStart(JNIEnv *env, jobject self, jlong app) {
    (void)env;
    (void)self;
    zero_native_app_start((void *)app);
}

JNIEXPORT void JNICALL Java_dev_zero_1native_examples_android_MainActivity_nativeStop(JNIEnv *env, jobject self, jlong app) {
    (void)env;
    (void)self;
    zero_native_app_stop((void *)app);
}

JNIEXPORT void JNICALL Java_dev_zero_1native_examples_android_MainActivity_nativeResize(JNIEnv *env, jobject self, jlong app, jfloat width, jfloat height, jfloat scale, jobject surface) {
    (void)env;
    (void)self;
    zero_native_app_resize((void *)app, width, height, scale, surface);
}

JNIEXPORT void JNICALL Java_dev_zero_1native_examples_android_MainActivity_nativeTouch(JNIEnv *env, jobject self, jlong app, jlong id, jint phase, jfloat x, jfloat y, jfloat pressure) {
    (void)env;
    (void)self;
    zero_native_app_touch((void *)app, (uint64_t)id, phase, x, y, pressure);
}

JNIEXPORT jint JNICALL Java_dev_zero_1native_examples_android_MainActivity_nativeCommand(JNIEnv *env, jobject self, jlong app, jstring command) {
    (void)self;
    const char *command_chars = (*env)->GetStringUTFChars(env, command, NULL);
    if (!command_chars) return 0;
    zero_native_app_command((void *)app, command_chars, strlen(command_chars));
    (*env)->ReleaseStringUTFChars(env, command, command_chars);
    return (jint)zero_native_app_last_command_count((void *)app);
}

JNIEXPORT void JNICALL Java_dev_zero_1native_examples_android_MainActivity_nativeFrame(JNIEnv *env, jobject self, jlong app) {
    (void)env;
    (void)self;
    zero_native_app_frame((void *)app);
}
