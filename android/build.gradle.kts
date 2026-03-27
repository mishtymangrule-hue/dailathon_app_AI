buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Force javapoet 1.13.0 to avoid NoSuchMethodError in Hilt's AggregateDepsTask.
        // AGP 8.x transitively brings in javapoet 1.10.0 which lacks ClassName.canonicalName().
        // See: https://github.com/google/dagger/issues/3068
        classpath("com.squareup:javapoet:1.13.0")
    }
}

plugins {
    id("com.google.dagger.hilt.android") version "2.56.2" apply false
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}
