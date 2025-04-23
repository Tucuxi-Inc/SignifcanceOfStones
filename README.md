# Significance Of Stones

A multi-agent AI conversation system that simulates a cognitive architecture with specialized agents working together to provide thoughtful, balanced responses.

## Overview

Significance Of Stones implements a "mind system" architecture where different cognitive agents collaborate to process user input:

- **Cortex Agent**: Handles emotional processing and basic meaning analysis
- **Seer Agent**: Focuses on pattern recognition and prediction
- **Oracle Agent**: Manages strategic planning and probability analysis
- **House Agent**: Evaluates practical considerations and implementation details
- **Prudence Agent**: Assesses risks and manages constraints
- **Conscience Agent**: Provides ethical oversight and moral considerations

These agents work sequentially to analyze input, with each agent building upon insights from previous agents. The system also tracks emotional states and dynamically adjusts response parameters based on the conversation context.

## Features

- **Multi-agent processing**: Input passes through specialized cognitive agents
- **Emotional state tracking**: System analyzes its own emotional and cognitive state
- **Dynamic temperature adjustment**: Response characteristics adapt based on conversation context
- **Conversation history awareness**: Responses consider recent exchanges
- **Detailed analysis storage**: Each processing step is recorded for transparency

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

## How It Works

1. User sends a message to the system
2. The Cortex agent analyzes emotional content
3. Each specialized agent processes the input sequentially
4. The system integrates responses from all agents
5. An emotional state analysis is performed
6. Agent temperature settings are adjusted based on the emotional state
7. The integrated response is returned to the user

## License

[Add your license information here]

## Acknowledgments

- OpenAI for providing the API that powers the cognitive processing
- [Add any other acknowledgments here] 