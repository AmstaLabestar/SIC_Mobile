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
// subprojects {
//     val configureAction = Action<Project> {
//         if (plugins.hasPlugin("com.android.application")) {
//             extensions.configure<com.android.build.gradle.AppExtension>("android") {
//                 compileSdkVersion(36)
//             }
//         }
//         if (plugins.hasPlugin("com.android.library")) {
//             extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
//                 compileSdkVersion(36)
//             }
//         }
//     }
//     if (state.executed) {
//         configureAction.execute(this)
//     } else {
//         afterEvaluate(configureAction)
//     }
// }

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
