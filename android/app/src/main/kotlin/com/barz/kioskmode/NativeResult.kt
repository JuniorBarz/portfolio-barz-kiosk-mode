package com.barz.kioskmode

object NativeResult {
    fun ok(data: Any? = null): Map<String, Any?> {
        return mapOf("success" to true, "error" to null, "data" to data)
    }

    fun fail(error: String): Map<String, Any?> {
        return mapOf("success" to false, "error" to error)
    }
}

