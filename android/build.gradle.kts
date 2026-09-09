allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}
// Restrict every Android subproject's native build to 64-bit ARM. The NDK 28
// toolchain ships only the aarch64 clang targets — the `armeabi` (32-bit) ABI
// is no longer supported, so plugins that run CMake for all default ABIs
// (e.g. path_provider_android -> jni) fail with "armeabi is no longer
// supported". Pinning abiFilters here prevents that at the root.
subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.BaseExtension>("android") {
            defaultConfig.ndk.abiFilters.add("arm64-v8a")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
