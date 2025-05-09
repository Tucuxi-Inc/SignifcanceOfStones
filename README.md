# Significance Of Stones

A multi-agent AI conversation system that simulates a cognitive architecture with specialized agents working together to provide thoughtful, balanced responses.

## Overview

Significance Of Stones implements a "mind system" architecture where different cognitive agents collaborate to process user input:

- **Cortex Agent**: Handles emotional processing and basic meaning analysis
- **Seer Agent**: Focuses on pattern recognition and prediction
- **Oracle Agent**: Manages strategic planning and probability analysis
- **House Agent**: Evaluates practical considerations and implementation details
- **Prudence Agent**: Assesses risks and manages constraints
- **Daydream Agent**: Explores associative connections and generates creative insights
- **Conscience Agent**: Provides ethical oversight and moral considerations

These agents work sequentially to analyze input, with each agent building upon insights from previous agents. The system also tracks emotional states and dynamically adjusts response parameters based on the conversation context.

## Features

- **Multi-agent processing**: Input passes through specialized cognitive agents
- **Emotional state tracking**: System analyzes its own emotional and cognitive state
- **Dynamic temperature adjustment**: Response characteristics adapt based on conversation context
- **Conversation history awareness**: Responses consider recent exchanges
- **Detailed analysis storage**: Each processing step is recorded for transparency
- **Emotional feedback loops**: The system's internal emotional state influences agent behavior
- **Real-time speech recognition**: Voice input with visual feedback during recording

## Requirements

- iOS 17.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later
- OpenAI API key

## Setup

### API Key Configuration

This application requires an OpenAI API key to function properly. For security reasons, the actual API key file is not included in the repository.

Follow these steps to set up your API key:

1. Sign up for an OpenAI account and obtain your API key at [OpenAI](https://platform.openai.com/)
2. Create a new file named `SignifcanceOfStones/Config/APIConfig.swift`
3. Copy the following code into the new file and replace the placeholder with your actual OpenAI API key

```swift
import Foundation

enum APIConfig {
    static let openAIKey = "YOUR_ACTUAL_OPENAI_API_KEY"
}
```

**IMPORTANT: Never commit your API key to version control. The `APIConfig.swift` file is included in `.gitignore` to prevent accidental commits.**

## Building and Running

1. Clone the repository
2. Set up your API key as described above
3. Open `SignifcanceOfStones.xcodeproj` in Xcode
4. Select your target device or simulator
5. Build and run the application (⌘+R)

## Architecture

The application is structured around these key components:

- **MindSystem**: Orchestrates the processing of user input through multiple agents
- **CognitiveAgent Protocol**: Defines the interface for all specialized agents
- **BaseAgent**: Implements common agent functionality
- **Specialized Agents**: Implement domain-specific processing logic
- **OpenAIService**: Handles API communication with OpenAI
- **EmotionalTemperature**: Manages temperature settings based on emotional state
- **SwiftData Integration**: Stores conversation history and processing analytics

## Emotional Context and Mental States

The Significance Of Stones app implements an innovative approach to understanding and utilizing emotional context within AI conversations:

### Daydream Agent

The Daydream agent enhances the mind system's cognitive architecture by:
- Exploring associative connections between current input and past exchanges
- Generating creative insights through metaphorical thinking and association
- Creating novel perspectives that complement logical analysis
- Operating with a dynamically adjusted higher temperature setting to encourage creativity
- Providing balance to the more analytical agents in the system

### Emotional Feedback Loops

The app features a sophisticated emotional feedback system:

1. **Emotional State Analysis**: After each conversation turn, the system analyzes its own internal emotional and cognitive state
2. **Dynamic Temperature Adjustment**: Agent parameters (temperature) automatically adjust based on the emotional state
3. **Emotional Presets**: Users can select from predefined emotional states like "Balanced Learning," "Creative Problem Solving," or "Empathetic Understanding"
4. **Custom Emotional Blends**: Advanced users can create custom emotional states by adjusting individual emotions and their intensities

### Visualization and Controls

Several specialized views help users understand and control the mind system:

1. **Agent Settings View**: Shows the current temperature of each agent and allows manual adjustment
2. **Emotional State Settings**: Displays current emotional state and allows selection of emotional presets
3. **Conversation Visualization**: Provides charts tracking emotional trends and temperature variations throughout conversations
4. **Processing Impact View**: Shows how each emotional state affects different agents' processing parameters
5. **Agent Responses View**: Displays raw responses from each agent for transparency and insight

### Mental State Inference

The system infers internal mental states through:

1. **Emotion Categories**: Tracking primary emotions, complex emotional states, cognitive-emotional blends, and processing states
2. **Adaptive Processing**: The Daydream agent receives higher temperature settings when curiosity, surprise, or creative states are high
3. **State Labeling**: The system identifies overall states like "Baseline Balance," "Emotionally Creative," or "Analytically Forward-Looking" based on agent parameters
4. **Processing Dynamics**: Temperature settings influence exploration vs. exploitation balance in responses

## How It Works

1. User sends a message to the system (text or speech)
2. The Cortex agent analyzes emotional content
3. Each specialized agent processes the input sequentially
4. The Daydream agent explores creative connections and metaphorical insights
5. The system integrates responses from all agents
6. An emotional state analysis is performed
7. Agent temperature settings are adjusted based on the emotional state
8. The integrated response is returned to the user

## License

Copyright 2025 Tucuxi, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Acknowledgments

- OpenAI for providing the API that powers the cognitive processing
- My wife, Diane, a licensed marriage and family therapist. Hours and hours of conversations about how humans process information and how emotion influences our perceptions and processing were the inspiration for this part of a much larger project to build systems that learn and think like us. 
