package com.barz.kioskmode

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent

class OptionalAccessibilityService : AccessibilityService() {
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
    }

    override fun onInterrupt() {
    }
}

