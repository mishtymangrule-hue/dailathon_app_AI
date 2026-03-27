package com.mangrule.dailathon.oem

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import timber.log.Timber

enum class OemBrand {
    XIAOMI, SAMSUNG, HUAWEI, ONEPLUS, OPPO, REALME, VIVO, IQOO, NOTHING, STOCK
}

enum class ColorOsVersion {
    COLOROS_13, COLOROS_14, COLOROS_15, NEWER
}

object OemCompatManager {

    fun getOem(): OemBrand = when {
        Build.MANUFACTURER.equals("xiaomi", ignoreCase = true) -> OemBrand.XIAOMI
        Build.MANUFACTURER.equals("samsung", ignoreCase = true) -> OemBrand.SAMSUNG
        Build.BRAND.equals("huawei", ignoreCase = true) ||
                Build.BRAND.equals("honor", ignoreCase = true) -> OemBrand.HUAWEI
        Build.MANUFACTURER.equals("oneplus", ignoreCase = true) -> OemBrand.ONEPLUS
        Build.BRAND.equals("realme", ignoreCase = true) ||
                Build.PRODUCT.contains("realme", ignoreCase = true) -> OemBrand.REALME
        Build.MANUFACTURER.equals("iqoo", ignoreCase = true) -> OemBrand.IQOO
        Build.MANUFACTURER.equals("vivo", ignoreCase = true) ||
                Build.BRAND.equals("vivo", ignoreCase = true) -> OemBrand.VIVO
        Build.MANUFACTURER.equals("oppo", ignoreCase = true) ||
                Build.BRAND.equals("oppo", ignoreCase = true) -> OemBrand.OPPO
        Build.MANUFACTURER.equals("nothing", ignoreCase = true) -> OemBrand.NOTHING
        else -> OemBrand.STOCK
    }

    /**
     * Get battery/startup optimization settings intent for the device's OEM.
     * Tries multiple fallback intents to account for different ROM versions.
     */
    fun getBatterySettingsIntent(context: Context): Intent {
        val oem = getOem()
        Timber.d("OemCompatManager: detected OEM brand = $oem, manufacturer = ${Build.MANUFACTURER}, brand = ${Build.BRAND}")

        return when (oem) {
            OemBrand.XIAOMI -> getXiaomiBatteryIntent(context)
            OemBrand.SAMSUNG -> getSamsungBatteryIntent(context)
            OemBrand.HUAWEI -> getHuaweiBatteryIntent(context)
            OemBrand.ONEPLUS -> getOnePlusBatteryIntent(context)
            OemBrand.OPPO -> getOppoBatteryIntent(context)
            OemBrand.REALME -> getRealmeBatteryIntent(context)
            OemBrand.VIVO -> getVivoBatteryIntent(context)
            OemBrand.IQOO -> getIqooBatteryIntent(context)
            OemBrand.NOTHING -> getNothingBatteryIntent(context)
            OemBrand.STOCK -> Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", context.packageName, null)
            }
        }
    }

    private fun getXiaomiBatteryIntent(context: Context): Intent {
        return try {
            // Try MIUI power keeper app
            Intent().apply {
                setClassName("com.miui.powerkeeper", 
                    "com.miui.powerkeeper.ui.HideAppPowerModeActivity")
            }
        } catch (e: Exception) {
            // Fallback to settings
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", context.packageName, null)
            }
        }
    }

    private fun getSamsungBatteryIntent(context: Context): Intent {
        return try {
            Intent().apply {
                setClassName("com.samsung.android.lool",
                    "com.samsung.android.sm.battery.ui.BatteryActivity")
            }
        } catch (e: Exception) {
            try {
                // Fallback for newer Samsung devices
                Intent(Intent.ACTION_MAIN).apply {
                    setClassName("com.android.settings",
                        "com.android.settings.Settings\$BatteryUsageSummaryActivity")
                }
            } catch (e2: Exception) {
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.fromParts("package", context.packageName, null)
                }
            }
        }
    }

    private fun getHuaweiBatteryIntent(context: Context): Intent {
        return try {
            Intent().apply {
                setClassName("com.huawei.systemmanager",
                    "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity")
            }
        } catch (e: Exception) {
            try {
                // Alternative for some Huawei versions
                Intent().apply {
                    setClassName("com.huawei.systemmanager",
                        "com.huawei.systemmanager.optimize.process.ProtectActivity")
                }
            } catch (e2: Exception) {
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.fromParts("package", context.packageName, null)
                }
            }
        }
    }

    private fun getOnePlusBatteryIntent(context: Context): Intent {
        return try {
            Intent().apply {
                setClassName("com.oneplus.security",
                    "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity")
            }
        } catch (e: Exception) {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", context.packageName, null)
            }
        }
    }

    /**
     * Oppo devices use ColorOS.
     * Handle multiple ColorOS versions and battery optimization screens.
     */
    private fun getOppoBatteryIntent(context: Context): Intent {
        return try {
            // Try ColorOS Safe Center (primary method)
            Intent().apply {
                setClassName("com.coloros.safecenter",
                    "com.coloros.safecenter.permission.startup.StartupAppListActivity")
            }
        } catch (e: Exception) {
            try {
                // Alternative: Try Oppo's Security app
                Intent().apply {
                    setClassName("com.oppo.safe",
                        "com.oppo.safe.security.SecurityMainActivity")
                }
            } catch (e2: Exception) {
                try {
                    // Fallback: Oppo's App Lock or Startup Manager
                    Intent().apply {
                        setClassName("com.color.os.safecenter",
                            "com.color.os.safecenter.permission.startup.StartupAppListActivity")
                    }
                } catch (e3: Exception) {
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.fromParts("package", context.packageName, null)
                    }
                }
            }
        }
    }

    /**
     * Realme devices (separate from Oppo but use similar ColorOS).
     * Realme UI extends ColorOS with customizations.
     */
    private fun getRealmeBatteryIntent(context: Context): Intent {
        return try {
            // Realme devices often have their own SafeCenter
            Intent().apply {
                setClassName("com.realme.safecenter",
                    "com.realme.safecenter.permission.startup.StartupAppListActivity")
            }
        } catch (e: Exception) {
            try {
                // Fallback to ColorOS SafeCenter (some Realme use ColorOS)
                Intent().apply {
                    setClassName("com.coloros.safecenter",
                        "com.coloros.safecenter.permission.startup.StartupAppListActivity")
                }
            } catch (e2: Exception) {
                try {
                    // Alternative: Realme Settings > App Management
                    Intent().apply {
                        setClassName("com.android.settings",
                            "com.android.settings.Settings\$ApplicationsActivity")
                    }
                } catch (e3: Exception) {
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.fromParts("package", context.packageName, null)
                    }
                }
            }
        }
    }

    /**
     * Vivo devices use Funtouch OS (based on OriginOS for newer models).
     * Some Vivo devices use iQOO brand for gaming variants.
     */
    private fun getVivoBatteryIntent(context: Context): Intent {
        return try {
            // Try iQOO Secure (newer Vivo devices often use this)
            Intent().apply {
                setClassName("com.iqoo.secure",
                    "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity")
            }
        } catch (e: Exception) {
            try {
                // Fallback: Vivo Secure app
                Intent().apply {
                    setClassName("com.vivo.secure",
                        "com.vivo.secure.ui.phoneoptimize.AddWhiteListActivity")
                }
            } catch (e2: Exception) {
                try {
                    // Alternative: OriginOS settings
                    Intent().apply {
                        setClassName("com.android.settings",
                            "com.android.settings.Settings\$AppsActivity")
                    }
                } catch (e3: Exception) {
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.fromParts("package", context.packageName, null)
                    }
                }
            }
        }
    }

    /**
     * iQOO devices (gaming-focused Vivo subsidiary).
     * Use similar optimization approach as Vivo.
     */
    private fun getIqooBatteryIntent(context: Context): Intent {
        return try {
            // iQOO Secure app
            Intent().apply {
                setClassName("com.iqoo.secure",
                    "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity")
            }
        } catch (e: Exception) {
            // Fallback to Vivo app
            getVivoBatteryIntent(context)
        }
    }

    /**
     * Nothing (by Carl Pei) devices running NothingOS.
     * Nothing OS is based on Android 13+.
     */
    private fun getNothingBatteryIntent(context: Context): Intent {
        return try {
            // Try Nothing's app optimization
            Intent().apply {
                setClassName("com.nothing.systemui",
                    "com.nothing.systemui.notification.optimization.AppOptimizationActivity")
            }
        } catch (e: Exception) {
            // Fallback to standard settings
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", context.packageName, null)
            }
        }
    }

    /**
     * Check if device is in MIUI battery saver / low power mode.
     * Used to adjust call audio and visual priority.
     */
    fun isBatterySaverActive(context: Context): Boolean {
        return try {
            when (getOem()) {
                OemBrand.XIAOMI -> {
                    // Check MIUI power keeper setting
                    val contentResolver = context.contentResolver
                    Settings.Global.getInt(contentResolver, "battery_saver_mode", 0) == 1
                }
                OemBrand.SAMSUNG -> {
                    Settings.Global.getInt(context.contentResolver, "sem_powersaving_mode", 0) == 1
                }
                OemBrand.VIVO, OemBrand.IQOO -> {
                    Settings.Global.getInt(context.contentResolver, "power_save_mode", 0) == 1
                }
                else -> false
            }
        } catch (e: Exception) {
            Timber.e(e, "Error checking battery saver mode")
            false
        }
    }
}
