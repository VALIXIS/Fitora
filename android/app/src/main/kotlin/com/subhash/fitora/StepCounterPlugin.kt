package com.subhash.fitora

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.SystemClock
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class StepCounterPlugin : FlutterPlugin, EventChannel.StreamHandler, MethodChannel.MethodCallHandler {

    companion object {
        const val STEP_CHANNEL    = "com.subhash.fitora/step_counter"
        const val DEBUG_CHANNEL   = "com.subhash.fitora/step_debug"
        const val PREFS_NAME      = "fitora_step_prefs"
        const val KEY_BOOT_STEP   = "boot_baseline_steps"
        const val KEY_SAVED_DATE  = "baseline_date"
    }

    private lateinit var eventChannel: EventChannel
    private lateinit var methodChannel: MethodChannel
    private lateinit var context: Context

    private var eventSink: EventChannel.EventSink? = null
    private var sensorManager: SensorManager? = null
    private var sensorListener: SensorEventListener? = null

    // State
    private var bootBaseline: Int    = -1
    private var latestRaw: Int       = -1
    private var latestTodaySteps: Int = 0
    private var lastEventTimestamp: Long = 0L   // epoch millis

    // -------------------------------------------------------------------------
    // FlutterPlugin lifecycle
    // -------------------------------------------------------------------------

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as? SensorManager

        eventChannel = EventChannel(binding.binaryMessenger, STEP_CHANNEL)
        eventChannel.setStreamHandler(this)

        methodChannel = MethodChannel(binding.binaryMessenger, DEBUG_CHANNEL)
        methodChannel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        eventChannel.setStreamHandler(null)
        methodChannel.setMethodCallHandler(null)
        stopListening()
    }

    // -------------------------------------------------------------------------
    // MethodChannel — debug snapshot queries
    // -------------------------------------------------------------------------

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getDebugSnapshot" -> {
                val sm = sensorManager ?: (context.getSystemService(Context.SENSOR_SERVICE) as? SensorManager)
                val isAvailable = sm?.getDefaultSensor(Sensor.TYPE_STEP_COUNTER) != null
                result.success(mapOf(
                    "rawSteps"          to latestRaw,
                    "todaySteps"        to latestTodaySteps,
                    "baseline"          to bootBaseline,
                    "lastEventMs"       to lastEventTimestamp,
                    "sensorAvailable"   to isAvailable
                ))
            }
            else -> result.notImplemented()
        }
    }

    // -------------------------------------------------------------------------
    // EventChannel — step stream
    // -------------------------------------------------------------------------

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
        eventSink = sink
        startListening()
    }

    override fun onCancel(arguments: Any?) {
        stopListening()
        eventSink = null
    }

    // -------------------------------------------------------------------------
    // Sensor logic
    // -------------------------------------------------------------------------

    private fun startListening() {
        sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as? SensorManager
        val stepCounter = sensorManager?.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)

        if (stepCounter == null) {
            // Hardware not present
            eventSink?.endOfStream()
            return
        }

        restoreBaseline()

        sensorListener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent?) {
                if (event == null) return

                val rawSteps = event.values[0].toInt()
                latestRaw = rawSteps
                lastEventTimestamp = System.currentTimeMillis()

                val todayStr  = todayString()
                val savedDate = getPrefs().getString(KEY_SAVED_DATE, "")

                // First reading ever for today — set baseline
                if (bootBaseline < 0 || savedDate != todayStr) {
                    // Midnight crossed or first boot reading
                    bootBaseline = rawSteps
                    saveBaseline(bootBaseline)
                }

                val todaySteps = (rawSteps - bootBaseline).coerceAtLeast(0)
                latestTodaySteps = todaySteps
                eventSink?.success(todaySteps)
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
        }

        sensorManager?.registerListener(
            sensorListener,
            stepCounter,
            SensorManager.SENSOR_DELAY_UI   // ~200ms refresh, appropriate for UI
        )
    }

    private fun stopListening() {
        sensorListener?.let { sensorManager?.unregisterListener(it) }
        sensorListener = null
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private fun getPrefs() =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private fun todayString(): String {
        val cal = java.util.Calendar.getInstance()
        return "${cal.get(java.util.Calendar.YEAR)}-" +
               "${cal.get(java.util.Calendar.MONTH)}-" +
               "${cal.get(java.util.Calendar.DAY_OF_MONTH)}"
    }

    private fun restoreBaseline() {
        val prefs     = getPrefs()
        val savedDate = prefs.getString(KEY_SAVED_DATE, "")
        bootBaseline  = if (savedDate == todayString()) {
            prefs.getInt(KEY_BOOT_STEP, -1)
        } else {
            -1   // New day — will be set on first sensor reading
        }
    }

    private fun saveBaseline(value: Int) {
        getPrefs().edit()
            .putInt(KEY_BOOT_STEP, value)
            .putString(KEY_SAVED_DATE, todayString())
            .apply()
    }
}
