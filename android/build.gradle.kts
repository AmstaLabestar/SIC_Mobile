allprojects {
    repositories {
        google()
        mavenCentral()
    }
    if (project.name != "app") {
        extra.set("flutter", mapOf(
            // compileSdk 36 : certains plugins (flutter_plugin_android_lifecycle)
            // exigent des consommateurs qu'ils compilent en >=35.
            "compileSdkVersion" to 36,
            "minSdkVersion" to 21,
            "targetSdkVersion" to 34,
            // NDK 28 (deja installe) : evite un download ~1 Go du NDK 27.
            "ndkVersion" to "28.2.13676358"
        ))
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
// Force compileSdk=36 sur TOUS les sous-projets plugins (certains plugins
// recents exigent que leurs consommateurs compilent en >=35). En `afterEvaluate`
// pour ECRASER le compileSdk que chaque plugin fixe lui-meme (souvent 34).
// Enregistre AVANT `evaluationDependsOn(":app")` (qui force l'evaluation).
subprojects {
    afterEvaluate {
        val androidExt = extensions.findByName("android")
        when (androidExt) {
            is com.android.build.api.dsl.LibraryExtension -> androidExt.compileSdk = 36
            is com.android.build.api.dsl.ApplicationExtension -> androidExt.compileSdk = 36
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
