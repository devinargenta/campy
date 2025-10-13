// File: CameraViewUITests.swift
// Target: cambarUITests

import XCTest

final class CameraViewUITests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    func testPreviewExistsWhenWindowShown() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UIShowWindow", "-UIForceNotRunning"]
        app.launch()
        
        // The preview container should exist
        let preview = app.windows.element(boundBy: 0).descendants(matching: .any)["CameraPreview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 3.0))
    }
    
    func testDoubleTapShowsScreenshotOverlay() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UIShowWindow", "-UIForceNotRunning"]
        app.launch()
        
        let preview = app.windows.element(boundBy: 0).descendants(matching: .any)["CameraPreview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 3.0))
        
        // Double-tap on preview
        preview.doubleTap()
        
        // The overlay should appear
        let overlay = app.windows.element(boundBy: 0).descendants(matching: .any)["ScreenshotOverlay"]
        XCTAssertTrue(overlay.waitForExistence(timeout: 2.0))
    }
    
    func testErrorStateAndRefreshButton() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UIShowWindow", "-UIForceError"]
        app.launch()
        
        let errorMessage = app.staticTexts["ErrorMessage"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 3.0))
        
        let refreshButton = app.buttons["ErrorRefreshButton"]
        XCTAssertTrue(refreshButton.exists)
        
        // Tap refresh to clear the error and reconfigure
        refreshButton.click()
        
        // After refresh, the error UI should eventually disappear
        XCTAssertFalse(errorMessage.waitForExistence(timeout: 2.0))
    }
    
    func testProgressViewWhenSessionNotRunning() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UIShowWindow", "-UIForceNotRunning"]
        app.launch()
        
        // When session is not running, our background overlay includes a ProgressView.
        // XCTest may see it as a progress indicator element.
        let progressIndicators = app.windows.element(boundBy: 0).descendants(matching: .progressIndicator)
        XCTAssertTrue(progressIndicators.element(boundBy: 0).waitForExistence(timeout: 3.0))
    }
}
