// Main JavaScript for Nepali Speech Translator

document.addEventListener('DOMContentLoaded', () => {
    // DOM elements
    const startBtn = document.getElementById('startBtn');
    const stopBtn = document.getElementById('stopBtn');
    const statusDiv = document.getElementById('status');
    const resultDiv = document.getElementById('result');
    const translationDiv = document.getElementById('translation');
    const volumeIndicator = document.getElementById('volumeIndicator');
    const errorContainer = document.getElementById('errorContainer');
    const errorText = document.getElementById('errorText');
    
    // Constants
    const MIN_RECORDING_TIME = 3000; // 3 seconds minimum recording time
    const MAX_SILENCE_DURATION = 1500; // 1.5 seconds of silence for auto-stop
    const PROCESSING_TIMEOUT = 15000; // 15 second timeout for processing
    
    // Variables
    let mediaRecorder;
    let audioContext;
    let audioStream;
    let recordingStartTime;
    let socket;
    let audioChunks = []; // Store audio chunks for complete recording
    let isRecording = false;
    let silenceDetector = null;
    let silenceStart = null;
    let processingInProgress = false;
    let processingTimeoutId = null;
    
    // Initialize Socket.IO
    function initSocket() {
        // Clear any existing connection
        if (socket) {
            socket.disconnect();
        }
        
        socket = io();
        
        // Handle socket events
        socket.on('connect', () => {
            console.log('Connected to server');
            updateStatus('Connected');
        });
        
        socket.on('disconnect', () => {
            console.log('Disconnected from server');
            updateStatus('Disconnected');
            // Try to reconnect
            setTimeout(initSocket, 2000);
        });
        
        socket.on('status', (data) => {
            console.log('Status:', data.message);
            updateStatus(data.message);
        });
        
        socket.on('error', (data) => {
            console.error('Error:', data.message);
            updateStatus('Error occurred', 'error');
            showError(data.message);
            resetProcessingState();
        });
        
        socket.on('interim_result', (data) => {
            console.log('Interim result:', data);
            if (data.message) {
                updateStatus(data.message);
            }
            // Still consider this a valid response for timeout purposes
            clearProcessingTimeout();
        });
        
        socket.on('transcription_result', (data) => {
            console.log('Transcription result:', data);
            displayResult(data.transcript, data.translation, data.confidence, data.low_confidence);
            updateStatus('Idle');
            resetProcessingState();
        });
    }
    
    // Reset the processing state
    function resetProcessingState() {
        processingInProgress = false;
        clearProcessingTimeout();
        startBtn.disabled = false;
    }
    
    // Setup processing timeout
    function setupProcessingTimeout() {
        clearProcessingTimeout();
        processingTimeoutId = setTimeout(() => {
            console.log('Processing timed out');
            updateStatus('Ready', 'info');
            showError('Processing timed out - please try again with a clearer, louder voice');
            resetProcessingState();
        }, PROCESSING_TIMEOUT);
    }
    
    // Clear processing timeout
    function clearProcessingTimeout() {
        if (processingTimeoutId) {
            clearTimeout(processingTimeoutId);
            processingTimeoutId = null;
        }
    }
    
    // Show error message
    function showError(message) {
        errorText.textContent = message;
        errorContainer.classList.remove('d-none');
        // Auto-hide after 8 seconds
        setTimeout(() => {
            errorContainer.classList.add('d-none');
        }, 8000);
    }
    
    // Start recording audio
    async function startRecording() {
        if (processingInProgress) {
            // If stuck in processing, allow starting a new recording anyway
            if (confirm('Still processing previous audio. Start a new recording anyway?')) {
                resetProcessingState();
            } else {
                return;
            }
        }
        
        // Hide any previous errors
        errorContainer.classList.add('d-none');
        
        try {
            // Reset previous recording data
            audioChunks = [];
            resultDiv.textContent = '';
            translationDiv.textContent = '';
            silenceStart = null;
            
            // Get audio stream with improved settings
            audioStream = await navigator.mediaDevices.getUserMedia({
                audio: {
                    echoCancellation: true,
                    noiseSuppression: true,
                    autoGainControl: true,
                    channelCount: 1,
                    sampleRate: 44100
                }
            });
            
            // Create audio context
            audioContext = new (window.AudioContext || window.webkitAudioContext)({
                sampleRate: 44100
            });
            
            // Create analyzer for volume indication and silence detection
            const analyser = audioContext.createAnalyser();
            analyser.fftSize = 1024; // Larger FFT for better analysis
            analyser.smoothingTimeConstant = 0.5; // Smoother transitions
            const bufferLength = analyser.frequencyBinCount;
            const dataArray = new Uint8Array(bufferLength);
            
            // Create media stream source
            const source = audioContext.createMediaStreamSource(audioStream);
            source.connect(analyser);
            
            // Set up volume meter and silence detection
            function updateVolumeAndSilence() {
                if (!isRecording) return;
                
                analyser.getByteFrequencyData(dataArray);
                let sum = 0;
                for (let i = 0; i < bufferLength; i++) {
                    sum += dataArray[i];
                }
                const average = sum / bufferLength;
                const volumePercent = Math.min(100, average * 2.5); // Scale for better visibility
                
                // Detect silence
                if (average < 5) { // Very low volume threshold
                    if (silenceStart === null) {
                        silenceStart = Date.now();
                    } else if (Date.now() - silenceStart > MAX_SILENCE_DURATION && 
                              Date.now() - recordingStartTime > MIN_RECORDING_TIME) {
                        // Auto-stop after silence if minimum time elapsed
                        console.log('Silence detected - auto stopping');
                        stopRecording();
                        return;
                    }
                } else {
                    silenceStart = null; // Reset silence detector on sound
                }
                
                // Update volume indicator
                volumeIndicator.style.width = `${volumePercent}%`;
                volumeIndicator.style.backgroundColor = getVolumeColor(volumePercent);
                
                // Continue updating
                requestAnimationFrame(updateVolumeAndSilence);
            }
            
            // Start volume meter and silence detection
            silenceDetector = updateVolumeAndSilence;
            silenceDetector();
            
            // Initialize media recorder with more compatible settings
            const mimeType = getSupportedMimeType();
            console.log(`Using mime type: ${mimeType}`);
            
            mediaRecorder = new MediaRecorder(audioStream, {
                mimeType: mimeType,
                audioBitsPerSecond: 128000 // Lower bitrate for more compatibility
            });
            
            // Handle data available event - store all chunks
            mediaRecorder.ondataavailable = (event) => {
                if (event.data.size > 0) {
                    audioChunks.push(event.data);
                }
            };
            
            // Start recording
            mediaRecorder.start(250); // Collect chunks more frequently
            recordingStartTime = Date.now();
            isRecording = true;
            
            updateStatus('Recording... (speak clearly)');
            startBtn.disabled = true;
            stopBtn.disabled = false;
            volumeIndicator.style.display = 'block';
            
        } catch (error) {
            console.error('Error starting recording:', error);
            updateStatus('Error', 'error');
            
            if (error.name === 'NotAllowedError') {
                showError('Microphone access denied. Please allow microphone access and try again.');
            } else if (error.name === 'NotFoundError') {
                showError('No microphone found. Please connect a microphone and try again.');
            } else {
                showError(`Error starting recording: ${error.message}`);
            }
            
            resetProcessingState();
        }
    }
    
    // Get supported MIME type for MediaRecorder
    function getSupportedMimeType() {
        const types = [
            'audio/webm;codecs=opus',
            'audio/webm',
            'audio/ogg;codecs=opus',
            'audio/mp4',
            'audio/mpeg',
            ''  // Empty string is default
        ];
        
        for (let type of types) {
            if (!type || MediaRecorder.isTypeSupported(type)) {
                return type;
            }
        }
        
        return '';
    }
    
    // Stop recording
    function stopRecording() {
        if (!mediaRecorder || mediaRecorder.state === 'inactive') {
            return;
        }
        
        // Check if minimum recording time has elapsed
        const recordingDuration = Date.now() - recordingStartTime;
        if (recordingDuration < MIN_RECORDING_TIME) {
            const remainingTime = Math.ceil((MIN_RECORDING_TIME - recordingDuration) / 1000);
            updateStatus(`Please speak for at least ${remainingTime} more second(s)`);
            return;
        }
        
        // Stop media recorder
        mediaRecorder.stop();
        isRecording = false;
        silenceStart = null;
        
        // Process complete recording when media recorder stops
        mediaRecorder.onstop = async () => {
            // Clean up
            if (audioStream) {
                audioStream.getTracks().forEach(track => track.stop());
            }
            
            // Check if there's any audio data
            if (audioChunks.length === 0) {
                showError('No audio recorded - please try again');
                resetProcessingState();
                return;
            }
            
            // Process the complete audio recording
            updateStatus('Processing complete audio...');
            processingInProgress = true;
            setupProcessingTimeout();
            
            try {
                // Create a single Blob from all audio chunks
                const audioBlob = new Blob(audioChunks, { type: mediaRecorder.mimeType || 'audio/webm' });
                console.log(`Complete recording size: ${audioBlob.size} bytes, duration: ${recordingDuration}ms`);
                
                if (audioBlob.size < 1000) {
                    showError('Audio recording too short - please try again');
                    resetProcessingState();
                    return;
                }
                
                // Convert to proper format
                const rawData = await audioBlob.arrayBuffer();
                const result = await convertToLinear16(rawData, audioContext.sampleRate);
                
                // Encode as base64
                const base64Audio = arrayBufferToBase64(result.buffer);
                
                // Send complete audio to server
                socket.emit('complete_audio_data', {
                    audio: base64Audio,
                    duration: recordingDuration
                });
                
                updateStatus('Analyzing speech...');
                
            } catch (error) {
                console.error('Error processing audio:', error);
                showError(`Error processing audio: ${error.message}`);
                resetProcessingState();
            }
            
            // Reset UI
            stopBtn.disabled = true;
            volumeIndicator.style.width = '0%';
        };
    }
    
    // Convert audio to LINEAR16 format (16-bit PCM at 16kHz)
    async function convertToLinear16(audioBuffer, sampleRate) {
        try {
            // Create a new AudioContext for processing
            const offlineContext = new OfflineAudioContext(
                1, // mono
                audioBuffer.byteLength * (16000 / sampleRate), // adjust buffer size for resampling
                16000 // target sample rate for Google Speech API
            );
            
            // Load audio data
            const audioBufferSource = offlineContext.createBufferSource();
            const sourceBuffer = await offlineContext.decodeAudioData(audioBuffer);
            audioBufferSource.buffer = sourceBuffer;
            
            // Connect to offline context
            audioBufferSource.connect(offlineContext.destination);
            audioBufferSource.start(0);
            
            // Process the audio
            const renderedBuffer = await offlineContext.startRendering();
            
            // Convert to 16-bit PCM
            const floatSamples = renderedBuffer.getChannelData(0);
            const int16Samples = new Int16Array(floatSamples.length);
            
            // Convert Float32 to Int16
            for (let i = 0; i < floatSamples.length; i++) {
                const s = Math.max(-1, Math.min(1, floatSamples[i]));
                int16Samples[i] = s < 0 ? s * 0x8000 : s * 0x7FFF;
            }
            
            return {
                buffer: int16Samples.buffer,
                sampleRate: 16000
            };
        } catch (error) {
            console.error('Error converting audio format:', error);
            throw new Error('Failed to convert audio to required format');
        }
    }
    
    // Convert ArrayBuffer to Base64
    function arrayBufferToBase64(buffer) {
        const bytes = new Uint8Array(buffer);
        let binary = '';
        for (let i = 0; i < bytes.byteLength; i++) {
            binary += String.fromCharCode(bytes[i]);
        }
        return window.btoa(binary);
    }
    
    // Get color for volume indicator
    function getVolumeColor(volume) {
        if (volume < 30) return '#4CAF50'; // Low volume - green
        if (volume < 70) return '#FFC107'; // Medium volume - yellow
        return '#F44336'; // High volume - red
    }
    
    // Display results
    function displayResult(transcript, translation, confidence, lowConfidence) {
        resultDiv.textContent = transcript || 'No transcription available';
        translationDiv.textContent = translation || 'No translation available';
        
        // Add confidence indicator if available
        if (confidence) {
            const confidencePercent = Math.round(confidence * 100);
            const confidenceSpan = document.createElement('span');
            confidenceSpan.textContent = ` (${confidencePercent}% confidence)`;
            confidenceSpan.className = confidencePercent > 70 ? 'high-confidence' : 'low-confidence';
            resultDiv.appendChild(confidenceSpan);
            
            // Show warning for low confidence results
            if (lowConfidence) {
                showError('Low confidence in speech recognition. The translation may not be accurate.');
            }
        }
    }
    
    // Update status message
    function updateStatus(message, type = 'info') {
        statusDiv.textContent = message;
        statusDiv.className = `status ${type}`;
    }
    
    // Initialize app
    function initApp() {
        // Initialize socket
        initSocket();
        
        // Event listeners
        startBtn.addEventListener('click', startRecording);
        stopBtn.addEventListener('click', stopRecording);
        
        // Initial setup
        stopBtn.disabled = true;
        updateStatus('Ready');
        
        // Check for any stuck state and reset
        resetProcessingState();
    }
    
    // Start the app
    initApp();
}); 