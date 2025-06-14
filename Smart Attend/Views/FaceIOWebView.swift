import SwiftUI
import WebKit

struct FaceIOWebView: UIViewRepresentable {
    let onAuthenticated: (String) -> Void
    let onError: (String) -> Void
    let onClose: () -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // Enhanced media permissions
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.allowsAirPlayForMediaPlayback = false
        
        // Security settings
        configuration.preferences.javaScriptEnabled = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        
        // Message handlers
        let messageHandlers = ["onAuthenticated", "onError", "onLog", "onClose"]
        for handler in messageHandlers {
            webView.configuration.userContentController.add(context.coordinator, name: handler)
        }
        
        // Load HTML content
        let htmlString = getFaceIOHTML()
        webView.loadHTMLString(htmlString, baseURL: URL(string: "https://localhost"))
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onAuthenticated: onAuthenticated, onError: onError, onClose: onClose)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        let onAuthenticated: (String) -> Void
        let onError: (String) -> Void
        let onClose: () -> Void
        
        init(onAuthenticated: @escaping (String) -> Void, onError: @escaping (String) -> Void, onClose: @escaping () -> Void) {
            self.onAuthenticated = onAuthenticated
            self.onError = onError
            self.onClose = onClose
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            DispatchQueue.main.async {
                switch message.name {
                case "onAuthenticated":
                    if let rollNumber = message.body as? String {
                        self.onAuthenticated(rollNumber)
                    }
                case "onError":
                    if let error = message.body as? String {
                        self.onError(error)
                    }
                case "onClose":
                    self.onClose()
                case "onLog":
                    if let logMessage = message.body as? String {
                        print("🔍 Face.io: \(logMessage)")
                    }
                default:
                    break
                }
            }
        }
        
        // Enhanced media capture permission handling
        func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            print("📹 Media capture permission requested for: \(origin.host ?? "unknown")")
            decisionHandler(.grant)
        }
        
        // Handle JavaScript alerts
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            print("⚠️ JavaScript Alert: \(message)")
            completionHandler()
        }
        
        // Navigation delegate methods
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ WebView finished loading")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ WebView navigation failed: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.onError("Failed to load authentication: \(error.localizedDescription)")
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("❌ WebView provisional navigation failed: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.onError("Failed to initialize: \(error.localizedDescription)")
            }
        }
    }
}

private func getFaceIOHTML() -> String {
    return """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
        <title>Face Authentication</title>
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }
            
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
                min-height: 100vh;
                background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
                color: white;
                overflow: hidden;
                -webkit-user-select: none;
                user-select: none;
            }
            
            .container {
                text-align: center;
                background: rgba(255, 255, 255, 0.95);
                color: #333;
                padding: 40px 30px;
                border-radius: 24px;
                box-shadow: 0 25px 50px rgba(0,0,0,0.15);
                max-width: 380px;
                width: 90%;
                backdrop-filter: blur(20px);
                border: 1px solid rgba(255,255,255,0.2);
                transition: all 0.3s ease;
            }
            
            .scanning .container {
                opacity: 0.1;
                pointer-events: none;
            }
            
            .icon {
                font-size: 56px;
                margin-bottom: 20px;
                filter: drop-shadow(0 4px 8px rgba(0,0,0,0.1));
            }
            
            h2 {
                color: #2d3748;
                margin-bottom: 8px;
                font-size: 28px;
                font-weight: 800;
                letter-spacing: -0.5px;
            }
            
            .subtitle {
                color: #718096;
                margin-bottom: 24px;
                font-size: 16px;
                font-weight: 500;
            }
            
            .info {
                color: #a0aec0;
                margin-bottom: 24px;
                font-size: 14px;
                line-height: 1.5;
            }
            
            .status {
                margin-top: 24px;
                padding: 16px 20px;
                border-radius: 16px;
                font-weight: 600;
                font-size: 15px;
                transition: all 0.3s ease;
                border: 2px solid transparent;
            }
            
            .success {
                background: linear-gradient(135deg, #48bb78, #38a169);
                color: white;
                border-color: #38a169;
                box-shadow: 0 8px 25px rgba(72, 187, 120, 0.3);
            }
            
            .error {
                background: linear-gradient(135deg, #f56565, #e53e3e);
                color: white;
                border-color: #e53e3e;
                box-shadow: 0 8px 25px rgba(245, 101, 101, 0.3);
            }
            
            .loading {
                background: linear-gradient(135deg, #4299e1, #3182ce);
                color: white;
                border-color: #3182ce;
                box-shadow: 0 8px 25px rgba(66, 153, 225, 0.3);
            }
            
            .button {
                background: linear-gradient(135deg, #4facfe, #00f2fe);
                color: white;
                border: none;
                padding: 16px 32px;
                border-radius: 50px;
                cursor: pointer;
                margin-top: 24px;
                font-size: 16px;
                font-weight: 700;
                transition: all 0.2s ease;
                box-shadow: 0 8px 25px rgba(79, 172, 254, 0.3);
                min-width: 140px;
                text-transform: uppercase;
                letter-spacing: 0.5px;
            }
            
            .button:hover {
                transform: translateY(-2px);
                box-shadow: 0 12px 35px rgba(79, 172, 254, 0.4);
            }
            
            .button:active {
                transform: translateY(0);
            }
            
            .close-button {
                position: absolute;
                top: 20px;
                right: 20px;
                background: rgba(255, 255, 255, 0.9);
                color: #333;
                border: none;
                width: 40px;
                height: 40px;
                border-radius: 50%;
                cursor: pointer;
                font-size: 18px;
                font-weight: bold;
                display: flex;
                align-items: center;
                justify-content: center;
                transition: all 0.2s ease;
                backdrop-filter: blur(10px);
            }
            
            .close-button:hover {
                background: rgba(255, 255, 255, 1);
                transform: scale(1.1);
            }
            
            @keyframes pulse {
                0% { transform: scale(1); }
                50% { transform: scale(1.03); }
                100% { transform: scale(1); }
            }
            
            @keyframes spin {
                0% { transform: rotate(0deg); }
                100% { transform: rotate(360deg); }
            }
            
            .pulse {
                animation: pulse 2s infinite ease-in-out;
            }
            
            .spin {
                animation: spin 2s linear infinite;
            }
            
            .scanning-overlay {
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                z-index: 1000;
                background: rgba(0, 0, 0, 0.8);
                display: none;
                align-items: center;
                justify-content: center;
                backdrop-filter: blur(5px);
            }
            
            .scanning-message {
                background: rgba(255, 255, 255, 0.95);
                color: #333;
                padding: 30px;
                border-radius: 20px;
                text-align: center;
                font-size: 18px;
                font-weight: 600;
                box-shadow: 0 20px 40px rgba(0,0,0,0.3);
            }
            
            /* Remove the scanning overlay display - let Face.io handle the UI */
            .scanning .scanning-overlay {
                display: none;
            }
        </style>
    </head>
    <body>
        <button class="close-button" onclick="closeAuth()" aria-label="Close">×</button>
        
        <div class="scanning-overlay">
            <div class="scanning-message">
                <div class="icon spin">📷</div>
                <div>Face scanning in progress...</div>
                <div style="font-size: 14px; margin-top: 10px; opacity: 0.7;">Please look directly at the camera</div>
            </div>
        </div>
        
        <div class="container">
            <div class="icon">🔐</div>
            <h2>Face Authentication</h2>
            <p class="subtitle">Secure biometric verification</p>
            <p class="info">Position your face within the camera frame for quick and secure authentication</p>
            <div id="status" class="status loading">Initializing secure connection...</div>
            <button id="startButton" class="button" style="display: none;">Start Verification</button>
        </div>

        <script src="https://cdn.faceio.net/fio.js"></script>
        <script>
            let faceio = null;
            let isProcessing = false;
            const statusDiv = document.getElementById('status');
            const startButton = document.getElementById('startButton');
            const container = document.querySelector('.container');

            function log(message) {
                console.log(message);
                if (window.webkit?.messageHandlers?.onLog) {
                    try {
                        window.webkit.messageHandlers.onLog.postMessage(message);
                    } catch (e) {
                        console.error('Failed to send log to iOS:', e);
                    }
                }
            }

            function safeCallback(handlerName, data) {
                try {
                    if (window.webkit?.messageHandlers?.[handlerName]) {
                        window.webkit.messageHandlers[handlerName].postMessage(data);
                        log(`Callback sent: ${handlerName} - ${data}`);
                    } else {
                        log(`Handler ${handlerName} not available`);
                    }
                } catch (error) {
                    log(`Callback error for ${handlerName}: ${error.message}`);
                }
            }

            function closeAuth() {
                log('Close button clicked');
                safeCallback('onClose', 'User closed authentication');
            }

            function updateStatus(message, type) {
                statusDiv.innerHTML = message;
                statusDiv.className = `status ${type}`;
                log(`Status updated: ${type} - ${message}`);
            }

            function initializeFaceIO() {
                try {
                    log('Initializing Face.io...');
                    faceio = new faceIO('fioa264a');
                    
                    updateStatus('✨ Ready for authentication', 'success');
                    container.classList.add('pulse');
                    startButton.style.display = 'block';
                    startButton.onclick = startAuthentication;
                    
                    log('Face.io initialized successfully');
                } catch (error) {
                    log(`Face.io initialization failed: ${error.message}`);
                    updateStatus('❌ Failed to initialize authentication', 'error');
                    safeCallback('onError', `Initialization failed: ${error.message}`);
                }
            }

            function startAuthentication() {
                if (isProcessing) {
                    log('Authentication already in progress');
                    return;
                }
                
                isProcessing = true;
                startButton.style.display = 'none';
                updateStatus('🔍 Preparing camera...', 'loading');
                container.classList.remove('pulse');
                document.body.classList.add('scanning');
                
                log('Starting authentication process');
                
                setTimeout(() => {
                    authenticateUser();
                }, 1000);
            }

            function authenticateUser() {
                if (!faceio) {
                    resetToReady('Face.io not properly initialized');
                    return;
                }

                log('Starting face authentication');
                updateStatus('📷 Scanning face... Look at camera', 'loading');

                faceio.authenticate({
                    locale: "auto",
                    payload: {
                        /* Optional additional data */
                    }
                }).then(userData => {
                    log(`Authentication successful: ${JSON.stringify(userData)}`);
                    
                    const rollNumber = userData.payload?.rollNumber || userData.facialId || 'N/A';
                    const userName = userData.payload?.userName || 'User';
                    
                    updateStatus(
                        `✅ Authentication successful!<br><strong>${userName}</strong><br>ID: ${rollNumber}`, 
                        'success'
                    );
                    
                    setTimeout(() => {
                        safeCallback('onAuthenticated', rollNumber);
                    }, 1500);
                    
                }).catch(errCode => {
                    log(`Authentication failed with code: ${errCode}`);
                    const errorMessage = getErrorMessage(errCode);
                    resetToReady(errorMessage);
                    safeCallback('onError', errorMessage);
                });
            }

            function resetToReady(errorMessage = null) {
                isProcessing = false;
                document.body.classList.remove('scanning');
                container.classList.add('pulse');
                
                if (errorMessage) {
                    updateStatus(`❌ ${errorMessage}`, 'error');
                    startButton.textContent = 'Try Again';
                } else {
                    updateStatus('✨ Ready for authentication', 'success');
                    startButton.textContent = 'Start Verification';
                }
                
                startButton.style.display = 'block';
            }

            function getErrorMessage(errCode) {
                const errorMap = {
                    1: "Camera access denied. Please allow camera permissions.",
                    2: "No face detected. Please position yourself in front of the camera.",
                    3: "Face not recognized. Please try again or register first.",
                    4: "Multiple faces detected. Please ensure only one person is visible.",
                    5: "Liveness check failed. Please look directly at the camera.",
                    6: "Face detection timeout. Please try again.",
                    7: "Network connection error. Please check your internet.",
                    8: "Invalid PIN code entered.",
                    9: "Processing error occurred. Please try again.",
                    10: "Unauthorized access attempt detected.",
                    11: "Terms of service not accepted.",
                    12: "Authentication interface not ready.",
                    13: "Session has expired. Please restart.",
                    14: "Operation timed out. Please try again.",
                    15: "Too many requests. Please wait before trying again.",
                    16: "Face.io service temporarily unavailable.",
                    17: "Invalid application configuration."
                };
                
                return errorMap[errCode] || `Authentication error (Code: ${errCode}). Please try again.`;
            }

            // Initialize when page loads
            window.addEventListener('load', () => {
                log('Page loaded, initializing Face.io...');
                setTimeout(initializeFaceIO, 500);
            });

            // Handle visibility changes
            document.addEventListener('visibilitychange', () => {
                if (document.hidden && isProcessing) {
                    log('Page became hidden during processing');
                    resetToReady('Authentication interrupted');
                }
            });
        </script>
    </body>
    </html>
    """
}
