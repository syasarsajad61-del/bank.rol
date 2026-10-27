// [M02][F03] Real Android LocalOnlyHotspot with runtime permission handling.
package ir.zahedan.bankroll_plato
import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var reservation: WifiManager.LocalOnlyHotspotReservation? = null
    private var pending: MethodChannel.Result? = null
    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(engine.dartExecutor.binaryMessenger, "ir.zahedan.bankroll/hotspot").setMethodCallHandler { call, result ->
            if (call.method == "stop") { reservation?.close(); reservation = null; result.success(null) }
            else if (call.method == "start") {
                if (Build.VERSION.SDK_INT < 26) { result.error("API", "هات‌اسپات محلی به اندروید ۸ یا بالاتر نیاز دارد؛ از وای‌فای معمولی استفاده کنید", null) }
                else if (pending != null) { result.error("BUSY", "درخواست در حال اجرا است", null) }
                else {
                    pending = result
                    val permission = if (Build.VERSION.SDK_INT >= 33) Manifest.permission.NEARBY_WIFI_DEVICES else Manifest.permission.ACCESS_FINE_LOCATION
                    if (checkSelfPermission(permission) != PackageManager.PERMISSION_GRANTED) requestPermissions(arrayOf(permission), 7823)
                    else launchHotspot()
                }
            } else result.notImplemented()
        }
    }
    override fun onRequestPermissionsResult(code: Int, permissions: Array<out String>, grants: IntArray) {
        super.onRequestPermissionsResult(code, permissions, grants)
        if (code == 7823) {
            if (grants.isNotEmpty() && grants[0] == PackageManager.PERMISSION_GRANTED) launchHotspot()
            else { pending?.error("PERMISSION", "مجوز شبکه داده نشد", null); pending = null }
        }
    }
    private fun launchHotspot() {
        if (Build.VERSION.SDK_INT < 26) return
        try {
            reservation?.close()
            val manager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            manager.startLocalOnlyHotspot(object : WifiManager.LocalOnlyHotspotCallback() {
                override fun onStarted(value: WifiManager.LocalOnlyHotspotReservation) {
                    reservation = value
                    val ssid: String?; val passphrase: String?
                    if (Build.VERSION.SDK_INT >= 30) { ssid = value.softApConfiguration.ssid; passphrase = value.softApConfiguration.passphrase }
                    else { ssid = value.wifiConfiguration?.SSID; passphrase = value.wifiConfiguration?.preSharedKey }
                    pending?.success(mapOf("ssid" to ssid, "passphrase" to passphrase)); pending = null
                }
                override fun onFailed(reason: Int) { pending?.error("HOTSPOT", "هات‌اسپات در دسترس نیست ($reason). موقعیت و وای‌فای را بررسی کنید", null); pending = null }
                override fun onStopped() { reservation = null }
            }, Handler(Looper.getMainLooper()))
        } catch (e: Exception) { pending?.error("HOTSPOT", e.message, null); pending = null }
    }
    override fun onDestroy() { reservation?.close(); super.onDestroy() }
}
