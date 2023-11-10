//
//  Export Brewfile.swift
//  Cork
//
//  Created by David Bureš on 10.11.2023.
//

import Foundation

enum BrewfileDumpingError: Error
{
    case couldNotDetermineWorkingDirectory, errorWhileDumpingBrewfile, couldNotReadBrewfile
}

/// Exports the Brewfile and returns the raw data from the Brewfile itself for further manipulation. Does not preserve the Brewfile
func exportBrewfile() async throws -> Data
{
    let brewfileParentLocation: URL = URL.temporaryDirectory
    
    let pathRawOutput = await shell(URL(string: "/bin/pwd")!, ["-L"])
    
    async let brewfileDumpingResult: TerminalOutput = await shell(AppConstants.brewExecutablePath, ["bundle", "dump"], workingDirectory: brewfileParentLocation)

    /// Throw an error if the working directory could not be determined
    if !pathRawOutput.standardError.isEmpty
    {
        throw BrewfileDumpingError.couldNotDetermineWorkingDirectory
    }

    /// Throw an error if the working directory is so fucked up it's unusable
    guard let workingDirectory: URL = URL(string: pathRawOutput.standardOutput.replacingOccurrences(of: "\n", with: "")) else
    {
        throw BrewfileDumpingError.couldNotDetermineWorkingDirectory
    }
    
    if await !brewfileDumpingResult.standardError.isEmpty
    {
        throw BrewfileDumpingError.errorWhileDumpingBrewfile
    }
    
    print("Path: \(workingDirectory)")
    
    print("Brewfile dumping result: \(await brewfileDumpingResult)")
    
    let brewfileLocation: URL = brewfileParentLocation.appendingPathComponent("Brewfile", conformingTo: .fileURL)
    
    do
    {
        let brewfileContents: Data = try Data(contentsOf: brewfileLocation)
        
        /// Delete the brewfile
        try? FileManager.default.removeItem(at: brewfileLocation)
        
        return brewfileContents
    }
    catch let brewfileReadingError
    {
        print("Error while reading contents of Brewfile: \(brewfileReadingError)")
        throw BrewfileDumpingError.couldNotReadBrewfile
    }
}
