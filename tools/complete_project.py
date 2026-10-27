from pathlib import Path
import re, json, math, wave, struct
ROOT=Path(__file__).resolve().parents[1]
def write(name,text):
    p=ROOT/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text,encoding='utf-8')

write('lib/main.dart', '''// [F01][T09] Offline entry point.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app.dart';
void main(){WidgetsFlutterBinding.ensureInitialized();GoogleFonts.config.allowRuntimeFetching=false;runApp(const BankrollApp());}
''')
models={'player':'Player','property':'Property','contract':'Contract, ContractKind','loan':'Loan','auction':'Auction','insurance':'Insurance','economic_phase':'EconomicPhase','vote':'Vote'}
for file,symbol in models.items():write(f'lib/core/models/{file}.dart',f"// [T06] Public model entry point.\nexport 'game_state.dart' show {symbol};\n")
write('lib/core/models/city_property.dart', '''// [R10][R13] Typed neighborhood property.
import 'game_state.dart';
import '../data/properties_data.dart';
class CityProperty extends Property {CityProperty(CityPropertyData data):super(id:data.id,name:data.name,price:data.price,baseRent:data.baseRent,buildingCost:data.buildingCost,block:data.block);}
''')
write('lib/core/models/public_property.dart', '''// [R10][R12] Typed public property.
import 'game_state.dart';
import '../data/properties_data.dart';
class PublicProperty extends Property {PublicProperty(PublicPropertyData data):super(id:data.id,name:data.name,price:data.price,baseRent:data.baseRent);}
''')
write('lib/core/models/chance_card.dart', '''// [R16] Immutable drawn card model.
import '../data/chance_cards_data.dart';
class ChanceCard {final ChanceCardData data;final String playerId;final int round;const ChanceCard(this.data,this.playerId,this.round);Map<String,dynamic> toJson()=>{'id':data.id,'playerId':playerId,'round':round};}
''')
write('lib/core/models/law.dart', '''// [R25] Immutable enacted law model.
import '../data/laws_data.dart';
class Law {final LawData data;final int enactedRound;const Law(this.data,this.enactedRound);Map<String,dynamic> toJson()=>{'id':data.id,'enactedRound':enactedRound};}
''')
write('lib/core/models/building.dart', '''// [R13] A validated building level and its rent multiplier.
class Building {final int level;Building(this.level){if(level<0||level>3)throw RangeError.range(level,0,3);}double get multiplier=>[1.0,3.0,5.0,8.0][level];}
''')
write('lib/core/models/snapshot_state.dart', "// [M10] Snapshot representation.\nexport '../../network/snapshot.dart' show Snapshot;\n")
for label in ['Easy','Medium','Hard']:
    lower=label.lower()
    write(f'lib/ai/bot_{lower}.dart',f'''// [B01][B10] {label} strategy using the shared command API.
import '../core/models/game_state.dart';
import 'bot_controller.dart';
class Bot{label} {{static Player create(String id,String name,int identity,{{Personality personality=Personality.balanced}})=>Player(id:id,name:name,identity:identity,bot:true,difficulty:Difficulty.{lower},personality:personality);static BotAction? decide(GameState s,Player p){{if(p.difficulty!=Difficulty.{lower})throw ArgumentError('Difficulty mismatch');return BotController.decide(s,p);}}}}
''')
write('lib/ai/personality.dart', "// [B05] Personality and risk reserve.\nexport '../core/models/game_state.dart' show Personality;\nexport 'bot_controller.dart' show BotController;\n")
screens={'splash':'SplashScreen','main_menu':'MainMenuScreen','game_setup':'GameSetupScreen','game_board':'GameBoardScreen','end_game':'EndGameScreen','host_lobby':'HostLobbyScreen','join_lobby':'JoinLobbyScreen','auction':'AuctionScreen','contract':'ContractScreen','vote':'VoteScreen','loan':'LoanScreen'}
for file,symbol in screens.items():write(f'lib/ui/screens/{file}.dart',f"// [T06] Screen entry point.\nexport 'screens.dart' show {symbol};\n")
widgets={'player_profile_card':'PlayerProfileCard','property_card':'PropertyCard','dice_widget':'DiceWidget','phase_indicator':'PhaseIndicator','inflation_meter':'InflationMeter','common_bank_pool':'CommonBankPool','action_button':'ActionButton','bid_input':'BidInput','timer_widget':'TimerWidget','center_hud':'CenterHud','bottom_dock':'BottomDock','top_ticker_bar':'TopTickerBar','space_widget':'SpaceWidget','path_progress_bar':'PathProgressBar'}
for file,symbol in widgets.items():write(f'lib/ui/widgets/{file}.dart',f"// [T06] Widget entry point.\nexport 'components.dart' show {symbol};\n")
for p in (ROOT/'lib').rglob('*.dart'):
    if p.parent.name=='data' and p.name in ['properties_data.dart','chance_cards_data.dart','laws_data.dart']:continue
    text=p.read_text(encoding='utf-8');text=re.sub(r'\?\.(\d+)',r'? 0.\1',text);p.write_text(text,encoding='utf-8')

manifest=ROOT/'android/app/src/main/AndroidManifest.xml'
s=manifest.read_text(encoding='utf-8').replace('android:label="bankroll_plato"','android:label="بانک‌رول پلاتو+" android:usesCleartextTraffic="true"')
perms=['INTERNET','ACCESS_WIFI_STATE','CHANGE_WIFI_STATE','ACCESS_NETWORK_STATE','NEARBY_WIFI_DEVICES','ACCESS_FINE_LOCATION','ACCESS_COARSE_LOCATION','CHANGE_WIFI_MULTICAST_STATE']
s=s.replace('<application', '\n'.join(f'<uses-permission android:name="android.permission.{p}"'+(' android:usesPermissionFlags="neverForLocation"' if p=='NEARBY_WIFI_DEVICES' else '')+'/>' for p in perms)+'\n    <application',1)
manifest.write_text(s,encoding='utf-8')
write('android/app/src/main/kotlin/ir/zahedan/bankroll_plato/MainActivity.kt', '''// [M02][F03] Real Android LocalOnlyHotspot with runtime permission handling.
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
''')
appgradle=ROOT/'android/app/build.gradle.kts'
s=appgradle.read_text(encoding='utf-8');s=s.replace('minSdk = flutter.minSdkVersion','minSdk = 24').replace('targetSdk = flutter.targetSdkVersion','targetSdk = 34').replace('compileSdk = flutter.compileSdkVersion','compileSdk = 36')
s='\n'.join(l for l in s.splitlines() if '// TODO' not in l)
appgradle.write_text(s+'\n',encoding='utf-8')
write('android/app/src/main/res/values/colors.xml','<resources><color name="cream">#FAF6EE</color><color name="navy">#1E3A5F</color></resources>\n')
write('android/app/src/main/res/values/strings.xml','<resources><string name="app_name">بانک‌رول پلاتو+</string></resources>\n')
for filename,frames,color in [('coin_spin',30,[.83,.68,.22,1]),('dice_roll',20,[1,1,1,1]),('contract_break',15,[.9,.3,.24,1]),('phase_change',24,[.15,.68,.38,1])]:
    animation={'v':'5.7.4','fr':30,'ip':0,'op':frames,'w':128,'h':128,'nm':filename,'ddd':0,'assets':[],'layers':[{'ddd':0,'ind':1,'ty':4,'nm':filename,'sr':1,'ks':{'o':{'a':0,'k':100},'r':{'a':1,'k':[{'t':0,'s':[0],'e':[360],'i':{'x':[.67],'y':[1]},'o':{'x':[.33],'y':[0]}},{'t':frames,'s':[360]}]},'p':{'a':0,'k':[64,64,0]},'a':{'a':0,'k':[0,0,0]},'s':{'a':0,'k':[100,100,100]}},'shapes':[{'ty':'el','p':{'a':0,'k':[0,0]},'s':{'a':0,'k':[64,64]},'nm':'coin'},{'ty':'fl','c':{'a':0,'k':color},'o':{'a':0,'k':100},'r':1}], 'ip':0,'op':frames,'st':0,'bm':0}]}
    write(f'assets/animations/{filename}.json',json.dumps(animation))
for name,notes in {'dice_roll':[180,240,300,400,260,200],'coin_collect':[660,880,1320],'contract_seal':[300,160,100],'phase_change':[440,554,659,880],'error_buzz':[140,120]}.items():
    sample_rate=22050;duration=.08;data=[]
    for frequency in notes:
        for n in range(int(sample_rate*duration)):
            t=n/sample_rate;envelope=math.sin(math.pi*t/duration)**2;data.append(int(7500*envelope*math.sin(2*math.pi*frequency*t)))
    with wave.open(str(ROOT/f'assets/sounds/{name}.wav'),'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(sample_rate);f.writeframes(struct.pack('<'+'h'*len(data),*data))
write('assets/fonts/LICENSE.txt','Vazirmatn by Saber Rastikerdar, SIL Open Font License 1.1. Source: github.com/rastikerdar/vazirmatn\n')
print('Models, module entry points, Android hotspot, animation and sound assets created.')
