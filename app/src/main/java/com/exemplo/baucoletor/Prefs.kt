package com.exemplo.baucoletor

import android.content.Context

object Prefs {
    private fun sp(c: Context) = c.getSharedPreferences("bau", Context.MODE_PRIVATE)
    fun enabled(c: Context) = sp(c).getBoolean("enabled", true)
    fun setEnabled(c: Context, v: Boolean) = sp(c).edit().putBoolean("enabled", v).apply()
    fun useImage(c: Context) = sp(c).getBoolean("useImage", true)
    fun setUseImage(c: Context, v: Boolean) = sp(c).edit().putBoolean("useImage", v).apply()
}
