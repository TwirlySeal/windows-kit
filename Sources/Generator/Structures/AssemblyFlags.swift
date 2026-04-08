struct AssemblyFlags: OptionSet {
    let rawValue: UInt32

    static let PublicKey = 0x0001
    static let Retargetable = 0x0100
    static let DisableJITcompileOptimizer = 0x4000
    static let EnableJITcompileTracking = 0x8000
}