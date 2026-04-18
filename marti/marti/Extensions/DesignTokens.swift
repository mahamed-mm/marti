import SwiftUI

// MARK: - Colors (dark mode only — see DESIGN.md §Color System)

extension Color {
    static let canvas             = Color(red: 0x01/255, green: 0x09/255, blue: 0x13/255)
    static let surfaceDefault     = Color(red: 0x13/255, green: 0x1D/255, blue: 0x2B/255)
    static let surfaceElevated    = Color(red: 0x24/255, green: 0x33/255, blue: 0x46/255)
    static let surfaceHighlight   = Color(red: 0x1A/255, green: 0x2A/255, blue: 0x3D/255)

    static let textPrimary        = Color.white
    static let textSecondary      = Color(red: 0xBD/255, green: 0xC4/255, blue: 0xCB/255)
    static let textTertiary       = Color(red: 0x95/255, green: 0xA0/255, blue: 0xAE/255)

    static let coreAccent         = Color(red: 0x84/255, green: 0xE9/255, blue: 0xFF/255)
    static let corePrimary        = Color(red: 0x05/255, green: 0x41/255, blue: 0x84/255)

    static let statusSuccess      = Color(red: 0x62/255, green: 0xF1/255, blue: 0xC6/255)
    static let statusDanger       = Color(red: 0xFF/255, green: 0x64/255, blue: 0x9C/255)
    static let statusWarning      = Color(red: 0xFE/255, green: 0xEB/255, blue: 0x87/255)

    static let dividerLine        = Color.white.opacity(0.08)

    static let starEmpty          = Color(red: 0x44/255, green: 0x50/255, blue: 0x5F/255)
}

// MARK: - Spacing

enum Spacing {
    static let xs:   CGFloat = 2
    static let sm:   CGFloat = 4
    static let md:   CGFloat = 8
    static let base: CGFloat = 16
    static let lg:   CGFloat = 24
    static let xl:   CGFloat = 32
    static let xxl:  CGFloat = 40
}

// MARK: - Corner radius

enum Radius {
    static let xs:   CGFloat = 4
    static let sm:   CGFloat = 8
    static let md:   CGFloat = 12
    static let lg:   CGFloat = 24
    static let xl:   CGFloat = 40
    static let full: CGFloat = 100
}

// MARK: - Typography helpers

extension Font {
    static let martiHeading3   = Font.system(size: 24, weight: .bold)
    static let martiHeading4   = Font.system(size: 20, weight: .bold)
    static let martiHeading5   = Font.system(size: 16, weight: .bold)
    static let martiBody       = Font.system(size: 16, weight: .regular)
    static let martiFootnote   = Font.system(size: 14, weight: .regular)
    static let martiCaption    = Font.system(size: 12, weight: .regular)
    static let martiLabel1     = Font.system(size: 16, weight: .bold)
    static let martiLabel2     = Font.system(size: 14, weight: .bold)
}
