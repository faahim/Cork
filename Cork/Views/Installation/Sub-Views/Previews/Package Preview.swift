//
//  Package Preview.swift
//  Cork
//
//  Created by David Bureš on 28.05.2024.
//

import SwiftUI

struct PackagePreview: View
{
    let packageToPreview: BrewPackage?
    let isShowingSelf: Bool
    
    var body: some View
    {
        VStack
        {
            if isShowingSelf
            {
                VStack
                {
                    if let packageToPreview
                    {
                        Text(packageToPreview.name)
                    }
                    else
                    {
                        ProgressView()
                    }
                }
            }
        }
    }
}

