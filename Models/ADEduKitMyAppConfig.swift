//
//  ADEduKitContentAppConfig.swift
//  ADEduKitContentApp
//
//  Created by Schwarze on 23.12.21.
//

import Foundation
import ADEduKit

public class ADEduKitMyAppConfig: AppConfig {
    override public init() {
        super.init()
    }
    
    override open func standardContainerName() -> String {
        return "adedukitcontentapp"
    }

    override open func standardScheme() -> String {
        return "com.admadic.adedukit.adedukitcontentapp"
    }
}
