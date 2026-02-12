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
    if (name == "isar_flutter_libs") {
        afterEvaluate {
            try {
                // Set namespace specifically for isar_flutter_libs to fix AGP 8+ issue
                configure<com.android.build.gradle.LibraryExtension> {
                    namespace = "dev.isar.isar_flutter_libs"
                }
            } catch (e: Exception) {
                // Ignore if LibraryExtension is not available
            }
        }
    }

    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

