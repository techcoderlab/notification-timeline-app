// ─────────────────────────────────────────────────────
// Module   : MainActivity.kt (Android Native Host)
// ─────────────────────────────────────────────────────
package com.example.notification_timeline_app

import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Main Android Host Activity inheriting from FlutterFragmentActivity
 * for local_auth biometrics and providing platform channel to retrieve
 * installed packages for application filtering.
 */
class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.example.notification_timeline_app/installed_apps"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getInstalledApps") {
                Thread {
                    try {
                        val pm = packageManager
                        val packages = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
                            pm.getInstalledPackages(PackageManager.PackageInfoFlags.of(0))
                        } else {
                            @Suppress("DEPRECATION")
                            pm.getInstalledPackages(0)
                        }
                        val appList = ArrayList<Map<String, Any>>()

                        for (pkg in packages) {
                            val appInfo = pkg.applicationInfo ?: continue
                            val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                            val isUpdatedSystem = (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0

                            val appName = try {
                                pm.getApplicationLabel(appInfo).toString()
                            } catch (e: Exception) {
                                pkg.packageName
                            }
                            val packageName = pkg.packageName

                            // Skip our own application from being listed in filter
                            if (packageName == applicationContext.packageName) continue

                            val map = HashMap<String, Any>()
                            map["packageName"] = packageName
                            map["appName"] = if (appName.isNotEmpty()) appName else packageName
                            map["isSystemApp"] = isSystem && !isUpdatedSystem
                            appList.add(map)
                        }

                        // Sort alphabetically by human-readable app name
                        appList.sortBy { (it["appName"] as String).lowercase() }
                        runOnUiThread {
                            result.success(appList)
                        }
                    } catch (e: Exception) {
                        runOnUiThread {
                            result.error("ERROR_GETTING_APPS", e.message, null)
                        }
                    }
                }.start()
            } else {
                result.notImplemented()
            }
        }
    }
}
