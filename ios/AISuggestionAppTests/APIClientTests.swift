import XCTest
@testable import AISuggestionApp

final class APIClientTests: XCTestCase {
    func testDeviceIdentifierFormat() {
        let deviceId = DeviceIdentifier.current
        XCTAssertTrue(deviceId.hasPrefix("ios-"))
        XCTAssertTrue(deviceId.count >= 8)
        XCTAssertTrue(deviceId.count <= 128)
    }

    func testAPIKeyObfuscationRoundtrip() {
        let testKey = "abcdefghijklmnopqrstuvwxyz012345"
        let obfuscated = APIKeyObfuscation.obfuscate(plainKey: testKey)
        let xorKey: [UInt8] = [
            0x4A, 0x7B, 0x2C, 0x5D, 0x1E, 0x6F, 0x38, 0x09,
            0x5A, 0x3B, 0x0C, 0x7D, 0x2E, 0x4F, 0x18, 0x69,
            0x4A, 0x7B, 0x2C, 0x5D, 0x1E, 0x6F, 0x38, 0x09,
            0x5A, 0x3B, 0x0C, 0x7D, 0x2E, 0x4F, 0x18, 0x69,
        ]
        let decoded = zip(obfuscated, xorKey).map { $0 ^ $1 }
        let result = String(bytes: decoded, encoding: .utf8)
        XCTAssertEqual(result, testKey)
    }

    func testTripRequestEncoding() throws {
        let request = TripRequest(
            destination: "Tokyo",
            origin: nil,
            startDate: "2026-06-01",
            endDate: "2026-06-03",
            budget: .midRange,
            travelStyle: .moderate,
            interests: ["food", "history"],
            dietaryRestrictions: [],
            notes: nil
        )
        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["destination"] as? String, "Tokyo")
        XCTAssertEqual(json["start_date"] as? String, "2026-06-01")
        XCTAssertEqual(json["budget"] as? String, "mid_range")
        XCTAssertEqual(json["travel_style"] as? String, "moderate")
    }

    func testItineraryDecoding() throws {
        let json = """
        {
            "destination": "Tokyo",
            "duration_days": 3,
            "budget_level": "mid_range",
            "summary": "A great trip",
            "hotels": [{"name": "Hotel A", "area": "Shibuya", "price_range": "$100-150"}],
            "days": [{"day_number": 1, "date": "2026-06-01", "activities": [
                {"time": "09:00", "title": "Temple", "description": "Visit temple", "location": "Asakusa"}
            ]}],
            "packing_tips": ["umbrella"],
            "estimated_total_cost": "$800"
        }
        """
        let data = json.data(using: .utf8)!
        let itinerary = try JSONDecoder().decode(Itinerary.self, from: data)
        XCTAssertEqual(itinerary.destination, "Tokyo")
        XCTAssertEqual(itinerary.durationDays, 3)
        XCTAssertEqual(itinerary.days.count, 1)
        XCTAssertEqual(itinerary.days[0].activities.count, 1)
        XCTAssertEqual(itinerary.hotels[0].name, "Hotel A")
    }
}
