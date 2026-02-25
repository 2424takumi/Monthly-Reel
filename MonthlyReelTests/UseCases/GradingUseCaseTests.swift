import XCTest
import CoreImage
@testable import MonthlyReel

final class GradingUseCaseTests: XCTestCase {

    // MARK: - Filter Chain Completeness

    func test_allPresets_haveNonEmptyFilterChain() {
        // Arrange
        let presets = ColorPreset.allCases

        // Act & Assert
        for preset in presets {
            XCTAssertFalse(
                preset.filters.isEmpty,
                "\(preset.rawValue) should have at least one CIFilter"
            )
        }
    }

    // MARK: - Clean Preset Filters

    func test_cleanPreset_producesOutput() {
        // Arrange
        let preset = ColorPreset.clean
        let filters = preset.filters

        // Act & Assert
        XCTAssertFalse(filters.isEmpty)
        // Clean preset uses CIUnsharpMask
        let filterNames = filters.compactMap { $0.name }
        XCTAssertTrue(
            filterNames.contains("CIUnsharpMask"),
            "Clean preset should include CIUnsharpMask filter"
        )
    }

    // MARK: - Cinematic Preset Filters

    func test_cinematicPreset_hasExpectedFilters() {
        // Arrange
        let preset = ColorPreset.cinematic
        let filters = preset.filters

        // Act
        let filterNames = filters.compactMap { $0.name }

        // Assert: cinematic uses contrast, color matrix, and vignette
        XCTAssertTrue(filterNames.contains("CIColorControls"))
        XCTAssertTrue(filterNames.contains("CIColorMatrix"))
        XCTAssertTrue(filterNames.contains("CIVignette"))
    }

    // MARK: - Mono Preset Filters

    func test_monoPreset_includesMonochromeFilter() {
        // Arrange
        let preset = ColorPreset.mono
        let filters = preset.filters

        // Act
        let filterNames = filters.compactMap { $0.name }

        // Assert
        XCTAssertTrue(
            filterNames.contains("CIColorMonochrome"),
            "Mono preset should include CIColorMonochrome filter"
        )
    }

    // MARK: - Apply to CIImage

    func test_colorGrading_applyProducesNonNilOutput() {
        // Arrange: create a simple 1x1 red CIImage
        let color = CIColor(red: 1.0, green: 0.0, blue: 0.0)
        let image = CIImage(color: color).cropped(
            to: CGRect(x: 0, y: 0, width: 100, height: 100)
        )

        // Act & Assert: verify each preset produces output
        for preset in ColorPreset.allCases {
            let output = preset.apply(to: image)
            XCTAssertFalse(
                output.extent.isEmpty,
                "\(preset.rawValue) should produce non-empty output"
            )
        }
    }

    // MARK: - Warm Preset Filters

    func test_warmPreset_hasTemperatureFilter() {
        // Arrange
        let preset = ColorPreset.warm
        let filters = preset.filters

        // Act
        let filterNames = filters.compactMap { $0.name }

        // Assert
        XCTAssertTrue(
            filterNames.contains("CITemperatureAndTint"),
            "Warm preset should include CITemperatureAndTint filter"
        )
    }

    // MARK: - Film Preset Filters

    func test_filmPreset_hasDesaturationAndTemperature() {
        // Arrange
        let preset = ColorPreset.film
        let filters = preset.filters

        // Act
        let filterNames = filters.compactMap { $0.name }

        // Assert
        XCTAssertTrue(filterNames.contains("CIColorControls"))
        XCTAssertTrue(filterNames.contains("CITemperatureAndTint"))
    }

    // MARK: - Preset Codable

    func test_colorPreset_codableRoundTrip() throws {
        // Arrange
        for preset in ColorPreset.allCases {
            // Act
            let data = try JSONEncoder().encode(preset)
            let decoded = try JSONDecoder().decode(
                ColorPreset.self, from: data
            )

            // Assert
            XCTAssertEqual(preset, decoded)
        }
    }

    // MARK: - GradingUseCase Initialization

    func test_gradingUseCase_canBeInitialized() {
        // Act
        let useCase = GradingUseCase()

        // Assert: simply verify initialization succeeds
        XCTAssertNotNil(useCase)
    }
}
