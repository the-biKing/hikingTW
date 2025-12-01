//
//  SegmentManager.swift
//  hikingAPP
//
//  Created by 謝喆宇 on 2025/12/1.
//

import Foundation

class SegmentDataManager: ObservableObject {
    static let shared = SegmentDataManager()
    
    private var loadedSegments: [String: Segment] = [:] // ID : Segment
    private var loadedFiles: Set<String> = []
    private var fileIndex: [String: String] = [:] // Prefix : Filename
    
    init() {
        loadFileIndex()
    }
    
    // 1. Load the index map (Prefix -> Filename)
    private func loadFileIndex() {
        guard let url = Bundle.main.url(forResource: "segment_file_index", withExtension: "json") else {
            print("⚠️ Segment file index not found. Make sure you ran the split script.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            self.fileIndex = try JSONDecoder().decode([String: String].self, from: data)
        } catch {
            print("❌ Failed to load segment file index: \(error)")
        }
    }
    
    // 2. Main function to retrieve segments for specific areas
    func getSegments(forAreaCodes codes: [String]) -> [Segment] {
        var requiredFiles = Set<String>()
        
        for code in codes {
            if let filename = fileIndex[code] {
                requiredFiles.insert(filename)
            } else {
                // Fallback: try matching raw if not found in index
                print("⚠️ Area code \(code) not found in index.")
            }
        }
        
        // Load any files not yet in memory
        for file in requiredFiles {
            if !loadedFiles.contains(file) {
                loadSegmentsFromFile(filename: file)
            }
        }
        
        // Return all currently loaded segments (or you could filter strictly)
        return Array(loadedSegments.values)
    }
    
    // 3. Load specific JSON file
    private func loadSegmentsFromFile(filename: String) {
        // Assumes files are in Data/SplitSegments folder in Bundle
        // Note: You might need to add the folder to "Copy Bundle Resources" in Build Phases
        let fileNameWithoutExt = (filename as NSString).deletingPathExtension
        
        guard let url = Bundle.main.url(forResource: fileNameWithoutExt, withExtension: "json") else {
            print("❌ File \(filename) not found in bundle.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let collection = try JSONDecoder().decode(SegmentCollection.self, from: data)
            
            for seg in collection.segments {
                loadedSegments[seg.id] = seg
            }
            loadedFiles.insert(filename)
            print("✅ Loaded \(collection.segments.count) segments from \(filename)")
        } catch {
            print("❌ Failed to decode \(filename): \(error)")
        }
    }
    
    // Helper to get all currently loaded segments
    func getAllLoadedSegments() -> [Segment] {
        return Array(loadedSegments.values)
    }
    
    // Extract prefix from node ID (e.g. s_WM_01 -> WM)
    func getPrefix(from nodeID: String) -> String {
        let clean = nodeID.hasPrefix("s_") ? String(nodeID.dropFirst(2)) : nodeID
        let prefix = clean.prefix(while: { $0.isLetter })
        return String(prefix).uppercased()
    }
}
