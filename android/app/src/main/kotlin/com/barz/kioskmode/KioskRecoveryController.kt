package com.barz.kioskmode

class KioskRecoveryController(
    private val maxAttempts: Int = 5,
    private val windowMs: Long = 30_000
) {
    private val attempts = ArrayDeque<Long>()

    fun canRelaunch(nowMs: Long): Boolean {
        while (attempts.isNotEmpty() && nowMs - attempts.first() > windowMs) {
            attempts.removeFirst()
        }
        return attempts.size < maxAttempts
    }

    fun recordRelaunch(nowMs: Long) {
        attempts.addLast(nowMs)
    }

    fun reset() {
        attempts.clear()
    }
}

