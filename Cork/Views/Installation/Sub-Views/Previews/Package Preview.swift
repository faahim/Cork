//
//  Package Preview.swift
//  Cork
//
//  Created by David Bureš on 28.05.2024.
//

import SwiftUI
import SwiftyJSON

struct PackagePreview: View
{
    let packageToPreview: BrewPackage?
    let isShowingSelf: Bool

    @State private var description: String = ""
    @State private var homepage: URL = .init(string: "https://google.com")!
    @State private var tap: String = ""
    @State private var dependencies: [BrewPackageDependency]? = nil

    @State private var isShowingExpandedDependencies: Bool = false

    @State private var isLoadingPackageDetails: Bool = true

    var body: some View
    {
        if isShowingSelf
        {
            VStack
            {
                if let packageToPreview
                {
                    FullSizeGroupedForm
                    {
                        if !isLoadingPackageDetails
                        {
                            Section
                            {
                                LabeledContent
                                {
                                    Text(tap)
                                } label: {
                                    Text("Tap")
                                }

                                LabeledContent
                                {
                                    if packageToPreview.isCask
                                    {
                                        Text("package-details.type.cask")
                                    }
                                    else
                                    {
                                        Text("package-details.type.formula")
                                    }
                                } label: {
                                    Text("package-details.type")
                                }

                                LabeledContent
                                {
                                    Link(destination: homepage)
                                    {
                                        Text(homepage.absoluteString)
                                    }
                                } label: {
                                    Text("package-details.homepage")
                                }
                            } header: {
                                if !isLoadingPackageDetails
                                {
                                    VStack(alignment: .leading, spacing: 5)
                                    {
                                        Text(packageToPreview.name)
                                            .font(.title3)

                                        Text(description)
                                            .font(.body)
                                    }
                                }
                            }

                            Section
                            {
                                PackageDependencies(dependencies: dependencies, isDependencyDisclosureGroupExpanded: $isShowingExpandedDependencies)
                            }
                        }
                        else
                        {
                            ProgressView()
                        }
                    }
                    .frame(minWidth: 300)
                }
                else
                {
                    ProgressView()
                }
            }
            .task 
            {
                await loadPackageDetails(packageToPreview)
            }
            .onChange(of: packageToPreview)
            { newValue in
                Task
                {
                    await loadPackageDetails(newValue)
                }
            }
        }
    }

    @MainActor
    func loadPackageDetails(_ packageToPreview: BrewPackage?) async
    {
        if let packageToPreview
        {
            isLoadingPackageDetails = true
            
            dependencies = nil

            print("Will see info for \(packageToPreview.name)")

            var packageInfoRaw: String?

            defer
            {
                isLoadingPackageDetails = false
                packageInfoRaw = nil
            }

            if !packageToPreview.isCask
            {
                packageInfoRaw = await shell(AppConstants.brewExecutablePath, ["info", "--json=v2", packageToPreview.name]).standardOutput
            }
            else
            {
                packageInfoRaw = await shell(AppConstants.brewExecutablePath, ["info", "--json=v2", "--cask", packageToPreview.name]).standardOutput
            }

            do
            {
                let parsedJSON: JSON = try parseJSON(from: packageInfoRaw!)

                description = getPackageDescriptionFromJSON(json: parsedJSON, package: packageToPreview)
                homepage = getPackageHomepageFromJSON(json: parsedJSON, package: packageToPreview)
                tap = getPackageTapFromJSON(json: parsedJSON, package: packageToPreview)

                if let packageDependencies = getPackageDependenciesFromJSON(json: parsedJSON, package: packageToPreview)
                {
                    dependencies = packageDependencies
                }
            }
            catch let jsonParsingError
            {
                AppConstants.logger.error("Failed while parsing preview JSON: \(jsonParsingError)")
            }
        }
    }
}
