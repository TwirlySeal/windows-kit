import WinMD
import SwiftSyntax
import SwiftSyntaxBuilder

func write(type: TypeDef) throws {
    let category = try type.category
    
    if type.flags.implementation.contains(.windowsRuntime) {
        // WinRT
        switch category {
        case .enum:
            try write(enum: type)
            
        case .delegate:
            print("WinRT delegate")
        case .struct:
            print("WinRT struct")
        case .attribute:
            // Attributes are looked up on other items
            print("WinRT attribute (ignored)")
            return
        case .class:
            print("WinRT class")
        case .interface:
            print("WinRT interface")
        }
    } else {
        // Win32
        switch category {
        case .enum:
            print("Win32 enum")
        case .delegate:
            print("Win32 delegate")
        case .struct:
            print("Win32 struct")
        case .attribute:
            // Attributes are looked up on other items
            print("Win32 attribute (ignored)")
            return
        case .class:
            let name = try type.name
            
            // The "Apis" class is used for Win32 functions and constants
            if name == "Apis" {
                for method in try type.methods {
                    print("Win32 method: \(try method.name)")
                }
                
                for field in try type.fields {
                    print("Win32 field: \(try field.name)")
                }
            } else {
                // Other non-WinRT classes do not contribute types
                return
            }
        case .interface:
            print("Win32 interface")
        }
    }
}
