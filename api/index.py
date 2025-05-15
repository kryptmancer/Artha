from flask import Flask, request, render_template, jsonify
from flask_socketio import SocketIO, emit
from google.cloud import speech, translate_v2 as translate
import os
import json
import base64
import logging
from dotenv import load_dotenv
from google.oauth2 import service_account

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.DEBUG)  # Change to DEBUG for more verbose logging
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__, static_folder="../static", template_folder="../templates")
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'your-secret-key')

# Configure CORS for SocketIO
socketio = SocketIO(app, cors_allowed_origins="*")

# Path to credentials file
credentials_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'google-credentials.json')
logger.info(f"Looking for credentials at: {credentials_path}")

# Initialize Google Cloud clients
try:
    # Load credentials directly
    credentials = service_account.Credentials.from_service_account_file(credentials_path)
    
    # Print project ID for debugging
    project_id = credentials.project_id
    logger.info(f"Using Google Cloud project: {project_id}")
    
    # Initialize clients with explicit credentials
    speech_client = speech.SpeechClient(credentials=credentials)
    translate_client = translate.Client(credentials=credentials)
    
    # Verify API access by listing supported languages
    try:
        languages = translate_client.get_languages()
        nepali_supported = any(lang['language'] == 'ne' for lang in languages)
        logger.info(f"Translation API access verified, Nepali supported: {nepali_supported}")
    except Exception as e:
        logger.error(f"Error checking translation languages: {e}")
    
    logger.info("Google Cloud clients initialized successfully")
except Exception as e:
    logger.error(f"Error initializing Google Cloud clients: {e}")
    speech_client = None
    translate_client = None

# Common Nepali phrases to help with recognition
NEPALI_PHRASE_HINTS = [
    "नमस्ते", "धन्यवाद", "माफ गर्नुहोस्", "तपाईंलाई कस्तो छ",
    "म", "तिमी", "हामी", "उनीहरू", "के", "किन", "कसरी", "कहाँ",
    "एक", "दुई", "तीन", "चार", "पाँच", "छ", "सात", "आठ", "नौ", "दश",
    "खाना", "पानी", "घर", "स्कूल", "बजार", "काम"
]

@app.route('/')
def index():
    """Serve the main page."""
    return render_template('index.html')

@socketio.on('connect')
def handle_connect():
    """Handle client connection."""
    logger.info('Client connected')
    emit('status', {'message': 'Connected to server'})

@socketio.on('disconnect')
def handle_disconnect():
    """Handle client disconnection."""
    logger.info('Client disconnected')

@socketio.on('complete_audio_data')
def handle_complete_audio(data):
    """
    Process complete audio recording from the client:
    1. Transcribe Nepali speech to text
    2. Translate Nepali text to English
    3. Return both to the client
    """
    if not speech_client or not translate_client:
        emit('error', {'message': 'Google Cloud services not initialized'})
        return
    
    try:
        logger.info("Received complete audio data, processing...")
        
        # Decode base64 audio data
        audio_data = base64.b64decode(data['audio'])
        duration_ms = data.get('duration', 0)
        
        # Log audio data size for debugging
        logger.info(f"Complete audio data size: {len(audio_data)} bytes, duration: {duration_ms}ms")
        
        # Check for empty or too small audio data
        if len(audio_data) < 1000:
            logger.warning("Audio data too small, likely no speech")
            emit('interim_result', {'transcript': '', 'translation': '', 'message': 'No speech detected (recording too short)'})
            return
        
        # Send an immediate ack to the client
        emit('interim_result', {'message': 'Processing audio...'})
        
        # Configure speech recognition request for complete audio - simplified for speed
        config = speech.RecognitionConfig(
            encoding=speech.RecognitionConfig.AudioEncoding.LINEAR16,
            sample_rate_hertz=16000,
            language_code="ne-NP",
            use_enhanced=True,
            enable_automatic_punctuation=True,
            model="default",
            max_alternatives=1,  # Reduced alternatives for faster processing
            speech_contexts=[
                speech.SpeechContext(
                    phrases=NEPALI_PHRASE_HINTS,
                    boost=20.0
                )
            ],
            # Essential metadata only
            metadata=speech.RecognitionMetadata(
                interaction_type=speech.RecognitionMetadata.InteractionType.DICTATION,
                microphone_distance=speech.RecognitionMetadata.MicrophoneDistance.NEARFIELD,
                recording_device_type=speech.RecognitionMetadata.RecordingDeviceType.PC
            ),
            alternative_language_codes=["hi-IN", "en-US"]  # Add fallback languages
        )
        
        # Create audio object
        audio = speech.RecognitionAudio(content=audio_data)
        
        # Detect speech with more detailed logging
        logger.info("Sending complete audio to Google Speech-to-Text API...")
        response = speech_client.recognize(config=config, audio=audio)
        
        # Log response summary
        logger.info(f"Got response with {len(response.results)} results")
        
        # If no Nepali results, try with English as fallback
        if not response.results:
            logger.info("No results with Nepali, trying with English...")
            emit('interim_result', {'message': 'Trying with English...'})
            english_config = speech.RecognitionConfig(
                encoding=speech.RecognitionConfig.AudioEncoding.LINEAR16,
                sample_rate_hertz=16000,
                language_code="en-US",
                use_enhanced=True,
                enable_automatic_punctuation=True,
                max_alternatives=1
            )
            response = speech_client.recognize(config=english_config, audio=audio)
            logger.info(f"English recognition got {len(response.results)} results")
        
        # Process results
        if not response.results:
            logger.info("No speech detected in the complete audio")
            emit('interim_result', {'transcript': '', 'translation': '', 'message': 'No speech detected'})
            return
        
        # Join all transcription results for complete transcription
        full_transcript = ""
        confidence_sum = 0
        result_count = 0
        
        for result in response.results:
            if not result.alternatives:
                continue
            
            transcript = result.alternatives[0].transcript
            confidence = result.alternatives[0].confidence
            
            logger.info(f"Result {result_count+1}: Transcript: {transcript}, Confidence: {confidence}")
            
            full_transcript += " " + transcript
            confidence_sum += confidence
            result_count += 1
        
        # Calculate average confidence
        avg_confidence = confidence_sum / result_count if result_count > 0 else 0
        full_transcript = full_transcript.strip()
        
        logger.info(f"Full transcript: {full_transcript}, Average confidence: {avg_confidence}")
        
        # Even with very low confidence, still return the transcript
        # and mark it with a low confidence note
        low_confidence = avg_confidence < 0.2
        
        # Translate text
        try:
            # Send an interim result
            emit('interim_result', {'transcript': full_transcript, 'message': 'Translating...'})
            
            translation = translate_client.translate(
                full_transcript, 
                target_language='en',
                source_language='ne'
            )
            
            logger.info(f"Translation: {translation['translatedText']}")
            
            # Send results to client
            emit('transcription_result', {
                'transcript': full_transcript,
                'translation': translation['translatedText'],
                'confidence': avg_confidence,
                'low_confidence': low_confidence
            })
        except Exception as translate_error:
            logger.error(f"Translation error: {translate_error}")
            # Still send the transcript even if translation fails
            emit('transcription_result', {
                'transcript': full_transcript,
                'translation': f"Translation error: {str(translate_error)}",
                'confidence': avg_confidence,
                'low_confidence': low_confidence
            })
            
    except Exception as e:
        logger.error(f"Error processing complete audio: {e}")
        emit('error', {'message': f'Error processing audio: {str(e)}'})
        # Try to give a more specific message based on the error
        if "Invalid audio" in str(e):
            emit('error', {'message': 'Invalid audio format. Please try again.'})
        elif "Exceeds limit" in str(e):
            emit('error', {'message': 'Audio too long. Please record a shorter message.'})
        elif "Permission denied" in str(e):
            emit('error', {'message': 'API permission issue. Check Google Cloud credentials.'})
        elif "not enabled" in str(e):
            emit('error', {'message': 'Nepali language not enabled in Google Cloud project. Enable it in the Cloud Console.'})
        else:
            emit('error', {'message': f'Error processing audio: {str(e)}'})

# Keep old handler for compatibility, but we'll use complete_audio_data instead
@socketio.on('audio_data')
def handle_audio_data(data):
    """Legacy handler for streaming audio data chunks."""
    if not speech_client or not translate_client:
        emit('error', {'message': 'Google Cloud services not initialized'})
        return
    
    try:
        logger.info("Received legacy audio chunk, processing...")
        
        # Decode base64 audio data
        audio_data = base64.b64decode(data['audio'])
        
        # Log audio data size for debugging
        logger.info(f"Audio chunk size: {len(audio_data)} bytes")
        
        # Configure speech recognition request
        config = speech.RecognitionConfig(
            encoding=speech.RecognitionConfig.AudioEncoding.LINEAR16,
            sample_rate_hertz=16000,
            language_code="ne-NP",
            use_enhanced=True,
            enable_automatic_punctuation=True,
            model="default",
            speech_contexts=[
                speech.SpeechContext(
                    phrases=NEPALI_PHRASE_HINTS,
                    boost=15.0
                )
            ],
            metadata=speech.RecognitionMetadata(
                interaction_type=speech.RecognitionMetadata.InteractionType.DICTATION,
                microphone_distance=speech.RecognitionMetadata.MicrophoneDistance.NEARFIELD,
                recording_device_type=speech.RecognitionMetadata.RecordingDeviceType.PC
            ),
            alternative_language_codes=["en-US", "hi-IN"]
        )
        
        # Create audio object
        audio = speech.RecognitionAudio(content=audio_data)
        
        # Detect speech
        logger.info("Sending audio chunk to Speech-to-Text API...")
        response = speech_client.recognize(config=config, audio=audio)
        
        # Process results
        if not response.results:
            logger.info("No speech detected in audio chunk")
            emit('interim_result', {'transcript': '', 'translation': '', 'message': 'No speech detected'})
            return
            
        transcript = response.results[0].alternatives[0].transcript
        confidence = response.results[0].alternatives[0].confidence
        
        logger.info(f"Chunk transcript: {transcript}, Confidence: {confidence}")
        
        # Lower the confidence threshold
        if confidence < 0.3:
            emit('interim_result', {
                'transcript': transcript, 
                'translation': '', 
                'message': 'Low confidence - please speak clearly'
            })
            return
            
        # Translate text
        try:
            translation = translate_client.translate(
                transcript, 
                target_language='en',
                source_language='ne'
            )
            
            logger.info(f"Translation: {translation['translatedText']}")
            
            # Send results to client
            emit('transcription_result', {
                'transcript': transcript,
                'translation': translation['translatedText'],
                'confidence': confidence
            })
        except Exception as translate_error:
            logger.error(f"Translation error: {translate_error}")
            # Still send the transcript even if translation fails
            emit('transcription_result', {
                'transcript': transcript,
                'translation': f"Translation error: {str(translate_error)}",
                'confidence': confidence
            })
            
    except Exception as e:
        logger.error(f"Error processing audio chunk: {e}")
        emit('error', {'message': f'Error processing audio: {str(e)}'})

@app.route('/api/health')
def health_check():
    """API health check endpoint."""
    return jsonify({"status": "healthy"})

# Vercel requires a Flask app to be named 'app'
if __name__ == '__main__':
    socketio.run(app, debug=True, host='0.0.0.0', port=5001) 