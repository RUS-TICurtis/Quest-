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

    fun configureLibrary() {
        if (plugins.hasPlugin("com.android.library")) {
            extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.let { ext ->
                if (ext.namespace == null) {
                    ext.namespace = project.group.toString().takeIf { it.isNotEmpty() }
                        ?: "dev.isar.${project.name.replace('-', '_')}"
                }
                if (ext.compileSdk == null || ext.compileSdk!! < 34) {
                    ext.compileSdk = 36
                }
            }
        }
    }

    if (state.executed) {
        configureLibrary()
    } else {
        afterEvaluate {
            configureLibrary()
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

