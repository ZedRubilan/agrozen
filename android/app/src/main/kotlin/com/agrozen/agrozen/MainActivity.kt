package com.agrozen.agrozen

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val locationChannel = "com.agrozen.agrozen/location"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, locationChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "getCurrentLocation") {
                    resolveAndroidLocation(result)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun resolveAndroidLocation(result: MethodChannel.Result) {
        val fineGranted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        val coarseGranted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        if (!fineGranted && !coarseGranted) {
            result.success(null)
            return
        }

        val locationManager = getSystemService(Context.LOCATION_SERVICE) as? LocationManager
        if (locationManager == null) {
            result.success(null)
            return
        }

        try {
            val providers = listOf(
                LocationManager.GPS_PROVIDER,
                LocationManager.NETWORK_PROVIDER,
                LocationManager.PASSIVE_PROVIDER
            )
            var bestLocation: Location? = null
            val now = System.currentTimeMillis()

            for (provider in providers) {
                if (!locationManager.isProviderEnabled(provider)) continue
                val loc = try {
                    locationManager.getLastKnownLocation(provider)
                } catch (_: SecurityException) {
                    null
                }
                if (loc != null) {
                    if (bestLocation == null || loc.time > bestLocation!!.time) {
                        bestLocation = loc
                    }
                }
            }

            // If we have a recent fix (< 20 minutes old), return immediately
            if (bestLocation != null && (now - bestLocation.time) < 20 * 60 * 1000L) {
                result.success(
                    mapOf(
                        "lat" to bestLocation.latitude,
                        "lon" to bestLocation.longitude
                    )
                )
                return
            }

            // Otherwise request a fresh single update with a 5-second timeout fallback
            var completed = false
            val handler = Handler(Looper.getMainLooper())
            val listener = object : LocationListener {
                override fun onLocationChanged(location: Location) {
                    if (completed) return
                    completed = true
                    try {
                        locationManager.removeUpdates(this)
                    } catch (_: Exception) {}
                    result.success(
                        mapOf(
                            "lat" to location.latitude,
                            "lon" to location.longitude
                        )
                    )
                }

                @Deprecated("Deprecated in Java")
                override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
                override fun onProviderEnabled(provider: String) {}
                override fun onProviderDisabled(provider: String) {}
            }

            var requestedAny = false
            for (provider in listOf(LocationManager.NETWORK_PROVIDER, LocationManager.GPS_PROVIDER)) {
                if (locationManager.isProviderEnabled(provider)) {
                    try {
                        locationManager.requestLocationUpdates(
                            provider,
                            0L,
                            0f,
                            listener,
                            Looper.getMainLooper()
                        )
                        requestedAny = true
                    } catch (_: SecurityException) {}
                }
            }

            if (!requestedAny) {
                if (bestLocation != null) {
                    result.success(
                        mapOf(
                            "lat" to bestLocation.latitude,
                            "lon" to bestLocation.longitude
                        )
                    )
                } else {
                    result.success(null)
                }
                return
            }

            handler.postDelayed({
                if (!completed) {
                    completed = true
                    try {
                        locationManager.removeUpdates(listener)
                    } catch (_: Exception) {}
                    if (bestLocation != null) {
                        result.success(
                            mapOf(
                                "lat" to bestLocation.latitude,
                                "lon" to bestLocation.longitude
                            )
                        )
                    } else {
                        result.success(null)
                    }
                }
            }, 5000L)
        } catch (_: Exception) {
            result.success(null)
        }
    }
}

