import com.android.build.api.dsl.LibraryExtension
import org.gradle.api.tasks.compile.JavaCompile
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

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

subprojects {
    plugins.withId("com.android.library") {
        extensions.findByType(LibraryExtension::class.java)?.let { android ->
            if (android.namespace.isNullOrBlank()) {
                val manifestFile = file("src/main/AndroidManifest.xml")
                val manifestText = manifestFile.takeIf { it.exists() }?.readText()
                val manifestPackage = manifestText
                    ?.let { Regex("""package\s*=\s*"([^"]+)"""").find(it) }
                    ?.groupValues
                    ?.getOrNull(1)

                android.namespace =
                    manifestPackage
                        ?: "com.compat.${project.name.replace('-', '_')}"
            }
        }

        afterEvaluate {
            val javaTarget =
                tasks.withType(JavaCompile::class.java)
                    .firstOrNull()
                    ?.targetCompatibility
                    ?.ifBlank { null }
                    ?: JavaVersion.VERSION_1_8.toString()

            val kotlinTarget =
                when (javaTarget) {
                    JavaVersion.VERSION_17.toString() ->
                        org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                    JavaVersion.VERSION_11.toString() ->
                        org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
                    else -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
                }

            tasks.withType(KotlinCompile::class.java).configureEach {
                compilerOptions.jvmTarget.set(kotlinTarget)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
