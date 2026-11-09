import Foundation
import Vision

enum VisionTextRecognizer {
    nonisolated static func recognize(_ imageData: Data) async throws -> String {
        try await Task.detached {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            try VNImageRequestHandler(data: imageData).perform([request])
            let lines = (request.results ?? []).compactMap { observation -> (CGFloat, CGFloat, String)? in
                guard let text = observation.topCandidates(1).first?.string else { return nil }
                return (observation.boundingBox.maxY, observation.boundingBox.minX, text)
            }
            return lines.sorted {
                if $0.0 != $1.0 { return $0.0 > $1.0 }
                return $0.1 < $1.1
            }.map(\.2).joined(separator: "\n")
        }.value
    }
}
