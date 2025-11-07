# AI Hotkey

AI Hotkey is a macOS background application that enhances productivity by integrating AI-powered text processing via global hotkeys. The app runs quietly in the menu bar, allowing seamless AI interactions directly in any application.

## Features

- **Global Hotkeys**: Trigger AI processing system-wide with customizable keyboard shortcuts
- **Multiple Workflows**: Create different AI tasks with custom prompts and models
- **OpenRouter Integration**: Supports various AI models through OpenRouter API
- **Flexible Output**: Choose between pasting results in-place or displaying in a popup banner
- **Background Operation**: Runs invisibly in the menu bar without cluttering the Dock
- **Persistent Settings**: Workflows and API keys are saved automatically

## Requirements

- macOS 12.0 or later
- OpenRouter API key (get one at [openrouter.ai](https://openrouter.ai))
- Accessibility permissions (granted automatically on first run)

## Installation & Setup

1. **Clone or download** the project
2. **Build the app**:
   ```bash
   swift build
   ```
3. **Run in background**:
   ```bash
   ./.build/debug/InplaceAI &
   ```

The app will appear in your menu bar as a brain icon.

## Configuration

1. Click the menu bar icon and select "Settings"
2. Enter your OpenRouter API key
3. Create workflows:
   - Choose an AI model
   - Write a custom prompt (use `{text}` placeholder for selected text)
   - Set hotkeys (primary + optional alternatives)
   - Select output method (Paste in Place or Banner)

## Usage

1. Select text in any application
2. Press your configured hotkey
3. The menu bar icon will show a spinner during processing
4. AI response will be pasted or displayed according to your workflow settings

## Permissions

The app requires Accessibility permissions to:
- Monitor global keyboard shortcuts
- Simulate Cmd+C/Cmd+V for text manipulation

Grant permissions in System Preferences > Security & Privacy > Privacy > Accessibility when prompted.

## Logging

View logs by selecting "View Log" from the menu bar icon. This opens Console.app where you can filter logs by subsystem `com.inplaceai.InplaceAI`.

## Troubleshooting

- **Hotkeys not working**: Ensure Accessibility permissions are granted
- **API errors**: Check your OpenRouter API key and internet connection
- **App not responding**: Restart the app or check Console.app for error logs

## Development

Built with Swift using SwiftUI and AppKit. Uses modern async/await for API calls and structured logging.
