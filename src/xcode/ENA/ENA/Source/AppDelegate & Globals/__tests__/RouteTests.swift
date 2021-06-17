////
// 🦠 Corona-Warn-App
//

import XCTest
import base45_swift
@testable import ENA

class RouteTests: CWATestCase {

	func testGIVEN_URLWithWrongPercentEncoding_WHEN_RemocePercentEncoding_THEN_URLIsCorrect() throws {
		// GIVEN
		// swiftlint:disable line_length
		let wrongPercentEscapedURL =
			"HC1:6BFOXN*TS0BI$ZD.P9UOL97O4-2HH77HRM3DSPTLRR+%3D%20H9M9ESIGUBA%20KWMLYX1HXK%200DV:D5VC9:BPCNYKMXEE1JAA/CZIK0JK1WL260X638J3-E3ND3DAJ-43TTTMDF6S8:B73QN%20VNZ.0K6HYI3CNN96BPHNW*0I85V.499TXY9KK9%25OC+G9QJPNF67J6QW67KQ9G66PPM4MLJE+.PDB9L6Q2+PFQ5DB96PP5/P-59A%25N+892%207J235II3NJ7PK7SLQMIPUBN9CIZI.EJJ14B2MP41IZRZPQEC5L64HX6IAS%208SAFT/MAMXP6QS03L0QIRR97I2HOAXL92L0.%20KOKGGVG5SI:TU+MMPZ55%25PBT1YEGEA7IB65C94JBQ2NLEE:NQ%25%20GC3MXHFLF9OIFN0IZ95LJL80P1FDLW452I8941:HH3M41GTNP8EFUNT$.FTD852IWKP/HLIJL8JF8JF172E2JA0K*WDQMPB8T3%25KLUSR43M.F$QBQDR$VT7V01Y7J0BOZLH+D-QF6MO$R3%25XB+.4QI596GY$SITJP5BS0DFROC.7B.2RTB*UNYSM$*00HIL+H"

		// WHEN
		let route = Route(wrongPercentEscapedURL)
		guard
			case let .certificate(base45) = route else {
			XCTFail("Wrong rout found")
			return
		}

		// THEN
		let correctBase45Payload =
			"HC1:6BFOXN*TS0BI$ZD.P9UOL97O4-2HH77HRM3DSPTLRR+%3D H9M9ESIGUBA KWMLYX1HXK 0DV:D5VC9:BPCNYKMXEE1JAA/CZIK0JK1WL260X638J3-E3ND3DAJ-43TTTMDF6S8:B73QN VNZ.0K6HYI3CNN96BPHNW*0I85V.499TXY9KK9%OC+G9QJPNF67J6QW67KQ9G66PPM4MLJE+.PDB9L6Q2+PFQ5DB96PP5/P-59A%N+892 7J235II3NJ7PK7SLQMIPUBN9CIZI.EJJ14B2MP41IZRZPQEC5L64HX6IAS 8SAFT/MAMXP6QS03L0QIRR97I2HOAXL92L0. KOKGGVG5SI:TU+MMPZ55%PBT1YEGEA7IB65C94JBQ2NLEE:NQ% GC3MXHFLF9OIFN0IZ95LJL80P1FDLW452I8941:HH3M41GTNP8EFUNT$.FTD852IWKP/HLIJL8JF8JF172E2JA0K*WDQMPB8T3%KLUSR43M.F$QBQDR$VT7V01Y7J0BOZLH+D-QF6MO$R3%XB+.4QI596GY$SITJP5BS0DFROC.7B.2RTB*UNYSM$*00HIL+H"

		XCTAssertEqual(correctBase45Payload, base45)
	}

	func testGIVEN_validRATUrlWithoutDGCInfo_WHEN_parseRoute_THEN_isValid() {
		// GIVEN
		let validRATTestURL = "https://s.coronawarn.app?v=1#eyJ0aW1lc3RhbXAiOjE2MTk2MTcyNjksInNhbHQiOiI3QkZBMDZCNUFEOTMxMUI4NzE5QkI4MDY2MUM1NEVBRCIsInRlc3RpZCI6ImI0YTQwYzZjLWUwMmMtNDQ0OC1iOGFiLTBiNWI3YzM0ZDYwYSIsImhhc2giOiIxZWE0YzIyMmZmMGMwZTRlZDczNzNmMjc0Y2FhN2Y3NWQxMGZjY2JkYWM1NmM2MzI3NzFjZDk1OTIxMDJhNTU1IiwiZm4iOiJIZW5yeSIsImxuIjoiUGluemFuaSIsImRvYiI6IjE5ODktMDgtMzAifQ"

		// WHEN
		let route = Route(validRATTestURL)

		// THEN
		guard
			case let .rapidAntigen(result) = route,
			case let .success(coronaTestRegistrationInformation) = result,
			case let .antigen(qrCodeInformation: antigenTestQRCodeInformation) = coronaTestRegistrationInformation
		else {
			XCTFail("unexpected route type")
			return
		}

		XCTAssertEqual(antigenTestQRCodeInformation.hash, "1ea4c222ff0c0e4ed7373f274caa7f75d10fccbdac56c632771cd9592102a555")
		XCTAssertEqual(antigenTestQRCodeInformation.timestamp, 1619617269)
		XCTAssertEqual(antigenTestQRCodeInformation.firstName, "Henry")
		XCTAssertEqual(antigenTestQRCodeInformation.lastName, "Pinzani")
		XCTAssertEqual(antigenTestQRCodeInformation.dateOfBirth, Date(timeIntervalSince1970: 620438400))
		XCTAssertEqual(antigenTestQRCodeInformation.testID, "b4a40c6c-e02c-4448-b8ab-0b5b7c34d60a")
		XCTAssertEqual(antigenTestQRCodeInformation.cryptographicSalt, "7BFA06B5AD9311B8719BB80661C54EAD")
		XCTAssertNil(antigenTestQRCodeInformation.certificateSupportedByPointOfCare)
	}

	func testGIVEN_invalidRATUrl_WHEN_parseRoute_THEN_isValid() {
		// GIVEN
		let validRATTestURL = "https://s.coronawarn.app?v=1#eJ0aW1lc3RhbXAiOjE2MTg0ODI2MzksImd1aWQiOiIzM0MxNDNENS0yMTgyLTQ3QjgtOTM4NS02ODBGMzE4RkU0OTMiLCJmbiI6IlJveSIsImxuIjoiRnJhc3NpbmV0aSIsImRvYiI6IjE5ODEtMTItMDEifQ=="

		// WHEN
		let route = Route(validRATTestURL)
		guard case let .rapidAntigen(result) = route else {
			XCTFail("unexpected route type")
			return
		}

		// THEN
		switch result {
		case .success:
			XCTFail("Route parse success wasn't expected")
		case .failure:
			break
		}
	}

	func testGIVEN_InvalidURLString_WHEN_createRoute_THEN_RouteIsNil() {
		// GIVEN
		let invalidRATTestURL = "http:s.coronawarn.app?v=1#eJ0aW1lc3RhbXAiOjE2MTg0ODI2MzksImd1aWQiOiIzM0MxNDNENS0yMTgyLTQ3QjgtOTM4NS02ODBGMzE4RkU0OTMiLCJmbiI6IlJveSIsImxuIjoiRnJhc3NpbmV0aSIsImRvYiI6IjE5ODEtMTItMDEifQ=="

		// WHEN
		let route = Route(invalidRATTestURL)

		// THEN
		XCTAssertNil(route)
	}

	func testGIVEN_InvalidTestInformation_WHEN_Route_THEN_FailureInvalidHash() throws {
		// GIVEN
		let antigenTest = AntigenTestQRCodeInformation.mock(
			hash: "1ea4c222ff0c0e4ed7373f274caa7f75d10fccbdac56c632771cd9592102a55",
			timestamp: 1619617269,
			firstName: "Henry",
			lastName: "Pinzani",
			cryptographicSalt: "7BFA06B5AD9311B8719BB80661C54EAD",
			testID: "b4a40c6c-e02c-4448-b8ab-0b5b7c34d60a",
			dateOfBirth: Date(timeIntervalSince1970: 620438400),
			certificateSupportedByPointOfCare: true
		)

		let jsonData = try JSONEncoder().encode(antigenTest)
		let base64 = jsonData.base64EncodedString()
		let url = try XCTUnwrap(URLComponents(string: String(format: "https://s.coronawarn.app?v=1#%@", base64))?.url)

		// WHEN
		let route = Route(url: url)

		// THEN
		XCTAssertEqual(route, .rapidAntigen(.failure(.invalidTestCode(.invalidHash))))
	}

	func testGIVEN_InvalidTestInformation_WHEN_Route_THEN_FailureInvalidTimeStamp() throws {
		// GIVEN
		let antigenTest = AntigenTestQRCodeInformation.mock(
			hash: "1ea4c222ff0c0e4ed7373f274caa7f75d10fccbdac56c632771cd9592102a555",
			timestamp: -5,
			firstName: "Henry",
			lastName: "Pinzani",
			cryptographicSalt: "7BFA06B5AD9311B8719BB80661C54EAD",
			testID: "b4a40c6c-e02c-4448-b8ab-0b5b7c34d60a",
			dateOfBirth: Date(timeIntervalSince1970: 620438400),
			certificateSupportedByPointOfCare: true
		)

		let jsonData = try JSONEncoder().encode(antigenTest)
		let base64 = jsonData.base64EncodedString()
		let url = try XCTUnwrap(URLComponents(string: String(format: "https://s.coronawarn.app?v=1#%@", base64))?.url)

		// WHEN
		let route = Route(url: url)

		// THEN
		XCTAssertEqual(route, .rapidAntigen(.failure(.invalidTestCode(.invalidTimeStamp))))
	}

	func testGIVEN_InvalidTestInformation_WHEN_URLWithMissingV1_THEN_RouteIsNil() throws {
		// GIVEN
		let antigenTest = AntigenTestQRCodeInformation.mock(
			hash: "1ea4c222ff0c0e4ed7373f274caa7f75d10fccbdac56c632771cd9592102a555",
			timestamp: 1619617269,
			firstName: "Henry",
			lastName: "Pinzani",
			cryptographicSalt: "7BFA06B5AD9311B8719BB80661C54EAD",
			testID: "b4a40c6c-e02c-4448-b8ab-0b5b7c34d60a",
			dateOfBirth: Date(timeIntervalSince1970: 620438400),
			certificateSupportedByPointOfCare: true
		)

		let jsonData = try JSONEncoder().encode(antigenTest)
		let base64 = jsonData.base64EncodedString()
		let url = try XCTUnwrap(URLComponents(string: String(format: "https://s.coronawarn.app#%@", base64))?.url)

		// WHEN
		let route = Route(url: url)

		// THEN
		XCTAssertNil(route)
	}

	func testGIVEN_InvalidTestInformation_WHEN_FirstNameLastNameMiggingButDateOfBirthIsGiven_THEN_FailureInvalidTestedPersonInformation() throws {
		// GIVEN
		let antigenTest = AntigenTestQRCodeInformation.mock(
			hash: "1ea4c222ff0c0e4ed7373f274caa7f75d10fccbdac56c632771cd9592102a555",
			timestamp: 1619617269,
			firstName: nil,
			lastName: nil,
			cryptographicSalt: "7BFA06B5AD9311B8719BB80661C54EAD",
			testID: "b4a40c6c-e02c-4448-b8ab-0b5b7c34d60a",
			dateOfBirth: Date(timeIntervalSince1970: 620438400),
			certificateSupportedByPointOfCare: true
		)

		let jsonData = try JSONEncoder().encode(antigenTest)
		let base64 = jsonData.base64EncodedString()
		let url = try XCTUnwrap(URLComponents(string: String(format: "https://s.coronawarn.app?v=1#%@", base64))?.url)

		// WHEN
		let route = Route(url: url)

		// THEN
		XCTAssertEqual(route, .rapidAntigen(.failure(.invalidTestCode(.invalidTestedPersonInformation))))
	}

}
