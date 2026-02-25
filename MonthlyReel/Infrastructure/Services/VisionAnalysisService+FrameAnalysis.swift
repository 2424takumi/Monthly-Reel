import Vision
import CoreImage
import Foundation

// MARK: - Sharpness

extension VisionAnalysisService {

    func computeSharpness(from cgImage: CGImage) async throws -> Double {
        let ciImage = CIImage(cgImage: cgImage)
        let extent = ciImage.extent

        guard let laplacian = CIFilter(
            name: "CIConvolution3X3",
            parameters: [
                kCIInputImageKey: ciImage,
                "inputWeights": CIVector(values: [
                    0, 1, 0,
                    1, -4, 1,
                    0, 1, 0
                ], count: 9),
                "inputBias": 0.5
            ]
        ), let laplacianOutput = laplacian.outputImage else {
            return 0.0
        }

        guard let avgFilter = CIFilter(
            name: "CIAreaAverage",
            parameters: [
                kCIInputImageKey: laplacianOutput,
                kCIInputExtentKey: CIVector(cgRect: extent)
            ]
        ), let avgOutput = avgFilter.outputImage else {
            return 0.0
        }

        return readSharpnessValue(from: avgOutput)
    }

    func readSharpnessValue(from avgOutput: CIImage) -> Double {
        var pixel = [UInt8](
            repeating: 0,
            count: Constants.averagePixelByteCount
        )
        ciContext.render(
            avgOutput,
            toBitmap: &pixel,
            rowBytes: Constants.averagePixelByteCount,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        let deviation = abs(Double(pixel[0]) / 255.0 - 0.5) * 2.0
        let rawVariance = deviation * deviation
            * Constants.sharpnessNormalizationDivisor
        return min(
            max(rawVariance / Constants.sharpnessNormalizationDivisor, 0.0),
            1.0
        )
    }
}

// MARK: - Brightness

extension VisionAnalysisService {

    func computeBrightness(from cgImage: CGImage) async throws -> Double {
        let ciImage = CIImage(cgImage: cgImage)
        let extent = ciImage.extent

        guard let avgFilter = CIFilter(
            name: "CIAreaAverage",
            parameters: [
                kCIInputImageKey: ciImage,
                kCIInputExtentKey: CIVector(cgRect: extent)
            ]
        ), let avgOutput = avgFilter.outputImage else {
            return 0.0
        }

        return readLuminanceValue(from: avgOutput)
    }

    func readLuminanceValue(from avgOutput: CIImage) -> Double {
        var pixel = [UInt8](
            repeating: 0,
            count: Constants.averagePixelByteCount
        )
        ciContext.render(
            avgOutput,
            toBitmap: &pixel,
            rowBytes: Constants.averagePixelByteCount,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        let red = Double(pixel[0]) / 255.0
        let green = Double(pixel[1]) / 255.0
        let blue = Double(pixel[2]) / 255.0

        let luminance = Constants.luminanceRedCoefficient * red
            + Constants.luminanceGreenCoefficient * green
            + Constants.luminanceBlueCoefficient * blue

        return min(max(luminance, 0.0), 1.0)
    }
}

// MARK: - Face Detection

extension VisionAnalysisService {

    func detectFace(in cgImage: CGImage) async throws -> Bool {
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNDetectFaceRectanglesRequest()

        try handler.perform([request])

        guard let results = request.results else {
            return false
        }
        return !results.isEmpty
    }
}
