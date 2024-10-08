cmake_minimum_required(VERSION 3.1)



set(CMAKE_C_COMPILER "zigcc.bat" -target aarch64-linux-android -static)
set(CMAKE_CXX_COMPILER "zigc++.bat" -target aarch64-linux-android -static)
set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")

include_directories(SYSTEM "C:/Android/ndk/27.0.11718014/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/include" -isystem "C:/Android/ndk/27.0.11718014/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/include/x86_64-linux-android")
add_link_options(-L"C:/Android/ndk/27.0.11718014/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/lib/x86_64-linux-android/libc.a")

project(miniaudio LANGUAGES C)

add_library(miniaudio STATIC miniaudio.c)
