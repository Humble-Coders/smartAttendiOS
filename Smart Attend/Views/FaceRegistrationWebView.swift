import SwiftUI
import WebKit

struct FaceRegistrationWebView: UIViewRepresentable {
    let rollNumber: String
    let onFaceRegistered: (String) -> Void
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
        let messageHandlers = ["onFaceRegistered", "onError", "onLog", "onClose"]
        for handler in messageHandlers {
            webView.configuration.userContentController.add(context.coordinator, name: handler)
        }
        
        // Load HTML content
        let htmlString = getFaceRegistrationHTML(rollNumber: rollNumber)
        webView.loadHTMLString(htmlString, baseURL: URL(string: "https://localhost"))
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onFaceRegistered: onFaceRegistered, onError: onError, onClose: onClose)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        let onFaceRegistered: (String) -> Void
        let onError: (String) -> Void
        let onClose: () -> Void
        
        init(onFaceRegistered: @escaping (String) -> Void, onError: @escaping (String) -> Void, onClose: @escaping () -> Void) {
            self.onFaceRegistered = onFaceRegistered
            self.onError = onError
            self.onClose = onClose
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            DispatchQueue.main.async {
                switch message.name {
                case "onFaceRegistered":
                    if let faceId = message.body as? String {
                        self.onFaceRegistered(faceId)
                    }
                case "onError":
                    if let error = message.body as? String {
                        self.onError(error)
                    }
                case "onClose":
                    self.onClose()
                case "onLog":
                    if let logMessage = message.body as? String {
                        print("🔍 Face Registration: \(logMessage)")
                    }
                default:
                    break
                }
            }
        }
        
        func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            print("📹 Media capture permission requested for face registration: \(origin.host ?? "unknown")")
            decisionHandler(.grant)
        }
        
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            print("⚠️ JavaScript Alert: \(message)")
            completionHandler()
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ Face Registration WebView finished loading")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ Face Registration WebView navigation failed: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.onError("Failed to load face registration: \(error.localizedDescription)")
            }
        }
    }
}

private func getFaceRegistrationHTML(rollNumber: String) -> String {
    return """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
        <title>Face Registration</title>
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
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
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
                margin-bottom: 12px;
                font-size: 16px;
                font-weight: 500;
            }
            
            .roll-number {
                background-color: #e3f2fd;
                color: #1565c0;
                padding: 10px 20px;
                border-radius: 8px;
                font-weight: bold;
                font-size: 18px;
                margin-bottom: 20px;
                border: 2px solid #1976d2;
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
                background: linear-gradient(135deg, #667eea, #764ba2);
                color: white;
                border: none;
                padding: 16px 32px;
                border-radius: 50px;
                cursor: pointer;
                margin-top: 24px;
                font-size: 16px;
                font-weight: 700;
                transition: all 0.2s ease;
                box-shadow: 0 8px 25px rgba(103, 126, 234, 0.3);
                min-width: 140px;
                text-transform: uppercase;
                letter-spacing: 0.5px;
            }
            
            .button:hover {
                transform: translateY(-2px);
                box-shadow: 0 12px 35px rgba(103, 126, 234, 0.4);
            }
            
            .close-button {
                display: none;
            }
            
            @keyframes pulse {
                0% { transform: scale(1); }
                50% { transform: scale(1.03); }
                100% { transform: scale(1); }
            }
            
            .pulse {
                animation: pulse 2s infinite ease-in-out;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="icon">👤</div>
            <h2>Face Registration</h2>
            <p class="subtitle">Required for Attendance</p>
            
            <div class="roll-number">
                Roll Number: \(rollNumber)
            </div>
            
            <p class="info">Face registration is required for attendance marking. Position your face in the camera frame.</p>
            <div id="status" class="status loading">Initializing Face.io...</div>
            <button id="startButton" class="button" style="display: none;">Start Registration</button>
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

            function closeRegistration() {
                log('Registration cannot be closed - face registration is required');
                // Do nothing - face registration is mandatory
            }

            function updateStatus(message, type) {
                statusDiv.innerHTML = message;
                statusDiv.className = `status ${type}`;
                log(`Status updated: ${type} - ${message}`);
            }

            function initializeFaceIO() {
                try {
                    log('Initializing Face.io for registration...');
                    faceio = new faceIO('fioa3e64');
                    
                    updateStatus('✨ Ready for face registration', 'success');
                    container.classList.add('pulse');
                    startButton.style.display = 'block';
                    startButton.onclick = startRegistration;
                    
                    log('Face.io initialized successfully');
                } catch (error) {
                    log(`Face.io initialization failed: ${error.message}`);
                    updateStatus('❌ Failed to initialize face registration', 'error');
                    safeCallback('onError', `Initialization failed: ${error.message}`);
                }
            }

            function startRegistration() {
                if (isProcessing) {
                    log('Registration already in progress');
                    return;
                }
                
                isProcessing = true;
                startButton.style.display = 'none';
                updateStatus('🔍 Preparing camera for registration...', 'loading');
                container.classList.remove('pulse');
                
                log('Starting face registration process for roll number: \(rollNumber)');
                
                setTimeout(() => {
                    enrollNewUser();
                }, 1000);
            }

            function enrollNewUser() {
                if (!faceio) {
                    resetToReady('Face.io not properly initialized');
                    return;
                }

                log('Starting face enrollment for roll number: \(rollNumber)');
                updateStatus('📷 Scanning face for registration...', 'loading');

                faceio.enroll({
                    locale: "auto",
                    payload: {
                        rollNumber: "\(rollNumber)",
                        registeredBy: "student",
                        registrationDate: new Date().toISOString()
                    },
                    userConsent: false,
                    enrollIntroTimeout: 3,
                    noBoardingPass: true
                }).then(userInfo => {
                    log(`Registration successful! FacialId: ${userInfo.facialId} for roll number: \(rollNumber)`);
                    updateStatus(
                        `✅ Registration successful!<br><strong>Welcome!</strong><br>Face ID: ${userInfo.facialId}`, 
                        'success'
                    );
                    
                    setTimeout(() => {
                        safeCallback('onFaceRegistered', userInfo.facialId);
                    }, 1500);
                    
                }).catch(errCode => {
                    log(`Registration failed with code: ${errCode} for roll number: \(rollNumber)`);
                    const errorMessage = getErrorMessage(errCode);
                    resetToReady(errorMessage);
                    safeCallback('onError', errorMessage);
                });
            }

            function resetToReady(errorMessage = null) {
                isProcessing = false;
                container.classList.add('pulse');
                
                if (errorMessage) {
                    updateStatus(`❌ ${errorMessage}`, 'error');
                    startButton.textContent = 'Try Again';
                } else {
                    updateStatus('✨ Ready for face registration', 'success');
                    startButton.textContent = 'Start Registration';
                }
                
                startButton.style.display = 'block';
            }

            function getErrorMessage(errCode) {
                const errorMap = {
                    1: "Camera access denied. Please allow camera permissions.",
                    2: "No face detected. Please position yourself in front of the camera.",
                    3: "Face recognition failed. Please ensure good lighting.",
                    4: "Multiple faces detected. Please ensure only one person is visible.",
                    5: "Face already registered. This face is already in our system.",
                    6: "Liveness check failed. Please look directly at the camera.",
                    7: "Network connection error. Please check your internet.",
                    8: "Invalid PIN code entered.",
                    9: "Processing error occurred. Please try again.",
                    10: "Unauthorized access attempt detected.",
                    11: "Terms of service not accepted.",
                    12: "Registration interface not ready.",
                    13: "Session has expired. Please restart.",
                    14: "Operation timed out. Please try again.",
                    15: "Too many requests. Please wait before trying again.",
                    16: "Face.io service temporarily unavailable.",
                    17: "Invalid application configuration."
                };
                
                return errorMap[errCode] || `Registration error (Code: ${errCode}). Please try again.`;
            }

            // Initialize when page loads
            window.addEventListener('load', () => {
                log('Face registration page loaded for roll number: \(rollNumber)');
                setTimeout(initializeFaceIO, 500);
            });

            // Handle visibility changes
            document.addEventListener('visibilitychange', () => {
                if (document.hidden && isProcessing) {
                    log('Page became hidden during registration');
                    resetToReady('Registration interrupted');
                }
            });
        </script>
    </body>
    </html>
    """
}
