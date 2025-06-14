import Foundation

// MARK: - Face.io Authentication Models

struct FaceIOResult {
    let rollNumber: String
    let success: Bool
    let timestamp: Date
    let message: String?
    
    init(rollNumber: String, success: Bool = true, message: String? = nil) {
        self.rollNumber = rollNumber
        self.success = success
        self.timestamp = Date()
        self.message = message
    }
}

enum FaceIOError: Error, LocalizedError {
    case cameraPermissionDenied
    case noFaceDetected
    case faceNotRecognized
    case multipleFacesDetected
    case faceSpoofingDetected
    case networkError
    case wrongPinCode
    case processingError
    case unauthorized
    case termsNotAccepted
    case uiNotReady
    case sessionExpired
    case operationTimedOut
    case tooManyRequests
    case initializationFailed
    case unknown(code: Int)
    
    var errorDescription: String? {
        switch self {
        case .cameraPermissionDenied:
            return "Camera permission denied"
        case .noFaceDetected:
            return "No face detected. Please position your face in the camera"
        case .faceNotRecognized:
            return "Face not recognized. Please register first"
        case .multipleFacesDetected:
            return "Multiple faces detected. Please ensure only one face is visible"
        case .faceSpoofingDetected:
            return "Face spoofing detected"
        case .networkError:
            return "Network error. Please check your connection"
        case .wrongPinCode:
            return "Wrong PIN code"
        case .processingError:
            return "Processing error. Please try again"
        case .unauthorized:
            return "Unauthorized. Please check application settings"
        case .termsNotAccepted:
            return "Terms not accepted"
        case .uiNotReady:
            return "UI not ready. Please refresh and try again"
        case .sessionExpired:
            return "Session expired. Please try again"
        case .operationTimedOut:
            return "Operation timed out. Please try again"
        case .tooManyRequests:
            return "Too many requests. Please wait a moment"
        case .initializationFailed:
            return "Failed to initialize Face.io"
        case .unknown(let code):
            return "Unknown error occurred (Code: \(code))"
        }
    }
    
    static func fromErrorCode(_ code: Int) -> FaceIOError {
        switch code {
        case 1: return .cameraPermissionDenied
        case 2: return .noFaceDetected
        case 3: return .faceNotRecognized
        case 4: return .multipleFacesDetected
        case 5: return .faceSpoofingDetected
        case 7: return .networkError
        case 8: return .wrongPinCode
        case 9: return .processingError
        case 10: return .unauthorized
        case 11: return .termsNotAccepted
        case 12: return .uiNotReady
        case 13: return .sessionExpired
        case 14: return .operationTimedOut
        case 15: return .tooManyRequests
        default: return .unknown(code: code)
        }
    }
}

// MARK: - Attendance Session Model
struct AttendanceSession {
    let id = UUID()
    let device: BLEDevice
    let subjectCode: String
    let startTime: Date
    var faceIOResult: FaceIOResult?
    var isCompleted: Bool = false
    
    init(device: BLEDevice, subjectCode: String) {
        self.device = device
        self.subjectCode = subjectCode
        self.startTime = Date()
    }
    
    mutating func complete(with result: FaceIOResult) {
        self.faceIOResult = result
        self.isCompleted = true
    }
}
