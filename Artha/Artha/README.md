# Nepali Voice Translator App

This iOS app records Nepali speech, transcribes it to text, and translates it to English using Google Cloud APIs.

## Features

- Voice recording with visual waveform feedback
- Speech-to-text conversion for Nepali (ne-NP)
- Text translation from Nepali to English
- Text input option for direct text translation
- Clean, intuitive UI with dark mode

## Setup Instructions

### Prerequisites

- Xcode 15.0 or later
- iOS 16.0 or later target device
- Google Cloud Platform account with Speech-to-Text and Translation APIs enabled
- Service account credentials for Google Cloud authentication

### Setting Up Google Cloud (DETAILED GUIDE)

1. Create a Google Cloud Platform account if you don't have one already
2. Go to the [Google Cloud Console](https://console.cloud.google.com/)
3. Create a new project or use the existing "psychic-karma-459822-q4" project
4. Enable required APIs:
   - In the left sidebar, go to "APIs & Services" > "Library"
   - Search for and enable "Cloud Speech-to-Text API"
   - Search for and enable "Cloud Translation API"
5. Create API key:
   - In the left sidebar, go to "APIs & Services" > "Credentials"
   - Click "CREATE CREDENTIALS" and select "API key"
   - Copy the generated API key
   - (Optional but recommended) Click "Restrict key" to limit its usage to only Speech-to-Text and Translation APIs
6. Update the app with your API key:
   - Open `NewInfo.plist` in Xcode
   - Find the key `GOOGLE_CLOUD_API_KEY` and replace `YOUR_GOOGLE_CLOUD_API_KEY_HERE` with your actual API key
   - Or, if you prefer using a service account instead of API key (more secure):
     - Create a service account in Google Cloud Console
     - Grant necessary permissions for Speech and Translation APIs
     - Create a key for this service account (JSON format)
     - Add the JSON file to your project as `google-credentials.json`

### Adding Service Account Credentials

1. Open the project in Xcode
2. Implement secure service account credential handling:
   - Option 1 (Development): Use the `GoogleCredentialsHelper.swift` class to load credentials
   - Option 2 (Production): Implement a backend service to handle authentication

### Troubleshooting API Key Issues

If you see "API key not valid" errors:

1. Make sure you've enabled the correct APIs (Speech-to-Text and Translation)
2. Verify the API key has been correctly copied to `NewInfo.plist`
3. Check that the API key is not restricted in a way that prevents these services
4. Try creating a new API key if issues persist
5. Billing: Ensure your Google Cloud account has billing enabled (required for these APIs)

### Required Dependencies

1. Add JWTKit for authentication token generation:
   - Go to File > Swift Packages > Add Package Dependency...
   - Enter: `https://github.com/vapor/jwt-kit.git`

## Implementation Details

### Audio Recording

The app uses `AVAudioRecorder` to capture audio from the device's microphone, storing it temporarily as an M4A file that can be converted to base64 for API requests.

### Speech-to-Text

The audio is sent to Google Cloud Speech-to-Text API with the Nepali language code (ne-NP) to convert the spoken Nepali to text.

### Translation

The transcribed Nepali text is sent to Google Cloud Translation API to translate it to English.

## Architecture

- **ContentView.swift**: Main UI with recording controls and result display
- **VoiceTranslationViewModel.swift**: Manages recording, transcription, and translation workflow
- **AudioRecorder.swift**: Handles audio recording functionality
- **GoogleCloudService.swift**: Interacts with Google Cloud APIs
- **GoogleCredentialsHelper.swift**: Manages authentication for Google Cloud
- **VoiceWaveformView.swift**: Visual representation of audio recording

## Security Considerations

⚠️ **IMPORTANT**: Never include service account credentials directly in your app code. The implementation shown in this project is simplified for educational purposes.

For production applications:
1. Use a secure backend service to handle authentication
2. Consider using Firebase Auth to manage tokens
3. Follow Google's best practices for mobile authentication

## License

This project is intended for educational purposes only.

## Credits

Created as part of the Artha project to demonstrate Google Cloud API integration with SwiftUI for Nepali to English voice translation. 