import Foundation

// MARK: - Storage Types
public enum Core_StorageKey: String, Codable, CaseIterable {
    case configuration
    case devices
    case scenes
    case effects
    case logs
    case analytics
    case user
    case settings
}

public enum Core_StorageDirectory: String, Codable, CaseIterable {
    case documents
    case caches
    case temporary
    case applicationSupport
    case library
}

// MARK: - Storage Protocols
// Core_StorageManaging protocol is defined in StorageProtocols.swift
// Removing duplicate definition to resolve ambiguity errors 