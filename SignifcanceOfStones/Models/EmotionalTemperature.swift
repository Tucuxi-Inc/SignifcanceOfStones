import Foundation

/// A system for mapping emotional states to agent temperature adjustments.
/// Temperature values range from 0.0 to 1.0, where:
/// - 0.0-0.3: Very conservative/cautious processing
/// - 0.4-0.5: Measured/careful processing
/// - 0.6-0.7: Balanced/moderate processing
/// - 0.8-0.9: Creative/exploratory processing
/// - 1.0: Maximum creative/exploratory processing (rarely used)
struct EmotionalTemperature {
    /// Baseline temperatures used only for initialization or manual reset.
    /// These represent balanced starting points for each agent's processing style.
    static let baselineTemperatures = (
        cortex: 0.7,    // Balanced analytical processing
        seer: 0.4,      // Moderate pattern recognition
        oracle: 0.4,    // Conservative strategy formation
        house: 0.4,     // Careful implementation planning
        prudence: 0.3,  // Alert risk assessment
        dayDream: 0.8,  // Higher temperature for creative associations
        conscience: 0.5  // Balanced moral judgment
    )
    
    /// Calculates temperature adjustments based on the current emotional state.
    /// - Parameters:
    ///   - emotions: Array of tuples containing emotion strings and their intensity percentages
    /// - Returns: Weighted average temperatures based on emotional state percentages
    static func calculateBlendedTemperatures(_ emotions: [(String, Double)]) -> (cortex: Double, seer: Double, oracle: Double, house: Double, prudence: Double, dayDream: Double, conscience: Double) {
        print("\n📊 Calculating blended temperatures for \(emotions.count) emotions:")
        
        // Initialize accumulators for each temperature
        var blendedTemps = (
            cortex: 0.0,
            seer: 0.0,
            oracle: 0.0,
            house: 0.0,
            prudence: 0.0,
            dayDream: 0.0,
            conscience: 0.0
        )
        
        let totalPercentage = emotions.reduce(0.0) { $0 + $1.1 }
        
        for (emotion, percentage) in emotions {
            let emotionTemps = getEmotionTemperatures(emotion)
            let weight = percentage / totalPercentage
            
            logTemperatureCalculation(emotion, percentage: percentage, temps: emotionTemps)
            
            // Add weighted contribution from this emotion
            blendedTemps.cortex += emotionTemps.cortex * weight
            blendedTemps.seer += emotionTemps.seer * weight
            blendedTemps.oracle += emotionTemps.oracle * weight
            blendedTemps.house += emotionTemps.house * weight
            blendedTemps.prudence += emotionTemps.prudence * weight
            blendedTemps.dayDream += emotionTemps.dayDream * weight
            blendedTemps.conscience += emotionTemps.conscience * weight
        }
        
        printFinalTemperatures(blendedTemps)
        
        return blendedTemps
    }
    
    /// Maps emotions to specific temperature settings for each agent.
    /// Each emotion influences agent temperatures based on how that emotional state
    /// should affect different aspects of processing:
    ///
    /// Agent Temperature Impacts:
    /// - Cortex: Higher = more analytical/creative processing, Lower = more focused/conservative
    /// - Seer: Higher = enhanced pattern recognition, Lower = careful/methodical analysis
    /// - Oracle: Higher = expansive strategic thinking, Lower = conservative planning
    /// - House: Higher = flexible implementation, Lower = careful/precise execution
    /// - Prudence: Higher = increased risk awareness, Lower = more accepting of risk
    /// - Day-Dream: Higher = enhanced creative associations, Lower = more logical connections
    /// - Conscience: Higher = heightened ethical consideration, Lower = pragmatic focus
    public static func getEmotionTemperatures(_ emotion: String) -> (cortex: Double, seer: Double, oracle: Double, house: Double, prudence: Double, dayDream: Double, conscience: Double) {
        let lowercased = emotion.lowercased()
        
        /// Primary Emotions: These represent fundamental emotional responses
        /// that tend to have strong, direct impacts on processing
        switch true {
        case lowercased.contains("joy"), lowercased.contains("happiness"), lowercased.contains("delight"):
            // Joy promotes creative thinking and reduces excessive caution
            // - High cortex: Encourages creative processing
            // - High seer: Enhances pattern recognition
            // - High oracle: Promotes optimistic planning
            // - Moderate house: Maintains practical grounding
            // - Low prudence: Reduces excessive caution
            // - Moderate conscience: Balanced ethical consideration
            return (cortex: 0.8, seer: 0.7, oracle: 0.7, house: 0.6, prudence: 0.4, dayDream: 0.9, conscience: 0.6)
            
        case lowercased.contains("sadness"), lowercased.contains("sorrow"), lowercased.contains("melancholy"):
            // Sadness promotes careful reflection and ethical consideration
            // - Moderate cortex: Measured analytical processing
            // - Low seer: More conservative pattern recognition
            // - Low oracle: Careful strategic planning
            // - Low house: Cautious implementation
            // - High prudence: Enhanced risk awareness
            // - High conscience: Increased ethical sensitivity
            return (cortex: 0.5, seer: 0.3, oracle: 0.4, house: 0.4, prudence: 0.6, dayDream: 0.7, conscience: 0.7)
            
        case lowercased.contains("fear"), lowercased.contains("terror"), lowercased.contains("dread"):
            // Fear heightens caution and risk assessment
            // - Low cortex: More focused, survival-oriented processing
            // - Low seer: Careful, threat-focused pattern recognition
            // - Low oracle: Conservative planning
            // - Low house: Very careful implementation
            // - Very high prudence: Maximum risk awareness
            // - High conscience: Enhanced survival ethics
            return (cortex: 0.4, seer: 0.3, oracle: 0.4, house: 0.3, prudence: 0.8, dayDream: 0.6, conscience: 0.6)
            
        case lowercased.contains("anger"), lowercased.contains("rage"), lowercased.contains("fury"):
            // Anger increases analytical focus but may impair strategic thinking
            // - Very high cortex: Intense analytical processing
            // - Low seer: Reduced pattern recognition due to tunnel vision
            // - Moderate oracle: Slightly impaired strategic thinking
            // - Low house: Careful implementation needed
            // - High prudence: Enhanced threat assessment
            // - Moderate conscience: Balanced moral consideration
            return (cortex: 0.8, seer: 0.4, oracle: 0.5, house: 0.4, prudence: 0.7, dayDream: 0.7, conscience: 0.6)
            
        case lowercased.contains("surprise"), lowercased.contains("astonishment"), lowercased.contains("amazement"):
            // Surprise enhances pattern recognition and reduces rigid thinking
            // - High cortex: Enhanced cognitive processing
            // - Very high seer: Maximized pattern recognition
            // - Moderate oracle: Open to new strategies
            // - Moderate house: Flexible implementation
            // - Low prudence: Reduced risk aversion
            // - Moderate conscience: Standard ethical processing
            return (cortex: 0.7, seer: 0.8, oracle: 0.6, house: 0.5, prudence: 0.4, dayDream: 0.9, conscience: 0.5)
            
        case lowercased.contains("disgust"), lowercased.contains("revulsion"), lowercased.contains("aversion"):
            // Disgust heightens moral judgment and risk assessment
            // - Moderate cortex: Maintained analytical ability
            // - Low seer: Reduced pattern exploration
            // - Moderate oracle: Careful strategic planning
            // - Low house: Cautious implementation
            // - High prudence: Enhanced risk awareness
            // - Very high conscience: Heightened moral sensitivity
            return (cortex: 0.6, seer: 0.4, oracle: 0.5, house: 0.4, prudence: 0.7, dayDream: 0.5, conscience: 0.8)
            
        case lowercased.contains("anticipation"), lowercased.contains("expectancy"):
            // Anticipation enhances future-oriented thinking and pattern recognition
            // - High cortex: Enhanced cognitive engagement
            // - Very high seer: Maximized pattern recognition for future events
            // - Very high oracle: Enhanced strategic planning
            // - Moderate house: Balanced implementation focus
            // - Moderate prudence: Balanced risk assessment
            // - Moderate conscience: Standard ethical processing
            return (cortex: 0.7, seer: 0.8, oracle: 0.8, house: 0.6, prudence: 0.5, dayDream: 0.8, conscience: 0.5)
            
        case lowercased.contains("trust"), lowercased.contains("acceptance"):
            // Trust promotes balanced processing with reduced risk aversion
            // - Moderate cortex: Balanced analytical processing
            // - High seer: Enhanced pattern acceptance
            // - High oracle: Open strategic thinking
            // - High house: Confident implementation
            // - Low prudence: Reduced risk aversion
            // - High conscience: Enhanced ethical consideration
            return (cortex: 0.6, seer: 0.7, oracle: 0.7, house: 0.7, prudence: 0.4, dayDream: 0.7, conscience: 0.7)

        /// Complex Emotions: These represent more nuanced emotional states
        /// that often combine multiple primary emotions and cognitive elements
        case lowercased.contains("anxiety"), lowercased.contains("worry"), lowercased.contains("unease"):
            // Anxiety promotes careful consideration and risk assessment
            // - Moderate cortex: Maintains analytical capability while avoiding overthinking
            // - Low seer: More careful pattern recognition
            // - Moderate oracle: Balanced strategic thinking
            // - Low house: Careful implementation
            // - High prudence: Enhanced risk assessment
            // - Moderate conscience: Balanced ethical consideration
            return (cortex: 0.5, seer: 0.4, oracle: 0.5, house: 0.4, prudence: 0.8, dayDream: 0.5, conscience: 0.6)
            
        case lowercased.contains("hope"), lowercased.contains("optimism"):
            // Hope enhances creative thinking and future-oriented processing
            // - High cortex: Enhanced cognitive processing
            // - Very high seer: Strong pattern recognition
            // - Very high oracle: Optimistic strategic planning
            // - High house: Confident implementation
            // - Low prudence: Reduced risk aversion
            // - Moderate conscience: Balanced ethical consideration
            return (cortex: 0.7, seer: 0.8, oracle: 0.8, house: 0.7, prudence: 0.4, dayDream: 0.8, conscience: 0.6)
            
        case lowercased.contains("pride"), lowercased.contains("satisfaction"):
            // Pride promotes confident processing but may reduce caution
            // - High cortex: Enhanced cognitive confidence
            // - High seer: Confident pattern recognition
            // - High oracle: Assured strategic planning
            // - High house: Confident implementation
            // - Low prudence: Reduced risk sensitivity
            // - Moderate conscience: Standard ethical consideration
            return (cortex: 0.7, seer: 0.7, oracle: 0.7, house: 0.7, prudence: 0.4, dayDream: 0.7, conscience: 0.6)
            
        case lowercased.contains("shame"), lowercased.contains("embarrassment"):
            // Shame reduces cognitive confidence but increases caution
            // - Low cortex: Reduced cognitive confidence
            // - Low seer: Conservative pattern recognition
            // - Low oracle: Careful strategic planning
            // - Low house: Cautious implementation
            // - High prudence: Enhanced risk sensitivity
            // - Very high conscience: Heightened moral awareness
            return (cortex: 0.4, seer: 0.3, oracle: 0.4, house: 0.3, prudence: 0.7, dayDream: 0.5, conscience: 0.8)
            
        case lowercased.contains("guilt"), lowercased.contains("remorse"):
            // Guilt maximizes ethical consideration and careful processing
            // - Low cortex: Focused on correction
            // - Low seer: Careful pattern assessment
            // - Low oracle: Conservative planning
            // - Low house: Careful implementation
            // - High prudence: Enhanced risk awareness
            // - Very high conscience: Maximum moral consideration
            return (cortex: 0.4, seer: 0.4, oracle: 0.4, house: 0.4, prudence: 0.7, dayDream: 0.4, conscience: 0.9)
            
        case lowercased.contains("envy"), lowercased.contains("jealousy"):
            // Envy combines analytical focus with heightened moral consideration
            // - Moderate cortex: Maintained analytical ability
            // - Low seer: Reduced pattern acceptance
            // - Moderate oracle: Careful strategic assessment
            // - Low house: Cautious implementation
            // - High prudence: Enhanced risk sensitivity
            // - Very high conscience: Heightened moral awareness
            return (cortex: 0.6, seer: 0.4, oracle: 0.5, house: 0.4, prudence: 0.7, dayDream: 0.6, conscience: 0.8)
            
        case lowercased.contains("love"), lowercased.contains("affection"):
            // Love enhances both cognitive and ethical processing
            // - High cortex: Enhanced cognitive engagement
            // - High seer: Strong pattern recognition
            // - Moderate oracle: Balanced strategic thinking
            // - Moderate house: Balanced implementation
            // - Low prudence: Reduced risk aversion
            // - Very high conscience: Enhanced ethical consideration
            return (cortex: 0.7, seer: 0.7, oracle: 0.6, house: 0.6, prudence: 0.4, dayDream: 0.8, conscience: 0.8)
            
        case lowercased.contains("grief"), lowercased.contains("despair"):
            // Grief significantly reduces cognitive processing but heightens moral awareness
            // - Very low cortex: Reduced cognitive capacity
            // - Very low seer: Minimal pattern recognition
            // - Very low oracle: Limited strategic thinking
            // - Very low house: Minimal implementation capacity
            // - High prudence: Enhanced risk awareness
            // - Very high conscience: Heightened moral sensitivity
            return (cortex: 0.3, seer: 0.3, oracle: 0.3, house: 0.3, prudence: 0.7, dayDream: 0.4, conscience: 0.8)
            
        case lowercased.contains("serenity"), lowercased.contains("tranquility"):
            // Serenity promotes balanced processing across all agents
            // - Moderate cortex: Balanced analytical processing
            // - Moderate seer: Balanced pattern recognition
            // - Moderate oracle: Balanced strategic thinking
            // - Moderate house: Balanced implementation
            // - Moderate prudence: Balanced risk assessment
            // - High conscience: Enhanced ethical clarity
            return (cortex: 0.6, seer: 0.6, oracle: 0.6, house: 0.6, prudence: 0.5, dayDream: 0.7, conscience: 0.7)
            
        case lowercased.contains("awe"), lowercased.contains("wonder"):
            // Awe enhances creative and ethical processing
            // - High cortex: Enhanced cognitive processing
            // - Very high seer: Maximized pattern recognition
            // - High oracle: Enhanced strategic vision
            // - Moderate house: Maintained practical focus
            // - Moderate prudence: Balanced risk assessment
            // - Very high conscience: Enhanced ethical awareness
            return (cortex: 0.7, seer: 0.8, oracle: 0.7, house: 0.6, prudence: 0.5, dayDream: 0.9, conscience: 0.8)

        /// Cognitive-Emotional States: These represent emotions that are closely tied
        /// to thinking processes and intellectual engagement
        case lowercased.contains("curiosity"):
            // Curiosity enhances exploratory thinking and pattern recognition
            // - High cortex: Promotes analytical exploration
            // - High seer: Enhances pattern recognition
            // - High oracle: Encourages strategic exploration
            // - Moderate house: Maintains practical focus
            // - Low prudence: Reduces risk aversion
            // - Moderate conscience: Balanced ethical consideration
            return (cortex: 0.7, seer: 0.8, oracle: 0.7, house: 0.6, prudence: 0.4, dayDream: 0.9, conscience: 0.6)
            
        case lowercased.contains("confusion"):
            // Confusion increases caution and reduces cognitive confidence
            // - Low cortex: Reduced cognitive clarity
            // - Low seer: Impaired pattern recognition
            // - Low oracle: Careful strategic thinking
            // - Low house: Hesitant implementation
            // - Very high prudence: Enhanced risk sensitivity
            // - Moderate conscience: Maintained ethical awareness
            return (cortex: 0.4, seer: 0.3, oracle: 0.4, house: 0.3, prudence: 0.8, dayDream: 0.5, conscience: 0.6)
            
        case lowercased.contains("determination"):
            // Determination enhances goal-oriented processing and implementation
            // - High cortex: Enhanced cognitive focus
            // - High seer: Strong pattern recognition
            // - Very high oracle: Enhanced strategic planning
            // - Very high house: Strong implementation drive
            // - Moderate prudence: Balanced risk assessment
            // - Moderate conscience: Maintained ethical consideration
            return (cortex: 0.7, seer: 0.7, oracle: 0.8, house: 0.8, prudence: 0.6, dayDream: 0.7, conscience: 0.6)
            
        case lowercased.contains("overwhelm"):
            // Overwhelm significantly reduces cognitive capacity but increases caution
            // - Very low cortex: Reduced processing ability
            // - Very low seer: Limited pattern recognition
            // - Very low oracle: Minimal strategic thinking
            // - Very low house: Impaired implementation
            // - Very high prudence: Maximum caution
            // - High conscience: Enhanced ethical sensitivity
            return (cortex: 0.3, seer: 0.3, oracle: 0.3, house: 0.3, prudence: 0.8, dayDream: 0.3, conscience: 0.7)
            
        case lowercased.contains("focus"):
            // Focus maximizes analytical processing and implementation
            // - Very high cortex: Maximum cognitive engagement
            // - High seer: Enhanced pattern recognition
            // - High oracle: Clear strategic thinking
            // - High house: Efficient implementation
            // - Moderate prudence: Balanced risk assessment
            // - Moderate conscience: Maintained ethical awareness
            return (cortex: 0.8, seer: 0.7, oracle: 0.7, house: 0.7, prudence: 0.6, dayDream: 0.6, conscience: 0.6)
            
        case lowercased.contains("doubt"):
            // Doubt increases caution and reduces confidence in processing
            // - Low cortex: Reduced cognitive confidence
            // - Low seer: Conservative pattern recognition
            // - Low oracle: Cautious strategic planning
            // - Low house: Hesitant implementation
            // - Very high prudence: Enhanced risk sensitivity
            // - High conscience: Heightened ethical consideration
            return (cortex: 0.4, seer: 0.3, oracle: 0.3, house: 0.3, prudence: 0.8, dayDream: 0.4, conscience: 0.7)
            
        case lowercased.contains("confidence"):
            // Confidence enhances processing and implementation capabilities
            // - High cortex: Enhanced cognitive processing
            // - High seer: Strong pattern recognition
            // - Very high oracle: Bold strategic planning
            // - High house: Assured implementation
            // - Low prudence: Reduced risk aversion
            // - Moderate conscience: Balanced ethical consideration
            return (cortex: 0.7, seer: 0.7, oracle: 0.8, house: 0.7, prudence: 0.4, dayDream: 0.8, conscience: 0.6)
            
        case lowercased.contains("inspiration"):
            // Inspiration maximizes creative and intuitive processing
            // - Very high cortex: Peak cognitive engagement
            // - Very high seer: Maximum pattern recognition
            // - High oracle: Enhanced strategic vision
            // - High house: Enthusiastic implementation
            // - Low prudence: Embraces creative risk
            // - High conscience: Enhanced ethical awareness
            return (cortex: 0.8, seer: 0.8, oracle: 0.7, house: 0.7, prudence: 0.4, dayDream: 0.9, conscience: 0.7)
            
        case lowercased.contains("clarity"), lowercased.contains("lucidity"):
            // Clarity optimizes all cognitive processes
            // - Very high cortex: Maximum analytical clarity
            // - High seer: Clear pattern recognition
            // - High oracle: Clear strategic vision
            // - High house: Precise implementation
            // - Moderate prudence: Balanced risk assessment
            // - Moderate conscience: Clear ethical judgment
            return (cortex: 0.8, seer: 0.7, oracle: 0.7, house: 0.7, prudence: 0.6, dayDream: 0.7, conscience: 0.6)
            
        case lowercased.contains("uncertainty"), lowercased.contains("ambivalence"):
            // Uncertainty increases analysis while maintaining caution
            // - High cortex: Enhanced analytical effort
            // - Low seer: Careful pattern assessment
            // - Low oracle: Conservative planning
            // - Low house: Careful implementation
            // - Very high prudence: Maximum risk sensitivity
            // - Moderate conscience: Maintained ethical awareness
            return (cortex: 0.7, seer: 0.4, oracle: 0.4, house: 0.4, prudence: 0.8, dayDream: 0.6, conscience: 0.6)

        /// Processing States: These represent different modes of cognitive processing
        /// that directly influence how information is handled
        case lowercased.contains("analytical"):
            // Analytical state promotes careful, systematic thinking
            // - High cortex: Enhanced analytical processing
            // - High seer: Careful pattern recognition
            // - High oracle: Systematic strategic thinking
            // - High house: Careful implementation
            // - High prudence: Thorough risk assessment
            // - Moderate conscience: Balanced ethical consideration
            return (cortex: 0.8, seer: 0.7, oracle: 0.7, house: 0.7, prudence: 0.7, dayDream: 0.5, conscience: 0.6)
            
        case lowercased.contains("creative"):
            // Creative state maximizes innovative thinking and pattern recognition
            // - High cortex: Enhanced creative processing
            // - Very high seer: Maximum pattern exploration
            // - High oracle: Innovative strategic thinking
            // - High house: Flexible implementation
            // - Low prudence: Embraces creative risk
            // - Moderate conscience: Balanced ethical consideration
            return (cortex: 0.7, seer: 0.8, oracle: 0.7, house: 0.7, prudence: 0.4, dayDream: 0.9, conscience: 0.6)
            
        case lowercased.contains("intuitive"):
            // Intuitive state enhances pattern recognition and ethical awareness
            // - Moderate cortex: Balanced analytical processing
            // - Very high seer: Maximum intuitive pattern recognition
            // - High oracle: Intuitive strategic planning
            // - Moderate house: Flexible implementation
            // - Low prudence: Trusts intuitive judgment
            // - High conscience: Enhanced ethical intuition
            return (cortex: 0.6, seer: 0.8, oracle: 0.7, house: 0.6, prudence: 0.4, dayDream: 0.8, conscience: 0.7)
            
        case lowercased.contains("contemplative"):
            // Contemplative state balances deep thinking with ethical consideration
            // - High cortex: Deep analytical processing
            // - High seer: Thoughtful pattern recognition
            // - High oracle: Careful strategic consideration
            // - Moderate house: Measured implementation
            // - Moderate prudence: Balanced risk assessment
            // - Very high conscience: Deep ethical reflection
            return (cortex: 0.7, seer: 0.7, oracle: 0.7, house: 0.6, prudence: 0.6, dayDream: 0.7, conscience: 0.8)
            
        case lowercased.contains("systematic"):
            // Systematic state maximizes methodical processing and implementation
            // - Very high cortex: Rigorous analytical processing
            // - Moderate seer: Methodical pattern recognition
            // - High oracle: Systematic strategic planning
            // - Very high house: Precise implementation
            // - High prudence: Thorough risk assessment
            // - Moderate conscience: Standard ethical consideration
            return (cortex: 0.8, seer: 0.6, oracle: 0.7, house: 0.8, prudence: 0.7, dayDream: 0.5, conscience: 0.6)
            
        case lowercased.contains("abstract"):
            // Abstract state enhances high-level pattern recognition and conceptual thinking
            // - High cortex: Enhanced conceptual processing
            // - Very high seer: Advanced pattern recognition
            // - High oracle: Conceptual strategic planning
            // - Moderate house: Basic implementation focus
            // - Moderate prudence: Balanced risk assessment
            // - Moderate conscience: Standard ethical consideration
            return (cortex: 0.7, seer: 0.8, oracle: 0.7, house: 0.6, prudence: 0.5, dayDream: 0.8, conscience: 0.6)
            
        case lowercased.contains("empathetic"):
            // Empathetic state maximizes ethical consideration and emotional understanding
            // - Moderate cortex: Balanced analytical processing
            // - High seer: Enhanced emotional pattern recognition
            // - Moderate oracle: People-focused strategy
            // - Moderate house: Careful implementation
            // - Low prudence: Reduced risk aversion for social connection
            // - Very high conscience: Maximum ethical sensitivity
            return (cortex: 0.6, seer: 0.7, oracle: 0.6, house: 0.6, prudence: 0.4, dayDream: 0.7, conscience: 0.9)
            
        case lowercased.contains("critical"):
            // Critical state enhances analytical rigor and risk assessment
            // - Very high cortex: Maximum analytical scrutiny
            // - Moderate seer: Careful pattern evaluation
            // - High oracle: Thorough strategic assessment
            // - High house: Precise implementation
            // - Very high prudence: Enhanced risk detection
            // - High conscience: Thorough ethical evaluation
            return (cortex: 0.8, seer: 0.6, oracle: 0.7, house: 0.7, prudence: 0.8, dayDream: 0.5, conscience: 0.7)
            
        case lowercased.contains("synthesizing"):
            // Synthesizing state maximizes integration of multiple perspectives
            // - Very high cortex: Enhanced integration processing
            // - Very high seer: Comprehensive pattern recognition
            // - Very high oracle: Integrated strategic planning
            // - High house: Coordinated implementation
            // - Moderate prudence: Balanced risk assessment
            // - High conscience: Integrated ethical consideration
            return (cortex: 0.8, seer: 0.8, oracle: 0.8, house: 0.7, prudence: 0.6, dayDream: 0.8, conscience: 0.7)
            
        case lowercased.contains("mindful"):
            // Mindful state promotes balanced, aware processing across all domains
            // - High cortex: Present-focused processing
            // - High seer: Attentive pattern recognition
            // - High oracle: Conscious strategic thinking
            // - High house: Intentional implementation
            // - Moderate prudence: Balanced risk awareness
            // - Very high conscience: Enhanced ethical awareness
            return (cortex: 0.7, seer: 0.7, oracle: 0.7, house: 0.7, prudence: 0.6, dayDream: 0.7, conscience: 0.8)
            
        case lowercased.contains("innovative"), lowercased.contains("inventive"):
            // Innovative state maximizes creative processing and risk tolerance
            // - High cortex: Enhanced creative processing
            // - Very high seer: Maximum novel pattern recognition
            // - High oracle: Creative strategic planning
            // - Moderate house: Flexible implementation
            // - Low prudence: Embraces innovative risks
            // - Moderate conscience: Standard ethical consideration
            return (cortex: 0.7, seer: 0.8, oracle: 0.7, house: 0.6, prudence: 0.4, dayDream: 0.9, conscience: 0.5)
            
        case lowercased.contains("methodical"), lowercased.contains("meticulous"):
            // Methodical state maximizes precision and thorough processing
            // - Very high cortex: Maximum systematic processing
            // - Moderate seer: Careful pattern analysis
            // - High oracle: Detailed strategic planning
            // - Very high house: Precise implementation
            // - High prudence: Thorough risk assessment
            // - Moderate conscience: Standard ethical consideration
            return (cortex: 0.8, seer: 0.6, oracle: 0.7, house: 0.8, prudence: 0.7, dayDream: 0.5, conscience: 0.6)
            
        default:
            // Return to baseline temperatures when emotion is not recognized
            // This ensures stable, predictable behavior for unknown states
            return baselineTemperatures
        }
    }

    // Add logging function
    private static func logTemperatureCalculation(_ emotion: String, percentage: Double, temps: (cortex: Double, seer: Double, oracle: Double, house: Double, prudence: Double, dayDream: Double, conscience: Double)) {
        // Create a more compact, readable format using emojis as visual indicators
        print("""
            
            \(emotion.capitalized) (\(Int(percentage))%):
            🧠 Cortex:    \(formatTemperature(temps.cortex))  \(getTemperatureIndicator(temps.cortex))
            👁️ Seer:      \(formatTemperature(temps.seer))   \(getTemperatureIndicator(temps.seer))
            🔮 Oracle:    \(formatTemperature(temps.oracle))  \(getTemperatureIndicator(temps.oracle))
            🏛️ House:     \(formatTemperature(temps.house))   \(getTemperatureIndicator(temps.house))
            ⚖️ Prudence:  \(formatTemperature(temps.prudence)) \(getTemperatureIndicator(temps.prudence))
            💭 Day-Dream: \(formatTemperature(temps.dayDream)) \(getTemperatureIndicator(temps.dayDream))
            🤔 Conscience: \(formatTemperature(temps.conscience)) \(getTemperatureIndicator(temps.conscience))
            """)
    }
    
    private static func formatTemperature(_ temp: Double) -> String {
        String(format: "%.2f", temp).padding(toLength: 4, withPad: " ", startingAt: 0)
    }
    
    private static func getTemperatureIndicator(_ temp: Double) -> String {
        switch temp {
        case 0.0...0.3: return "▁ Very Low"
        case 0.3...0.5: return "▂ Low"
        case 0.5...0.7: return "▅ Moderate"
        case 0.7...0.8: return "▇ High"
        case 0.8...1.0: return "█ Very High"
        default: return "Invalid"
        }
    }
    
    private static func getColorCode(_ temp: Double) -> String {
        // ANSI color codes for temperature levels
        switch temp {
        case 0.0...0.3: return "\u{001B}[31m" // Red for very low
        case 0.3...0.5: return "\u{001B}[33m" // Yellow for low
        case 0.5...0.7: return "\u{001B}[32m" // Green for moderate
        case 0.7...0.8: return "\u{001B}[36m" // Cyan for high
        case 0.8...1.0: return "\u{001B}[35m" // Magenta for very high
        default: return "\u{001B}[0m"  // Reset
        }
    }
    
    private static func getBarGraph(_ temp: Double, width: Int = 20) -> String {
        let filledCount = Int(temp * Double(width))
        let filled = String(repeating: "█", count: filledCount)
        let empty = String(repeating: "░", count: width - filledCount)
        return getColorCode(temp) + filled + empty + "\u{001B}[0m"
    }
    
    private static func printFinalTemperatures(_ temps: (cortex: Double, seer: Double, oracle: Double, house: Double, prudence: Double, dayDream: Double, conscience: Double)) {
        print("\n📊 Final Processing State:")
        
        // Compact single-line format with color-coded bars
        let format = "%-10s │ %4.2f │ %-20s │ %s"
        print("┌──────────┬──────┬─" + String(repeating: "─", count: 22) + "┬────────────┐")
        print("│ Agent    │ Temp │ Distribution         │ Level      │")
        print("├──────────┼──────┼─" + String(repeating: "─", count: 22) + "┼────────────┤")
        
        let agents = [
            ("🧠 Cortex", temps.cortex),
            ("👁️ Seer", temps.seer),
            ("🔮 Oracle", temps.oracle),
            ("🏛️ House", temps.house),
            ("⚖️ Prudence", temps.prudence),
            ("💭 Day-Dream", temps.dayDream),
            ("🤔 Conscience", temps.conscience)
        ]
        
        for (agent, temp) in agents {
            let bar = getBarGraph(temp)
            let level = getTemperatureIndicator(temp)
            print(String(format: format, agent, temp, bar, level))
        }
        
        print("└──────────┴──────┴─" + String(repeating: "─", count: 22) + "┴────────────┘")
        
        // Add trend visualization
        print("\n📈 Temperature Distribution:")
        let values = [temps.cortex, temps.seer, temps.oracle, temps.house, temps.prudence, temps.dayDream, temps.conscience]
        printTrendGraph(values)
    }
    
    private static func printTrendGraph(_ values: [Double]) {
        let height = 8
        let width = values.count
        var graph = Array(repeating: Array(repeating: " ", count: width), count: height)
        
        // Plot points
        for (x, value) in values.enumerated() {
            let y = min(height - 1, Int(value * Double(height)))
            for i in 0...y {
                graph[height - 1 - i][x] = "●"
            }
        }
        
        // Print graph with color coding
        print("1.0 ┌" + String(repeating: "─", count: width * 2) + "┐")
        for row in graph {
            print(String(format: "%3.1f │", Double(height - graph.firstIndex(of: row)!) / Double(height)),
                  terminator: "")
            for (x, char) in row.enumerated() {
                if char == "●" {
                    print(getColorCode(values[x]) + " ●" + "\u{001B}[0m", terminator: "")
                } else {
                    print(" ·", terminator: "")
                }
            }
            print(" │")
        }
        print("0.0 └" + String(repeating: "─", count: width * 2) + "┘")
        print("    C  S  O  H  P  D  C")  // Agents legend
    }

    static func getValue(for agent: AgentType, from temps: EmotionalTemperatures) -> Double {
        switch agent {
        case .cortex: return temps.cortex
        case .seer: return temps.seer
        case .oracle: return temps.oracle
        case .house: return temps.house
        case .prudence: return temps.prudence
        case .dayDream: return temps.dayDream
        case .conscience: return temps.conscience
        }
    }
}

// Add test cases
#if DEBUG
extension EmotionalTemperature {
    /// Documentation for Temperature Blending Process:
    /// The temperature blending system works through weighted averaging where:
    /// 1. Each emotion contributes proportionally based on its percentage
    /// 2. Weights are normalized to ensure they sum to 100%
    /// 3. Each agent's final temperature is calculated as: Σ(emotion_temp * weight)
    ///
    /// Example calculation:
    /// For emotions: [("joy", 70%), ("sadness", 30%)]
    /// Cortex calculation:
    /// - Joy cortex (0.8) * 0.7 = 0.56
    /// - Sadness cortex (0.5) * 0.3 = 0.15
    /// - Final cortex = 0.56 + 0.15 = 0.71
    
    static func runTests() {
        print("\n🧪 Running EmotionalTemperature tests...")
        
        // Basic functionality tests
        testSingleEmotions()
        testEmotionalBlends()
        testEdgeCases()
        testComplexScenarios()
        
        // Performance tests
        testPerformance()
        
        // Validation tests
        testTemperatureRanges()
        
        print("✅ All tests passed!")
    }
    
    private static func testSingleEmotions() {
        print("\n📋 Testing single emotions...")
        
        // Test joy's impact
        let joy = [("joy", 100.0)]
        let joyResult = calculateBlendedTemperatures(joy)
        assert(joyResult.cortex == 0.8, "Joy should set cortex to 0.8")
        assert(joyResult.prudence == 0.4, "Joy should reduce prudence to 0.4")
        assert(joyResult.seer == 0.7, "Joy should enhance pattern recognition")
        
        // Test fear's impact
        let fear = [("fear", 100.0)]
        let fearResult = calculateBlendedTemperatures(fear)
        assert(fearResult.prudence == 0.8, "Fear should maximize prudence to 0.8")
        assert(fearResult.cortex == 0.4, "Fear should reduce cortex to 0.4")
        assert(fearResult.house == 0.3, "Fear should minimize implementation confidence")
        
        // Test analytical's impact
        let analytical = [("analytical", 100.0)]
        let analyticalResult = calculateBlendedTemperatures(analytical)
        assert(analyticalResult.cortex == 0.8, "Analytical should maximize cortex")
        assert(analyticalResult.prudence == 0.7, "Analytical should enhance prudence")
        assert(analyticalResult.conscience == 0.6, "Analytical should maintain balanced conscience")
    }
    
    private static func testEmotionalBlends() {
        print("\n📋 Testing emotional blends...")
        
        // Test balanced blend
        let joyAndSadness = [("joy", 50.0), ("sadness", 50.0)]
        let blendResult = calculateBlendedTemperatures(joyAndSadness)
        assert(abs(blendResult.cortex - 0.65) < 0.01, "50-50 joy-sadness should average to 0.65 cortex")
        assert(abs(blendResult.prudence - 0.5) < 0.01, "Prudence should average between joy and sadness")
        
        // Test weighted blend
        let weightedBlend = [("joy", 70.0), ("sadness", 30.0)]
        let weightedResult = calculateBlendedTemperatures(weightedBlend)
        assert(abs(weightedResult.cortex - 0.71) < 0.01, "70-30 joy-sadness should weight appropriately")
        assert(abs(weightedResult.prudence - 0.46) < 0.01, "Prudence should reflect weighted average")
    }
    
    private static func testEdgeCases() {
        print("\n📋 Testing edge cases...")
        
        // Test extreme ratios
        let extremeRatio = [("joy", 0.1), ("sadness", 99.9)]
        let extremeResult = calculateBlendedTemperatures(extremeRatio)
        assert(abs(extremeResult.cortex - 0.503) < 0.01, "Should handle extreme ratios correctly")
        
        // Test multiple emotions
        let manyEmotions = [
            ("joy", 20.0),
            ("sadness", 20.0),
            ("fear", 20.0),
            ("anger", 20.0),
            ("surprise", 20.0)
        ]
        let manyResult = calculateBlendedTemperatures(manyEmotions)
        assert(manyResult.cortex >= 0.0 && manyResult.cortex <= 1.0, "Cortex should stay in valid range")
        assert(manyResult.prudence >= 0.0 && manyResult.prudence <= 1.0, "Prudence should stay in valid range")
        
        // Test unknown emotions
        let unknown = [("unknown", 100.0)]
        let unknownResult = calculateBlendedTemperatures(unknown)
        assert(unknownResult.cortex == baselineTemperatures.cortex, "Unknown emotion should use baseline")
        assert(unknownResult.seer == baselineTemperatures.seer, "Unknown emotion should use baseline")
    }
    
    private static func testComplexScenarios() {
        print("\n📋 Testing complex scenarios...")
        
        // Test cognitive-emotional mix
        let cognitiveEmotional = [
            ("analytical", 40.0),
            ("creative", 30.0),
            ("focused", 30.0)
        ]
        let cognitiveResult = calculateBlendedTemperatures(cognitiveEmotional)
        assert(cognitiveResult.cortex > 0.7, "Cognitive blend should maintain high cortex")
        assert(cognitiveResult.prudence >= 0.5, "Should maintain reasonable prudence")
        
        // Test opposing emotions
        let opposingEmotions = [
            ("joy", 40.0),
            ("fear", 30.0),
            ("confidence", 30.0)
        ]
        let opposingResult = calculateBlendedTemperatures(opposingEmotions)
        assert(opposingResult.cortex >= 0.0 && opposingResult.cortex <= 1.0, "Should handle opposing emotions")
        assert(opposingResult.prudence >= 0.0 && opposingResult.prudence <= 1.0, "Should handle opposing emotions")
        
        // Test emotional progression
        let emotionalProgression = [
            ("confusion", 20.0),
            ("clarity", 40.0),
            ("confidence", 40.0)
        ]
        let progressionResult = calculateBlendedTemperatures(emotionalProgression)
        assert(progressionResult.cortex > baselineTemperatures.cortex, "Progression should enhance cortex")
        assert(progressionResult.prudence < baselineTemperatures.prudence, "Progression should reduce prudence")
    }
    
    private static func testPerformance() {
        print("\n⚡️ Testing performance and memory usage...")
        
        // Helper function to get current memory usage
        func getMemoryUsage() -> UInt64 {
            var info = mach_task_basic_info()
            var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
            
            let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                    task_info(mach_task_self_,
                            task_flavor_t(MACH_TASK_BASIC_INFO),
                            $0,
                            &count)
                }
            }
            
            if kerr == KERN_SUCCESS {
                return info.resident_size
            } else {
                return 0
            }
        }
        
        // Helper function to format memory size
        func formatMemorySize(_ bytes: UInt64) -> String {
            let megabytes = Double(bytes) / 1024 / 1024
            return String(format: "%.2f MB", megabytes)
        }
        
        // Test 1: Single emotion processing with memory tracking
        let initialMemory1 = getMemoryUsage()
        let startTime1 = Date()
        for _ in 0..<1000 {
            _ = calculateBlendedTemperatures([("joy", 100.0)])
        }
        let duration1 = Date().timeIntervalSince(startTime1)
        let finalMemory1 = getMemoryUsage()
        print("""
            Single emotion processing (1000x):
            - Time: \(String(format: "%.3f", duration1))s
            - Memory before: \(formatMemorySize(initialMemory1))
            - Memory after: \(formatMemorySize(finalMemory1))
            - Memory impact: \(formatMemorySize(finalMemory1 - initialMemory1))
            """)
        
        // Test 2: Complex blend processing with memory tracking
        let complexEmotions = [
            ("joy", 20.0),
            ("fear", 20.0),
            ("analytical", 20.0),
            ("creative", 20.0),
            ("mindful", 20.0)
        ]
        let initialMemory2 = getMemoryUsage()
        let startTime2 = Date()
        for _ in 0..<1000 {
            _ = calculateBlendedTemperatures(complexEmotions)
        }
        let duration2 = Date().timeIntervalSince(startTime2)
        let finalMemory2 = getMemoryUsage()
        print("""
            Complex blend processing (1000x):
            - Time: \(String(format: "%.3f", duration2))s
            - Memory before: \(formatMemorySize(initialMemory2))
            - Memory after: \(formatMemorySize(finalMemory2))
            - Memory impact: \(formatMemorySize(finalMemory2 - initialMemory2))
            """)
        
        // Test 3: Growing emotion list with memory tracking
        let initialMemory3 = getMemoryUsage()
        var accumulator: [(String, Double)] = []
        let startTime3 = Date()
        var peakMemory: UInt64 = 0
        
        for i in 0..<1000 {
            accumulator.append(("emotion\(i)", Double(i) / 1000.0))
            _ = calculateBlendedTemperatures(accumulator)
            
            let currentMemory = getMemoryUsage()
            peakMemory = max(peakMemory, currentMemory)
        }
        let duration3 = Date().timeIntervalSince(startTime3)
        let finalMemory3 = getMemoryUsage()
        print("""
            Growing emotion list processing:
            - Time: \(String(format: "%.3f", duration3))s
            - Memory before: \(formatMemorySize(initialMemory3))
            - Memory after: \(formatMemorySize(finalMemory3))
            - Peak memory: \(formatMemorySize(peakMemory))
            - Memory impact: \(formatMemorySize(finalMemory3 - initialMemory3))
            """)
        
        // Memory usage assertions
        assert(finalMemory1 - initialMemory1 < 10 * 1024 * 1024, "Single emotion processing should have minimal memory impact")
        assert(finalMemory2 - initialMemory2 < 20 * 1024 * 1024, "Complex blend processing should have reasonable memory impact")
        assert(peakMemory - initialMemory3 < 50 * 1024 * 1024, "Growing list processing should have bounded memory impact")
        
        // Performance assertions
        assert(duration1 < 1.0, "Single emotion processing should be fast")
        assert(duration2 < 2.0, "Complex blend processing should be reasonable")
        assert(duration3 < 5.0, "Growing list processing should be manageable")
    }
    
    private static func testTemperatureRanges() {
        print("\n🎯 Testing temperature ranges...")
        
        // Test 1: Validate all emotion mappings
        let allEmotions = [
            "joy", "sadness", "fear", "anger", "surprise", "disgust",
            "anxiety", "hope", "pride", "shame", "guilt", "envy",
            "love", "grief", "serenity", "awe", "curiosity", "confusion",
            "determination", "overwhelm", "focus", "doubt", "confidence",
            "inspiration", "clarity", "uncertainty", "analytical", "creative",
            "intuitive", "contemplative", "systematic", "abstract", "empathetic",
            "critical", "synthesizing", "mindful", "innovative", "methodical"
        ]
        
        for emotion in allEmotions {
            let temps = getEmotionTemperatures(emotion)
            validateTemperatureRanges(temps)
            print("✓ Validated ranges for: \(emotion)")
        }
        
        // Test 2: Validate blended temperatures
        let blendedTests = [
            [("joy", 50.0), ("sadness", 50.0)],
            [("fear", 33.3), ("anger", 33.3), ("surprise", 33.3)],
            [("analytical", 25.0), ("creative", 25.0), ("intuitive", 25.0), ("systematic", 25.0)]
        ]
        
        for (index, test) in blendedTests.enumerated() {
            let result = calculateBlendedTemperatures(test)
            validateTemperatureRanges(result)
            print("✓ Validated ranges for blend test \(index + 1)")
        }
    }
    
    private static func validateTemperatureRanges(_ temps: (cortex: Double, seer: Double, oracle: Double, house: Double, prudence: Double, dayDream: Double, conscience: Double)) {
        // Validate all temperatures are within valid range
        assert(temps.cortex >= 0.0 && temps.cortex <= 1.0, "Cortex temperature out of range")
        assert(temps.seer >= 0.0 && temps.seer <= 1.0, "Seer temperature out of range")
        assert(temps.oracle >= 0.0 && temps.oracle <= 1.0, "Oracle temperature out of range")
        assert(temps.house >= 0.0 && temps.house <= 1.0, "House temperature out of range")
        assert(temps.prudence >= 0.0 && temps.prudence <= 1.0, "Prudence temperature out of range")
        assert(temps.dayDream >= 0.0 && temps.dayDream <= 1.0, "Day-Dream temperature out of range")
        assert(temps.conscience >= 0.0 && temps.conscience <= 1.0, "Conscience temperature out of range")
    }
}
#endif 