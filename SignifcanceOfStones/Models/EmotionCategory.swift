import Foundation

/// Represents categories and specific emotional states available for selection
enum EmotionCategory: String, CaseIterable {
    case primary = "Primary Emotions"
    case complex = "Complex Emotions"
    case cognitive = "Cognitive States"
    
    /// Returns all emotions within this category
    var emotions: [String] {
        switch self {
        case .primary:
            return [
                "Joy/Happiness/Delight",
                "Sadness/Sorrow/Melancholy",
                "Fear/Terror/Dread",
                "Anger/Rage/Fury",
                "Surprise/Astonishment/Amazement",
                "Disgust/Revulsion/Aversion",
                "Anticipation/Expectancy",
                "Trust/Acceptance"
            ]
        case .complex:
            return [
                "Anxiety/Worry/Unease",
                "Hope/Optimism",
                "Pride/Satisfaction",
                "Shame/Embarrassment",
                "Guilt/Remorse",
                "Envy/Jealousy",
                "Love/Affection",
                "Grief/Despair",
                "Serenity/Tranquility",
                "Awe/Wonder"
            ]
        case .cognitive:
            return [
                "Curiosity",
                "Confusion",
                "Determination",
                "Overwhelm",
                "Focus",
                "Doubt",
                "Confidence",
                "Inspiration",
                "Clarity",
                "Uncertainty",
                "Analytical",
                "Creative",
                "Intuitive",
                "Contemplative",
                "Systematic",
                "Abstract",
                "Empathetic",
                "Critical",
                "Synthesizing",
                "Mindful",
                "Innovative",
                "Methodical"
            ]
        }
    }
    
    /// Categorizes an emotion string into its appropriate category
    static func categorize(_ emotion: String) -> EmotionCategory? {
        let lowercased = emotion.lowercased()
        
        // Primary emotions
        let primaryKeywords = ["joy", "happiness", "sadness", "sorrow", "fear", "anxiety", 
                             "anger", "frustration", "surprise", "amazement", "disgust", 
                             "aversion", "anticipation", "trust", "acceptance"]
        if primaryKeywords.contains(where: { lowercased.contains($0) }) {
            return .primary
        }
        
        // Complex emotions
        let complexKeywords = ["pride", "satisfaction", "shame", "embarrassment", "guilt", 
                             "remorse", "envy", "jealousy", "love", "affection", "grief", 
                             "despair", "serenity", "tranquility", "awe", "wonder"]
        if complexKeywords.contains(where: { lowercased.contains($0) }) {
            return .complex
        }
        
        // Cognitive states
        let cognitiveKeywords = ["curiosity", "confusion", "determination", "focus", 
                                "clarity", "analytical", "creative", "intuitive", 
                                "contemplative", "systematic"]
        if cognitiveKeywords.contains(where: { lowercased.contains($0) }) {
            return .cognitive
        }
        
        return nil
    }
} 