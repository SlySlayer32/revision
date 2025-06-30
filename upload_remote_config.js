const { exec } = require('child_process');
const fs = require('fs');
const https = require('https');

const PROJECT_ID = 'revision-464202';
const TEMPLATE_FILE = 'firebase_remote_config_template.json';

console.log('🔧 Uploading Firebase Remote Config...');

// Check if template file exists
if (!fs.existsSync(TEMPLATE_FILE)) {
    console.error('❌ Template file not found:', TEMPLATE_FILE);
    process.exit(1);
}

// Get Firebase access token
exec('firebase auth:print-tokens --json', (error, stdout, stderr) => {
    if (error) {
        console.error('❌ Failed to get access token. Please run "firebase login"');
        process.exit(1);
    }

    let tokens;
    try {
        tokens = JSON.parse(stdout);
    } catch (e) {
        console.error('❌ Failed to parse access token');
        process.exit(1);
    }

    const accessToken = tokens.access_token;
    console.log('✅ Access token obtained');

    // Read template content
    const templateContent = fs.readFileSync(TEMPLATE_FILE, 'utf8');
    
    // Upload using REST API
    const options = {
        hostname: 'firebaseremoteconfig.googleapis.com',
        port: 443,
        path: `/v1/projects/${PROJECT_ID}/remoteConfig`,
        method: 'PUT',
        headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
            'Content-Length': Buffer.byteLength(templateContent)
        }
    };

    console.log('🚀 Uploading template to Firebase...');
    
    const req = https.request(options, (res) => {
        let data = '';
        
        res.on('data', (chunk) => {
            data += chunk;
        });
        
        res.on('end', () => {
            if (res.statusCode === 200) {
                const response = JSON.parse(data);
                console.log('✅ Remote Config uploaded successfully!');
                console.log('Version:', response.version.versionNumber);
                console.log('');
                console.log('🎉 Success! Your Remote Config has been updated.');
                console.log('View in Console: https://console.firebase.google.com/project/' + PROJECT_ID + '/config');
            } else {
                console.error('❌ Upload failed:', res.statusCode, data);
                process.exit(1);
            }
        });
    });

    req.on('error', (error) => {
        console.error('❌ Upload failed:', error.message);
        process.exit(1);
    });

    req.write(templateContent);
    req.end();
});
