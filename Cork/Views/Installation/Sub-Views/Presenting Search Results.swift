//
//  Presenting Search Results.swift
//  Cork
//
//  Created by David Bureš on 29.09.2023.
//

import SwiftUI

struct PresentingSearchResultsView: View
{
    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var appState: AppState

    @ObservedObject var searchResultTracker: SearchResultTracker

    @Binding var packageRequested: String
    @Binding var foundPackageSelection: UUID?

    @Binding var packageInstallationProcessStep: PackageInstallationProcessSteps

    @ObservedObject var installationProgressTracker: InstallationProgressTracker

    @State private var isFormulaeSectionCollapsed: Bool = false
    @State private var isCasksSectionCollapsed: Bool = false

    @State var isSearchFieldFocused: Bool = true

    @State private var packageToPreview: BrewPackage?
    @State private var isShowingPackagePreview: Bool = false

    var body: some View
    {
        VStack
        {
            HStack
            {
                VStack(alignment: .leading)
                {
                    InstallProcessCustomSearchField(search: $packageRequested, isFocused: $isSearchFieldFocused, customPromptText: String(localized: "add-package.search.prompt"))
                    {
                        foundPackageSelection = nil // Clear all selected items when the user looks for a different package
                    }
                    
                    List(selection: $foundPackageSelection)
                    {
                        SearchResultsSection(
                            sectionType: .formula,
                            packageList: searchResultTracker.foundFormulae
                        )
                        
                        SearchResultsSection(
                            sectionType: .cask,
                            packageList: searchResultTracker.foundCasks
                        )
                    }
                    .listStyle(.bordered(alternatesRowBackgrounds: true))
                    .frame(minWidth: 300, minHeight: 300)
                }
                
                PackagePreview(packageToPreview: packageToPreview, isShowingSelf: isShowingPackagePreview)
            }

            HStack
            {
                DismissSheetButton()

                Spacer()
                
                Button
                {
                    isShowingPackagePreview.toggle()
                } label: {
                    Text(isShowingPackagePreview ? "add-package.preview.close.action" : "add-package.preview.open.action")
                }

                if isSearchFieldFocused
                {
                    Button
                    {
                        packageInstallationProcessStep = .searching
                    } label: {
                        Text("add-package.search.action")
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(packageRequested.isEmpty)
                }
                else
                {
                    Button
                    {
                        getRequestedPackages()

                        packageInstallationProcessStep = .installing
                    } label: {
                        Text("add-package.install.action")
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(foundPackageSelection == nil)
                }
            }
        }
        .onChange(of: foundPackageSelection)
        { newValue in
            if let newValue
            {
                do
                {
                    packageToPreview = try getPackageFromUUID(requestedPackageUUID: newValue, tracker: searchResultTracker)
                }
                catch let uuidAssociationError
                {
                    AppConstants.logger.error("Could not associate UUID with package: \(uuidAssociationError)")
                }
            }
        }
    }

    private func getRequestedPackages()
    {
        if let requestedPackage = foundPackageSelection
        {
            do
            {
                let packageToInstall: BrewPackage = try getPackageFromUUID(requestedPackageUUID: requestedPackage, tracker: searchResultTracker)

                installationProgressTracker.packageBeingInstalled = PackageInProgressOfBeingInstalled(package: packageToInstall, installationStage: .ready, packageInstallationProgress: 0)

                #if DEBUG
                    AppConstants.logger.info("Packages to install: \(installationProgressTracker.packageBeingInstalled.package.name, privacy: .public)")
                #endif
            }
            catch let packageByUUIDRetrievalError
            {
                #if DEBUG
                    AppConstants.logger.error("Failed while associating package with its ID: \(packageByUUIDRetrievalError, privacy: .public)")
                #endif

                dismiss()

                appState.showAlert(errorToShow: .couldNotAssociateAnyPackageWithProvidedPackageUUID)
            }
        }
    }
}

private struct SearchResultsSection: View
{
    fileprivate enum SectionType
    {
        case formula, cask
    }

    let sectionType: SectionType

    let packageList: [BrewPackage]

    @State private var isSectionCollapsed: Bool = false

    var body: some View
    {
        Section
        {
            if !isSectionCollapsed
            {
                ForEach(packageList)
                { package in
                    SearchResultRow(packageName: package.name, isCask: package.isCask)
                }
            }
        } header: {
            CollapsibleSectionHeader(headerText: sectionType == .formula ? "add-package.search.results.formulae" : "add-package.search.results.casks", isCollapsed: $isSectionCollapsed)
        }
    }
}
