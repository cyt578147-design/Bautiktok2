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
