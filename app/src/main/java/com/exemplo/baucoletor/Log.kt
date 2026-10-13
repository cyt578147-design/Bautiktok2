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
