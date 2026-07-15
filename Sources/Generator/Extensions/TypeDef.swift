import WinMD

extension TypeDef {
    enum Category {
        case `enum`
        case delegate
        case `struct`
        case attribute
        case `class`
        case interface
    }
    
    var category: Category {
        get throws {
            guard let extends = try self.extends else {
                return .interface
            }
            
            guard try extends.namespace == "System" else {
                return .class
            }
            
            return switch try extends.name {
            case "Enum":
                .enum
                
            case "MulticastDelegate":
                .delegate
                
            case "ValueType":
                .struct
                
            case "Attribute":
                .attribute
                
            default:
                .class
            }
        }
    }
}
