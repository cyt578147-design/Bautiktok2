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
