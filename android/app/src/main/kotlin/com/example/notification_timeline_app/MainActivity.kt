// ─────────────────────────────────────────────────────
// Module   : MainActivity.kt (Android Native Host)
// ─────────────────────────────────────────────────────
package com.example.notification_timeline_app

import android.Manifest
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Main Android Host Activity inheriting from FlutterFragmentActivity
 * for local_auth biometrics and providing platform channel to retrieve
 * installed packages for application filtering, checking notification listener
 * permissions via NotificationManagerCompat, and rebinding notification services.
 */
class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.example.notification_timeline_app/installed_apps"
    private val NOTIFICATION_SERVICE_CLASS = "im.zoe.labs.flutter_notification_listener.NotificationsHandlerService"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ensureNotificationServiceEnabled()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    Thread {
                        try {
                            val pm = packageManager
                            val myPackageName = applicationContext.packageName
                            val discoveredMap = HashMap<String, MutableMap<String, Any>>()

                            // Strategy 1: Fetch installed applications with metadata
                            try {
                                val apps = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                    pm.getInstalledApplications(PackageManager.ApplicationInfoFlags.of(PackageManager.GET_META_DATA.toLong()))
                                } else {
                                    @Suppress("DEPRECATION")
                                    pm.getInstalledApplications(PackageManager.GET_META_DATA)
                                }
                                for (appInfo in apps) {
                                    val pkg = appInfo.packageName ?: continue
                                    if (pkg == myPackageName) continue

                                    val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                                    val isUpdatedSystem = (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0

                                    val name = try {
                                        pm.getApplicationLabel(appInfo).toString()
                                    } catch (_: Exception) {
                                        appInfo.loadLabel(pm).toString()
                                    }

                                    val map = HashMap<String, Any>()
                                    map["packageName"] = pkg
                                    map["appName"] = if (name.isNotEmpty()) name else pkg
                                    map["isSystemApp"] = isSystem && !isUpdatedSystem
                                    discoveredMap[pkg] = map
                                }
                            } catch (_: Exception) {
                                // Fall through to Strategy 2 if getInstalledApplications is restricted
                            }

                            // Strategy 2: Query launcher activities to ensure all user launchable apps are discovered
                            try {
                                val launcherIntent = Intent(Intent.ACTION_MAIN, null).apply {
                                    addCategory(Intent.CATEGORY_LAUNCHER)
                                }
                                val resolveList = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                    pm.queryIntentActivities(launcherIntent, PackageManager.ResolveInfoFlags.of(0))
                                } else {
                                    @Suppress("DEPRECATION")
                                    pm.queryIntentActivities(launcherIntent, 0)
                                }
                                for (resolveInfo in resolveList) {
                                    val activityInfo = resolveInfo.activityInfo ?: continue
                                    val pkg = activityInfo.packageName ?: continue
                                    if (pkg == myPackageName) continue

                                    if (!discoveredMap.containsKey(pkg)) {
                                        val appInfo = activityInfo.applicationInfo
                                        val isSystem = if (appInfo != null) {
                                            (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0 &&
                                            (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) == 0
                                        } else false

                                        val name = try {
                                            resolveInfo.loadLabel(pm).toString()
                                        } catch (_: Exception) {
                                            pkg
                                        }

                                        val map = HashMap<String, Any>()
                                        map["packageName"] = pkg
                                        map["appName"] = if (name.isNotEmpty()) name else pkg
                                        map["isSystemApp"] = isSystem
                                        discoveredMap[pkg] = map
                                    }
                                }
                            } catch (_: Exception) {}

                            val appList = ArrayList<Map<String, Any>>(discoveredMap.values)

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
                }

                "checkNotificationPermission" -> {
                    try {
                        val isGranted = checkNotificationAccessGranted()
                        result.success(isGranted)
                    } catch (e: Exception) {
                        result.error("ERROR_CHECK_PERMISSION", e.message, null)
                    }
                }

                "openNotificationListenerSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (_: Exception) {
                        try {
                            val intent = Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS").apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e2: Exception) {
                            result.error("ERROR_OPEN_SETTINGS", e2.message, null)
                        }
                    }
                }

                "rebindNotificationListener" -> {
                    try {
                        val ok = ensureNotificationServiceEnabled()
                        result.success(ok)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }

                "startNotificationListenerService" -> {
                    try {
                        val started = startNotificationServiceDirectly()
                        result.success(started)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }

                "requestPostNotificationPermission" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                                ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1001)
                            }
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    /**
     * Checks if Notification Listener Access is enabled using official AndroidX API
     * and fallback checks for complete Android 10+ (API 29 to 36) compatibility.
     * # O(1) time, O(1) space
     */
    private fun checkNotificationAccessGranted(): Boolean {
        val myPkg = packageName
        ensureNotificationServiceEnabled()

        // 1. Primary Check: NotificationManagerCompat (Reliable across all Android versions 10+)
        try {
            val enabledPackages = NotificationManagerCompat.getEnabledListenerPackages(this)
            if (enabledPackages.contains(myPkg)) {
                return true
            }
        } catch (_: Exception) {}

        // 2. Secondary Check: NotificationManager.isNotificationListenerAccessGranted (API 27+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            try {
                val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? android.app.NotificationManager
                val component = ComponentName(this, NOTIFICATION_SERVICE_CLASS)
                if (nm?.isNotificationListenerAccessGranted(component) == true) {
                    return true
                }
            } catch (_: Exception) {}
        }

        // 3. Fallback Check: Settings.Secure query for older Android builds
        try {
            val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
            if (!flat.isNullOrEmpty() && flat.contains(myPkg)) {
                return true
            }
        } catch (_: Exception) {}

        return false
    }

    /**
     * Ensures the Notification Listener component is enabled in the PackageManager
     * so it is always discoverable in Android System Settings and bound by Android OS.
     * Never disables the component, preventing permission revocation or ANR.
     */
    private fun ensureNotificationServiceEnabled(): Boolean {
        return try {
            val component = ComponentName(this, NOTIFICATION_SERVICE_CLASS)
            val currentState = packageManager.getComponentEnabledSetting(component)
            if (currentState != PackageManager.COMPONENT_ENABLED_STATE_ENABLED) {
                packageManager.setComponentEnabledSetting(
                    component,
                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                    PackageManager.DONT_KILL_APP
                )
            }
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun startNotificationServiceDirectly(): Boolean {
        return ensureNotificationServiceEnabled()
    }
}
