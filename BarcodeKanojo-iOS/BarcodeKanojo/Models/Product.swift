import Foundation

/// Product/barcode information model.
/// Source: Product.java + ProductParser.java
struct Product: Codable, Hashable, Sendable {

    var barcode: String?
    var name: String?
    var categoryId: Int
    var category: String?
    var comment: String?
    var location: String?
    /// Geo coordinates as comma-separated "lat,lng" string.
    var geo: String?
    var scanCount: Int
    var companyName: String?
    var country: String?
    var price: String?
    var product: String?

    // MARK: - Computed Properties

    var productImageURL: String? {
        guard let barcode, let product else { return nil }
        return "/product_images/barcode/\(barcode)/\(product).png"
    }

    // MARK: - Default Initializer

    init(
        barcode: String? = nil,
        name: String? = nil,
        categoryId: Int = 1,
        category: String? = nil,
        comment: String? = nil,
        location: String? = nil,
        geo: String? = nil,
        scanCount: Int = 0,
        companyName: String? = nil,
        country: String? = nil,
        price: String? = nil,
        product: String? = nil
    ) {
        self.barcode = barcode
        self.name = name
        self.categoryId = categoryId
        self.category = category
        self.comment = comment
        self.location = location
        self.geo = geo
        self.scanCount = scanCount
        self.companyName = companyName
        self.country = country
        self.price = price
        self.product = product
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case barcode, name, category, comment, location, geo, country, price, product
        case categoryId = "category_id"
        case scanCount = "scan_count"
        case companyName = "company_name"
    }

    // MARK: - Custom Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        barcode = try container.decodeIfPresent(String.self, forKey: .barcode)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        categoryId = try container.decodeIfPresent(Int.self, forKey: .categoryId) ?? 1
        category = try container.decodeIfPresent(String.self, forKey: .category)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        // geo can be a "lat,lng" string or a {"lat":...,"lng":...} object
        if let geoString = try? container.decodeIfPresent(String.self, forKey: .geo) {
            geo = geoString
        } else if let geoObject = try? container.decodeIfPresent(GeoObject.self, forKey: .geo) {
            geo = "\(geoObject.lat),\(geoObject.lng)"
        } else {
            geo = nil
        }
        scanCount = try container.decodeIfPresent(Int.self, forKey: .scanCount) ?? 0
        companyName = try container.decodeIfPresent(String.self, forKey: .companyName)
        country = try container.decodeIfPresent(String.self, forKey: .country)
        price = try container.decodeIfPresent(String.self, forKey: .price)
        product = try container.decodeIfPresent(String.self, forKey: .product)
    }
}

// MARK: - Geo Object Helper

private struct GeoObject: Codable {
    let lat: Double
    let lng: Double
}
