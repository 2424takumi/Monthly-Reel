import CoreImage

/// Color grading presets available for monthly reels.
/// Each preset defines a chain of CIFilters applied to the video output.
enum ColorPreset: String, CaseIterable, Codable {
    case cinematic = "CINEMATIC"
    case film      = "FILM"
    case clean     = "CLEAN"
    case mono      = "MONO"
    case warm      = "WARM"

    var displayName: String { rawValue }

    var filters: [CIFilter] {
        switch self {
        case .clean:
            return Self.cleanFilters
        case .cinematic:
            return Self.cinematicFilters
        case .film:
            return Self.filmFilters
        case .mono:
            return Self.monoFilters
        case .warm:
            return Self.warmFilters
        }
    }

    // MARK: - Filter Definitions

    private static var cleanFilters: [CIFilter] {
        guard let unsharp = CIFilter(name: "CIUnsharpMask", parameters: [
            "inputRadius": 1.5,
            "inputIntensity": 0.3
        ]) else { return [] }
        return [unsharp]
    }

    private static var cinematicFilters: [CIFilter] {
        var result: [CIFilter] = []
        if let contrast = CIFilter(name: "CIColorControls", parameters: [
            "inputContrast": 1.15,
            "inputSaturation": 0.85
        ]) {
            result.append(contrast)
        }
        if let matrix = CIFilter(name: "CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 1.05, y: 0.0, z: -0.05, w: 0),
            "inputGVector": CIVector(x: 0.0, y: 0.95, z: 0.0, w: 0),
            "inputBVector": CIVector(x: -0.1, y: 0.05, z: 1.1, w: 0)
        ]) {
            result.append(matrix)
        }
        if let vignette = CIFilter(name: "CIVignette", parameters: [
            "inputIntensity": 0.4,
            "inputRadius": 1.8
        ]) {
            result.append(vignette)
        }
        return result
    }

    private static var filmFilters: [CIFilter] {
        var result: [CIFilter] = []
        if let controls = CIFilter(name: "CIColorControls", parameters: [
            "inputSaturation": 0.75,
            "inputBrightness": 0.03
        ]) {
            result.append(controls)
        }
        if let temp = CIFilter(name: "CITemperatureAndTint", parameters: [
            "inputNeutral": CIVector(x: 6500, y: 0),
            "inputTargetNeutral": CIVector(x: 5500, y: 0)
        ]) {
            result.append(temp)
        }
        return result
    }

    private static var monoFilters: [CIFilter] {
        var result: [CIFilter] = []
        if let mono = CIFilter(name: "CIColorMonochrome", parameters: [
            "inputColor": CIColor(red: 0.9, green: 0.9, blue: 0.9),
            "inputIntensity": 1.0
        ]) {
            result.append(mono)
        }
        if let contrast = CIFilter(name: "CIColorControls", parameters: [
            "inputContrast": 1.1
        ]) {
            result.append(contrast)
        }
        return result
    }

    private static var warmFilters: [CIFilter] {
        var result: [CIFilter] = []
        if let temp = CIFilter(name: "CITemperatureAndTint", parameters: [
            "inputNeutral": CIVector(x: 6500, y: 0),
            "inputTargetNeutral": CIVector(x: 4800, y: 0)
        ]) {
            result.append(temp)
        }
        if let controls = CIFilter(name: "CIColorControls", parameters: [
            "inputSaturation": 1.15,
            "inputBrightness": 0.02
        ]) {
            result.append(controls)
        }
        return result
    }
}

// MARK: - ColorGrading Protocol

protocol ColorGrading {
    var filters: [CIFilter] { get }
    func apply(to image: CIImage) -> CIImage
}

extension ColorGrading {
    func apply(to image: CIImage) -> CIImage {
        filters.reduce(image) { img, filter in
            filter.setValue(img, forKey: kCIInputImageKey)
            return filter.outputImage ?? img
        }
    }
}

extension ColorPreset: ColorGrading {}
