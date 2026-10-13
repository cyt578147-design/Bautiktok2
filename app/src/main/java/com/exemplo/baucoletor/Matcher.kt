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
