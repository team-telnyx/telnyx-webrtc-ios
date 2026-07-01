//
//  MOSCalculatorTests.swift
//  TelnyxRTCTests
//
//  Regression coverage for IOS-C27 (VSDK-338): NaN / infinity inputs must
//  surface as `.unknown` quality, and quality bands must be continuous
//  with no gaps between `good`, `fair`, and `poor`.
//

import XCTest
@testable import TelnyxRTC

final class MOSCalculatorTests: XCTestCase {

    // MARK: - calculateMOS finite / non-finite behavior

    /// Inputs reported as `.infinity` (e.g. when remote inbound stats are
    /// absent in `WebRTCStatsReporter`) must produce NaN instead of a
    /// clamped `5.0` that maps to `.excellent`.
    func testCalculateMOS_returnsNaN_forInfiniteJitter() {
        let result = MOSCalculator.calculateMOS(
            jitter: Double.infinity,
            rtt: 50,
            packetsReceived: 100,
            packetsLost: 0
        )
        XCTAssertTrue(result.isNaN, "Expected NaN for infinite jitter, got \(result)")
    }

    func testCalculateMOS_returnsNaN_forInfiniteRTT() {
        let result = MOSCalculator.calculateMOS(
            jitter: 20,
            rtt: Double.infinity,
            packetsReceived: 100,
            packetsLost: 0
        )
        XCTAssertTrue(result.isNaN, "Expected NaN for infinite RTT, got \(result)")
    }

    func testCalculateMOS_returnsNaN_forNegativeInfiniteRTT() {
        let result = MOSCalculator.calculateMOS(
            jitter: 20,
            rtt: -Double.infinity,
            packetsReceived: 100,
            packetsLost: 0
        )
        XCTAssertTrue(result.isNaN, "Expected NaN for -infinite RTT, got \(result)")
    }

    func testCalculateMOS_clampsValidInputsToRange() {
        // Zero packet loss, low jitter, low RTT should produce a high MOS.
        let goodResult = MOSCalculator.calculateMOS(
            jitter: 5,
            rtt: 20,
            packetsReceived: 1000,
            packetsLost: 0
        )
        XCTAssertGreaterThanOrEqual(goodResult, 1.0)
        XCTAssertLessThanOrEqual(goodResult, 5.0)
        XCTAssertFalse(goodResult.isNaN)

        // Heavy packet loss should still produce a finite in-range MOS.
        let lossyResult = MOSCalculator.calculateMOS(
            jitter: 200,
            rtt: 400,
            packetsReceived: 10,
            packetsLost: 990
        )
        XCTAssertGreaterThanOrEqual(lossyResult, 1.0)
        XCTAssertLessThanOrEqual(lossyResult, 5.0)
        XCTAssertFalse(lossyResult.isNaN)
    }

    // MARK: - getQuality non-finite handling

    func testGetQuality_returnsUnknown_forNaN() {
        XCTAssertEqual(MOSCalculator.getQuality(mos: .nan), .unknown)
    }

    func testGetQuality_returnsUnknown_forPositiveInfinity() {
        XCTAssertEqual(MOSCalculator.getQuality(mos: .infinity), .unknown)
    }

    func testGetQuality_returnsUnknown_forNegativeInfinity() {
        XCTAssertEqual(MOSCalculator.getQuality(mos: -.infinity), .unknown)
    }

    // MARK: - getQuality band continuity (regression for the band gaps)

    func testGetQuality_excellent_band_above_4_2() {
        XCTAssertEqual(MOSCalculator.getQuality(mos: 4.3), .excellent)
        XCTAssertEqual(MOSCalculator.getQuality(mos: 5.0), .excellent)
    }

    func testGetQuality_good_band_4_1_to_4_2() {
        XCTAssertEqual(MOSCalculator.getQuality(mos: 4.2), .good)
        XCTAssertEqual(MOSCalculator.getQuality(mos: 4.15), .good)
    }

    /// Previously these values fell through to `.bad` because of the
    /// `4.1 <= mos <= 4.2` / `3.7 <= mos <= 4.0` inclusive upper bounds.
    func testGetQuality_closesGap_betweenGoodAndFair() {
        XCTAssertEqual(MOSCalculator.getQuality(mos: 4.05), .good)
        XCTAssertEqual(MOSCalculator.getQuality(mos: 4.0), .good)
    }

    func testGetQuality_fair_band_3_7_to_4_0() {
        XCTAssertEqual(MOSCalculator.getQuality(mos: 3.8), .fair)
        XCTAssertEqual(MOSCalculator.getQuality(mos: 4.0), .fair)
    }

    /// Previously these values fell through to `.bad` because of the
    /// `3.7 <= mos <= 4.0` / `3.1 <= mos <= 3.6` inclusive upper bounds.
    func testGetQuality_closesGap_betweenFairAndPoor() {
        XCTAssertEqual(MOSCalculator.getQuality(mos: 3.65), .fair)
        XCTAssertEqual(MOSCalculator.getQuality(mos: 3.7), .fair)
    }

    func testGetQuality_poor_band_3_1_to_3_6() {
        XCTAssertEqual(MOSCalculator.getQuality(mos: 3.1), .poor)
        XCTAssertEqual(MOSCalculator.getQuality(mos: 3.5), .poor)
    }

    func testGetQuality_bad_band_below_3_1() {
        XCTAssertEqual(MOSCalculator.getQuality(mos: 3.0), .bad)
        XCTAssertEqual(MOSCalculator.getQuality(mos: 1.0), .bad)
        XCTAssertEqual(MOSCalculator.getQuality(mos: 0.0), .bad)
        XCTAssertEqual(MOSCalculator.getQuality(mos: -1.0), .bad)
    }

    // MARK: - End-to-end: calculateMOS -> getQuality

    /// NaN flowing out of `calculateMOS` must produce `.unknown` so the
    /// host app never sees a misleading "excellent" or "bad" rating when
    /// the underlying WebRTC stats are missing.
    func testCalculateMOS_thenGetQuality_returnsUnknown_forNonFiniteInputs() {
        let mos = MOSCalculator.calculateMOS(
            jitter: Double.infinity,
            rtt: 50,
            packetsReceived: 100,
            packetsLost: 0
        )
        XCTAssertEqual(MOSCalculator.getQuality(mos: mos), .unknown)
    }
}
