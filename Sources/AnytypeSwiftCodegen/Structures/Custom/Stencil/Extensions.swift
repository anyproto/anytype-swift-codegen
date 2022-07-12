import Foundation
import Stencil

extension Extension {
    
    static let `default`: Extension = {
        let ext = Extension()
        ext.registerFilter("removeNewLines", filter: Filter.removeNewlines)
        ext.registerFilter("removeEmptyLines", filter: Filter.removeEmptyLines)
        return ext
    }()
    
}
