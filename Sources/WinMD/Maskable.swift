/// Used for structures in the metadata that require bitmasks to isolate bits of interest
/// Automatically adds an initializer that masks a raw value
protocol Maskable: RawRepresentable where RawValue: FixedWidthInteger {
	static var mask: RawValue { get }
}

extension Maskable {
	init?(masking rawValue: RawValue) {
		self.init(rawValue: rawValue & Self.mask)
	}
}
