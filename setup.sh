#!/bin/bash
# Recria o projeto Baú Coletor na pasta atual (cria ./BauColetor)
set -e
mkdir -p BauColetor && cd BauColetor

mkdir -p "."
cat > "LEIA-ME.md" <<'FIM_ARQUIVO_XYZ'
# Baú Coletor (v0.1)

App Android que usa um Serviço de Acessibilidade para:
1. Abrir o painel do baú quando o ícone aparece pronto (por texto/descrição ou por imagem).
2. Tocar em "Abrir" quando o botão deixa de ser contagem regressiva.

## Como gerar o APK (sem Android Studio)
1. Crie um repositório no GitHub e envie todo o conteúdo desta pasta (inclusive a pasta `.github`).
2. Vá em **Actions → Build APK → Run workflow** (ou ele roda sozinho a cada push).
3. Ao terminar, baixe o artefato **BauColetor-apk** → `app-debug.apk`.
4. Instale no celular (permita "instalar apps desconhecidos").

## Ativar
1. Abra o app → botão 1 → Acessibilidade → **Baú Coletor** → ativar.
   - Android 13+: se aparecer "configuração restrita", vá em Configurações → Apps → Baú Coletor → ⋮ → **Permitir configurações restritas** e tente de novo.
2. Desative a otimização de bateria do app e deixe o TikTok aberto na live.

## Ajustes
- Botão **Diagnóstico** despeja a árvore de views da tela do TikTok no log: copie e me mande para ajustar os textos/IDs.
- Constantes no topo de `BauService.kt` (`BOTAO_ABRIR`, `PAINEL`, `NCC_MIN`...).
- Template do ícone: `app/src/main/assets/bau_template.png` (recortado do seu print).
FIM_ARQUIVO_XYZ
mkdir -p "."
cat > "build.gradle.kts" <<'FIM_ARQUIVO_XYZ'
plugins {
    id("com.android.application") version "8.5.2" apply false
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false
}
FIM_ARQUIVO_XYZ
mkdir -p "."
cat > "gradle.properties" <<'FIM_ARQUIVO_XYZ'
org.gradle.jvmargs=-Xmx2g
android.useAndroidX=false
kotlin.code.style=official
FIM_ARQUIVO_XYZ
mkdir -p "."
cat > "settings.gradle.kts" <<'FIM_ARQUIVO_XYZ'
pluginManagement {
    repositories { google(); mavenCentral(); gradlePluginPortal() }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories { google(); mavenCentral() }
}
rootProject.name = "BauColetor"
include(":app")
FIM_ARQUIVO_XYZ
mkdir -p ".github/workflows"
cat > ".github/workflows/build.yml" <<'FIM_ARQUIVO_XYZ'
name: Build APK
on:
  push:
  workflow_dispatch:
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: 17
      - uses: gradle/actions/setup-gradle@v4
        with:
          gradle-version: 8.7
      - name: Compilar
        run: gradle assembleDebug --no-daemon
      - uses: actions/upload-artifact@v4
        with:
          name: BauColetor-apk
          path: app/build/outputs/apk/debug/app-debug.apk
FIM_ARQUIVO_XYZ
mkdir -p "app"
cat > "app/build.gradle.kts" <<'FIM_ARQUIVO_XYZ'
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.exemplo.baucoletor"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.exemplo.baucoletor"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "0.1"
    }
    buildTypes {
        release { isMinifyEnabled = false }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
}
FIM_ARQUIVO_XYZ
mkdir -p "app/src/main"
cat > "app/src/main/AndroidManifest.xml" <<'FIM_ARQUIVO_XYZ'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <application
        android:allowBackup="false"
        android:label="@string/app_name"
        android:theme="@android:style/Theme.DeviceDefault.Light.NoActionBar">

        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <service
            android:name=".BauService"
            android:exported="false"
            android:label="@string/app_name"
            android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE">
            <intent-filter>
                <action android:name="android.accessibilityservice.AccessibilityService" />
            </intent-filter>
            <meta-data
                android:name="android.accessibilityservice"
                android:resource="@xml/accessibility_service_config" />
        </service>
    </application>
</manifest>
FIM_ARQUIVO_XYZ
mkdir -p "app/src/main/assets"
base64 -d > "app/src/main/assets/bau_template.png" <<'B64_END'
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
B64_END
mkdir -p "app/src/main/java/com/exemplo/baucoletor"
cat > "app/src/main/java/com/exemplo/baucoletor/BauService.kt" <<'FIM_ARQUIVO_XYZ'
package com.exemplo.baucoletor

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Path
import android.graphics.Rect
import android.os.Build
import android.view.Display
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class BauService : AccessibilityService() {

    companion object {
        // TikTok global (BR usa este) e variante Ásia
        private val TIKTOK = setOf("com.zhiliaoapp.musically", "com.ss.android.ugc.trill")

        // Texto EXATO do botão quando o baú está liberado
        private val BOTAO_ABRIR = setOf("abrir", "open", "coletar", "collect", "resgatar", "claim", "receber")

        // Palavras que identificam o painel do baú
        private val PAINEL = listOf("baú de tesouro", "bau de tesouro", "treasure chest", "treasure box")

        // Palavras para achar o ícone do baú por descrição de acessibilidade
        private val ICONE = listOf("baú", "bau ", "tesouro", "treasure", "chest")

        private val TIMER = Regex("""\d{1,2}:\d{2}""")

        private const val NCC_MIN = 0.80f        // sensibilidade da busca por imagem (0..1)
        private const val INTERVALO_EVENTO = 700L
        private const val INTERVALO_IMAGEM = 2000L
        private const val RECARGA_ICONE = 20_000L  // não reclicar o ícone logo em seguida
    }

    private var ultimoEvento = 0L
    private var ultimaImagem = 0L
    private var ultimoCliqueIcone = 0L
    private var ultimoCliqueAbrir = 0L
    private var template: Bitmap? = null
    private var capturando = false

    override fun onServiceConnected() {
        super.onServiceConnected()
        template = try {
            assets.open("bau_template.png").use { BitmapFactory.decodeStream(it) }
        } catch (e: Exception) { null }
        Log.add("Serviço conectado. Template de imagem: ${if (template != null) "ok" else "FALTANDO"}")
    }

    override fun onInterrupt() {}

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        val pkg = event.packageName?.toString() ?: return
        if (pkg !in TIKTOK) return
        if (!Prefs.enabled(this)) return

        val agora = System.currentTimeMillis()
        if (agora - ultimoEvento < INTERVALO_EVENTO && !Log.dumpNext) return
        ultimoEvento = agora

        val root = rootInActiveWindow ?: return
        try {
            if (Log.dumpNext) {
                Log.dumpNext = false
                Log.add("=== DUMP DA TELA ===")
                dump(root, 0)
                Log.add("=== FIM DO DUMP ===")
            }

            // 1) Painel do baú aberto: clicar em "Abrir" quando estiver liberado
            if (painelAberto(root)) {
                val botao = acharBotao(root)
                if (botao != null && agora - ultimoCliqueAbrir > 1500) {
                    ultimoCliqueAbrir = agora
                    Log.add("Botão liberado -> clicando em '${botao.text}'")
                    clicar(botao)
                }
                return
            }

            // 2) Ícone do baú pela descrição de acessibilidade
            if (agora - ultimoCliqueIcone > RECARGA_ICONE) {
                val icone = acharIconePorTexto(root)
                if (icone != null) {
                    ultimoCliqueIcone = agora
                    Log.add("Ícone achado por texto -> clicando")
                    clicar(icone)
                    return
                }
            }

            // 3) Ícone pela imagem (captura de tela + comparação)
            if (Prefs.useImage(this) && Build.VERSION.SDK_INT >= Build.VERSION_CODES.R &&
                agora - ultimaImagem > INTERVALO_IMAGEM && agora - ultimoCliqueIcone > RECARGA_ICONE
            ) {
                ultimaImagem = agora
                buscarPorImagem()
            }
        } finally {
            root.recycle()
        }
    }

    // ---------- detecção por texto ----------

    private fun painelAberto(root: AccessibilityNodeInfo): Boolean {
        for (p in PAINEL) {
            val achados = root.findAccessibilityNodeInfosByText(p)
            if (!achados.isNullOrEmpty()) return true
        }
        return false
    }

    private fun acharBotao(root: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        val fila = ArrayDeque<AccessibilityNodeInfo>()
        fila.add(root)
        while (fila.isNotEmpty()) {
            val n = fila.removeFirst()
            val t = (n.text ?: n.contentDescription)?.toString()?.trim()?.lowercase()
            if (t != null && t in BOTAO_ABRIR) return n
            for (i in 0 until n.childCount) n.getChild(i)?.let { fila.add(it) }
        }
        return null
    }

    private fun acharIconePorTexto(root: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        val fila = ArrayDeque<AccessibilityNodeInfo>()
        fila.add(root)
        while (fila.isNotEmpty()) {
            val n = fila.removeFirst()
            if (!n.isEditable) {
                val t = (n.contentDescription ?: n.text)?.toString()?.lowercase()
                if (t != null && t.length < 60 && !TIMER.containsMatchIn(t) && ICONE.any { t.contains(it) }) {
                    return n
                }
            }
            for (i in 0 until n.childCount) n.getChild(i)?.let { fila.add(it) }
        }
        return null
    }

    // ---------- detecção por imagem ----------

    private fun buscarPorImagem() {
        val tpl = template ?: return
        if (capturando) return
        capturando = true
        takeScreenshot(Display.DEFAULT_DISPLAY, mainExecutor, object : TakeScreenshotCallback {
            override fun onSuccess(shot: ScreenshotResult) {
                try {
                    val hw = Bitmap.wrapHardwareBuffer(shot.hardwareBuffer, shot.colorSpace)
                    val bmp = hw?.copy(Bitmap.Config.ARGB_8888, false)
                    shot.hardwareBuffer.close()
                    if (bmp != null) {
                        val hit = Matcher.find(bmp, tpl)
                        if (hit != null && hit.score >= NCC_MIN) {
                            Log.add("Ícone achado por imagem (%.2f) em %d,%d -> clicando".format(hit.score, hit.x, hit.y))
                            ultimoCliqueIcone = System.currentTimeMillis()
                            tocar(hit.x.toFloat(), hit.y.toFloat())
                        } else if (hit != null && hit.score >= 0.6f) {
                            Log.add("Quase: melhor correspondência %.2f (mínimo %.2f)".format(hit.score, NCC_MIN))
                        }
                        bmp.recycle()
                    }
                } catch (e: Exception) {
                    Log.add("Erro na imagem: ${e.message}")
                } finally {
                    capturando = false
                }
            }

            override fun onFailure(errorCode: Int) {
                Log.add("Falha na captura de tela (código $errorCode)")
                capturando = false
            }
        })
    }

    // ---------- cliques ----------

    private fun clicar(no: AccessibilityNodeInfo) {
        var alvo: AccessibilityNodeInfo? = no
        while (alvo != null && !alvo.isClickable) alvo = alvo.parent
        if (alvo != null && alvo.performAction(AccessibilityNodeInfo.ACTION_CLICK)) return
        val r = Rect()
        no.getBoundsInScreen(r)
        tocar(r.exactCenterX(), r.exactCenterY())
    }

    private fun tocar(x: Float, y: Float) {
        val p = Path().apply { moveTo(x, y) }
        val g = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(p, 0, 60))
            .build()
        dispatchGesture(g, null, null)
    }

    // ---------- diagnóstico ----------

    private fun dump(n: AccessibilityNodeInfo, nivel: Int) {
        val r = Rect(); n.getBoundsInScreen(r)
        val cls = n.className?.toString()?.substringAfterLast('.') ?: "?"
        val id = n.viewIdResourceName?.substringAfterLast('/') ?: ""
        val t = n.text?.toString()?.take(40) ?: ""
        val d = n.contentDescription?.toString()?.take(40) ?: ""
        if (t.isNotEmpty() || d.isNotEmpty() || id.isNotEmpty() || n.isClickable) {
            Log.add("${"  ".repeat(minOf(nivel, 6))}$cls id=$id t='$t' d='$d' ${if (n.isClickable) "[click]" else ""} $r")
        }
        for (i in 0 until n.childCount) n.getChild(i)?.let { dump(it, nivel + 1) }
    }
}
FIM_ARQUIVO_XYZ
mkdir -p "app/src/main/java/com/exemplo/baucoletor"
cat > "app/src/main/java/com/exemplo/baucoletor/Log.kt" <<'FIM_ARQUIVO_XYZ'
package com.exemplo.baucoletor

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/** Log simples em memória, exibido na tela principal do app. */
object Log {
    private val lines = ArrayDeque<String>()
    private val fmt = SimpleDateFormat("HH:mm:ss", Locale.getDefault())

    @Volatile var dumpNext = false   // pedido para despejar a árvore de views na próxima leitura

    @Synchronized
    fun add(msg: String) {
        lines.addFirst("${fmt.format(Date())}  $msg")
        while (lines.size > 400) lines.removeLast()
    }

    @Synchronized
    fun text(): String = lines.joinToString("\n")

    @Synchronized
    fun clear() = lines.clear()
}
FIM_ARQUIVO_XYZ
mkdir -p "app/src/main/java/com/exemplo/baucoletor"
cat > "app/src/main/java/com/exemplo/baucoletor/MainActivity.kt" <<'FIM_ARQUIVO_XYZ'
package com.exemplo.baucoletor

import android.app.Activity
import android.content.Intent
import android.graphics.Typeface
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.ViewGroup
import android.widget.Button
import android.widget.CheckBox
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView

class MainActivity : Activity() {

    private lateinit var status: TextView
    private lateinit var logView: TextView
    private val handler = Handler(Looper.getMainLooper())

    private val atualiza = object : Runnable {
        override fun run() {
            val on = servicoAtivo()
            status.text = if (on) "● Serviço de acessibilidade ATIVO" else "○ Serviço DESLIGADO — toque no 1º botão e ative \"Baú Coletor\""
            logView.text = Log.text()
            handler.postDelayed(this, 1000)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val pad = (16 * resources.displayMetrics.density).toInt()
        val raiz = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(pad, pad * 2, pad, pad)
        }

        raiz.addView(TextView(this).apply { text = "Baú Coletor"; textSize = 24f; setTypeface(null, Typeface.BOLD) })
        status = TextView(this).apply { textSize = 15f; setPadding(0, pad / 2, 0, pad / 2) }
        raiz.addView(status)

        raiz.addView(botao("1) Abrir configurações de acessibilidade") {
            startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
        })

        raiz.addView(CheckBox(this).apply {
            text = "Coleta automática ligada"
            isChecked = Prefs.enabled(this@MainActivity)
            setOnCheckedChangeListener { _, v -> Prefs.setEnabled(this@MainActivity, v) }
        })
        raiz.addView(CheckBox(this).apply {
            text = "Procurar o ícone do baú por imagem (captura de tela)"
            isChecked = Prefs.useImage(this@MainActivity)
            setOnCheckedChangeListener { _, v -> Prefs.setUseImage(this@MainActivity, v) }
        })

        raiz.addView(botao("2) Diagnóstico: ler a tela do TikTok") {
            Log.dumpNext = true
            Log.add("Dump pedido: volte ao TikTok (na live) e aguarde 1–2 s...")
        })
        raiz.addView(botao("Limpar log") { Log.clear() })

        logView = TextView(this).apply { textSize = 11f; typeface = Typeface.MONOSPACE; setTextIsSelectable(true) }
        raiz.addView(ScrollView(this).apply { addView(logView) },
            LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))

        setContentView(raiz)
    }

    private fun botao(texto: String, acao: () -> Unit) = Button(this).apply {
        text = texto; isAllCaps = false; setOnClickListener { acao() }
    }

    private fun servicoAtivo(): Boolean {
        val s = Settings.Secure.getString(contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES) ?: return false
        return s.contains("$packageName/")
    }

    override fun onResume() { super.onResume(); handler.post(atualiza) }
    override fun onPause() { super.onPause(); handler.removeCallbacks(atualiza) }
}
FIM_ARQUIVO_XYZ
mkdir -p "app/src/main/java/com/exemplo/baucoletor"
cat > "app/src/main/java/com/exemplo/baucoletor/Matcher.kt" <<'FIM_ARQUIVO_XYZ'
package com.exemplo.baucoletor

import android.graphics.Bitmap
import kotlin.math.sqrt

/**
 * Procura o ícone do baú na captura de tela (correlação normalizada, NCC).
 * O template foi recortado de um print com largura 720px; tudo é reescalado.
 */
object Matcher {
    private const val WORK_W = 240
    private const val TEMPLATE_BASE_W = 720f

    class Hit(val score: Float, val x: Int, val y: Int)

    private fun gray(bm: Bitmap): IntArray {
        val px = IntArray(bm.width * bm.height)
        bm.getPixels(px, 0, bm.width, 0, 0, bm.width, bm.height)
        for (i in px.indices) {
            val c = px[i]
            px[i] = (((c shr 16) and 255) * 299 + ((c shr 8) and 255) * 587 + (c and 255) * 114) / 1000
        }
        return px
    }

    fun find(screen: Bitmap, template: Bitmap): Hit? {
        val sh = screen.height * WORK_W / screen.width
        val small = Bitmap.createScaledBitmap(screen, WORK_W, sh, true)
        val tw = maxOf(8, (template.width * WORK_W / TEMPLATE_BASE_W).toInt())
        val th = maxOf(8, template.height * tw / template.width)
        val tSmall = Bitmap.createScaledBitmap(template, tw, th, true)

        val img = gray(small)
        val tp = gray(tSmall)
        val n = tw * th
        val tMean = tp.sum().toFloat() / n
        val tc = FloatArray(n) { tp[it] - tMean }
        val tNorm = sqrt(tc.sumOf { (it * it).toDouble() }).toFloat()
        if (tNorm < 1f) return null

        // Região de busca: canto superior esquerdo, onde o TikTok coloca o ícone do baú
        val x0 = 0
        val x1 = (WORK_W * 0.55f).toInt() - tw
        val y0 = (sh * 0.06f).toInt()
        val y1 = (sh * 0.50f).toInt() - th

        var best = -1f; var bx = 0; var by = 0
        for (y in y0..y1) for (x in x0..x1) {
            var sI = 0f; var sI2 = 0f; var sIT = 0f
            var k = 0
            for (ty in 0 until th) {
                val row = (y + ty) * WORK_W + x
                for (tx in 0 until tw) {
                    val v = img[row + tx].toFloat()
                    sI += v; sI2 += v * v; sIT += v * tc[k]; k++
                }
            }
            val varI = sI2 - sI * sI / n
            if (varI < 1f) continue
            val ncc = sIT / (sqrt(varI) * tNorm)
            if (ncc > best) { best = ncc; bx = x; by = y }
        }
        small.recycle(); tSmall.recycle()
        if (best < 0) return null
        val scale = screen.width.toFloat() / WORK_W
        return Hit(best, ((bx + tw / 2f) * scale).toInt(), ((by + th / 2f) * scale).toInt())
    }
}
FIM_ARQUIVO_XYZ
mkdir -p "app/src/main/java/com/exemplo/baucoletor"
cat > "app/src/main/java/com/exemplo/baucoletor/Prefs.kt" <<'FIM_ARQUIVO_XYZ'
package com.exemplo.baucoletor

import android.content.Context

object Prefs {
    private fun sp(c: Context) = c.getSharedPreferences("bau", Context.MODE_PRIVATE)
    fun enabled(c: Context) = sp(c).getBoolean("enabled", true)
    fun setEnabled(c: Context, v: Boolean) = sp(c).edit().putBoolean("enabled", v).apply()
    fun useImage(c: Context) = sp(c).getBoolean("useImage", true)
    fun setUseImage(c: Context, v: Boolean) = sp(c).edit().putBoolean("useImage", v).apply()
}
FIM_ARQUIVO_XYZ
mkdir -p "app/src/main/res/values"
cat > "app/src/main/res/values/strings.xml" <<'FIM_ARQUIVO_XYZ'
<resources>
    <string name="app_name">Baú Coletor</string>
    <string name="service_desc">Detecta o baú de tesouros nas lives do TikTok e toca nele automaticamente.</string>
</resources>
FIM_ARQUIVO_XYZ
mkdir -p "app/src/main/res/xml"
cat > "app/src/main/res/xml/accessibility_service_config.xml" <<'FIM_ARQUIVO_XYZ'
<?xml version="1.0" encoding="utf-8"?>
<accessibility-service xmlns:android="http://schemas.android.com/apk/res/android"
    android:accessibilityEventTypes="typeWindowStateChanged|typeWindowContentChanged"
    android:accessibilityFeedbackType="feedbackGeneric"
    android:accessibilityFlags="flagReportViewIds|flagIncludeNotImportantViews|flagRetrieveInteractiveWindows"
    android:canRetrieveWindowContent="true"
    android:canPerformGestures="true"
    android:canTakeScreenshot="true"
    android:notificationTimeout="300"
    android:description="@string/service_desc" />
FIM_ARQUIVO_XYZ
echo "Pronto! Projeto criado em $(pwd)"
