# Google Cloud API Keys

For this application to work properly, you need to add Google Cloud API key files in this directory.

## Required Files:
- `google-credentials.json` - Main service account key for Google Cloud services
- `google-credentials-backup.json` - Backup service account key

## How to Obtain API Keys:
1. Go to the Google Cloud Console: https://console.cloud.google.com/
2. Create a new project or select an existing one
3. Enable the following APIs:
   - Cloud Speech-to-Text API
   - Cloud Translation API
4. Create a service account and download the JSON key file
5. Rename the downloaded file to `google-credentials.json` and place it in this directory

NOTE: These files contain sensitive API keys and should never be committed to version control.
The application will look for these files in this directory at runtime. 