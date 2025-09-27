package com.reentry.shared

data class Mood(
    val id: String,
    val name: String,
    val icon: String? = null,
    val category: String? = null
)

data class MoodLog(
    val id: String,
    val userId: String,
    val mood: Mood,
    val notes: String? = null,
    val intensity: Int? = null,
    val createdAt: String
)

fun formatMoodLog(log: MoodLog): String {
    return "${'$'}{log.mood.name} at ${'$'}{log.createdAt}"
}
