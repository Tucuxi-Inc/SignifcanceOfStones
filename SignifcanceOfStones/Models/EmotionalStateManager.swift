import Foundation

struct EmotionalTemperatures: Equatable {
    var cortex: Double
    var seer: Double
    var oracle: Double
    var house: Double
    var prudence: Double
    var conscience: Double
    
    // Add initializer to convert from tuple
    init(from tuple: (cortex: Double, seer: Double, oracle: Double, house: Double, prudence: Double, conscience: Double)) {
        self.cortex = tuple.cortex
        self.seer = tuple.seer
        self.oracle = tuple.oracle
        self.house = tuple.house
        self.prudence = tuple.prudence
        self.conscience = tuple.conscience
    }
    
    // Add conversion to tuple
    var asTuple: (cortex: Double, seer: Double, oracle: Double, house: Double, prudence: Double, conscience: Double) {
        return (cortex: cortex, seer: seer, oracle: oracle, house: house, prudence: prudence, conscience: conscience)
    }
}

@MainActor
class EmotionalStateManager: ObservableObject {
    @Published var selectedCategory: EmotionCategory = .primary
    @Published var selectedEmotion: String? = nil
    @Published var isUsingBaseline = false
    @Published var currentTemperatures: EmotionalTemperatures = EmotionalTemperatures(
        from: EmotionalTemperature.baselineTemperatures
    )
    
    func resetToBaseline() {
        currentTemperatures = EmotionalTemperatures(
            from: EmotionalTemperature.baselineTemperatures
        )
        isUsingBaseline = true
        selectedEmotion = nil
    }
    
    func setEmotionalBlend(_ emotions: [(String, Double)]) {
        let temps = EmotionalTemperature.calculateBlendedTemperatures(emotions)
        currentTemperatures = EmotionalTemperatures(from: temps)
        isUsingBaseline = false
    }
} 