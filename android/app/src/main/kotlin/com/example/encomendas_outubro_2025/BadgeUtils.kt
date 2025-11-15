package com.example.encomendas_outubro_2025

import android.content.Context
import me.leolin.shortcutbadger.ShortcutBadger

object BadgeUtils {
    fun setBadge(context: Context, count: Int) {
        try {
            ShortcutBadger.applyCount(context, count)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun removeBadge(context: Context) {
        try {
            ShortcutBadger.removeCount(context)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}