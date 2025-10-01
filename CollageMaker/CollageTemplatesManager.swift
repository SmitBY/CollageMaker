//
//  CollageTemplatesManager.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 29.01.2025.
//

import Foundation

/// Manager providing collage templates.
class CollageTemplatesManager {
    static let shared = CollageTemplatesManager()
    private init() {}
    
    let templates: [CollageTemplate] = [
        // Single photo
        CollageTemplate(id: 0, name: "Single", positions: [(0, 0)]),
        
        // Two photos - Basic layouts
        CollageTemplate(id: 1, name: "Vertical 2", positions: [(0, 0), (1, 0)]),
        CollageTemplate(id: 2, name: "Horizontal 2", positions: [(0, 0), (0, 1)]),
        CollageTemplate(id: 3, name: "Diagonal 2", positions: [(0, 0), (1, 1)]),
        
        // Three photos - Basic layouts
        CollageTemplate(id: 4, name: "L-Shape 3", positions: [(0, 0), (1, 0), (0, 1)]),
        CollageTemplate(id: 5, name: "L-Shape Bottom 3", positions: [(0, 0), (0, 1), (1, 1)]),
        CollageTemplate(id: 6, name: "Triplet Shape 3", positions: [(0, 0), (1, 0), (2, 0)]),
        CollageTemplate(id: 7, name: "Left Tall, Right Two", positions: [(0, 0), (1, 0), (1, 1)]),
        CollageTemplate(id: 8, name: "Right Tall, Left Two", positions: [(0, 0), (0, 1), (1, 0)]),
        
        // Three photos - Creative layouts (unique)
        CollageTemplate(id: 24, name: "Steps 3", positions: [(0, 0), (1, 1), (2, 0)]),
        
        // Four photos - Basic layouts
        CollageTemplate(id: 11, name: "Grid 4", positions: [(0, 0), (1, 0), (0, 1), (1, 1)]),
        CollageTemplate(id: 12, name: "Vertical Line 4", positions: [(0, 0), (1, 0), (2, 0), (3, 0)]),
        CollageTemplate(id: 13, name: "Side L-Shape 4", positions: [(0, 0), (0, 1), (1, 1), (1, 2)]),
        CollageTemplate(id: 14, name: "Cross Shape 4", positions: [(0, 1), (1, 0), (1, 2), (2, 1)]),
        
        // Four photos - Instagram style (unique)
        CollageTemplate(id: 30, name: "Instagram Stories", positions: [(0, 0), (0, 1), (0, 2), (0, 3)]),
        
        // Five photos
        CollageTemplate(id: 15, name: "Pentagon Shape 5", positions: [(0, 1), (1, 0), (1, 1), (1, 2), (2, 1)]),
        CollageTemplate(id: 32, name: "Plus 5", positions: [(1, 0), (0, 1), (1, 1), (2, 1), (1, 2)]),
        
        // Six photos
        CollageTemplate(id: 16, name: "Horizontal Rows 6", positions: [(0, 0), (0, 1), (0, 2), (1, 0), (1, 1), (1, 2)]),
        CollageTemplate(id: 17, name: "Vertical Columns 6", positions: [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)]),
        CollageTemplate(id: 34, name: "Hexagon 6", positions: [(1, 0), (0, 1), (2, 1), (0, 2), (2, 2), (1, 3)]),
        CollageTemplate(id: 35, name: "Flower 6", positions: [(1, 0), (0, 1), (1, 1), (2, 1), (0, 2), (2, 2)]),
        
        // Eight photos
        CollageTemplate(id: 36, name: "Octagon 8", positions: [
            (1, 0), (2, 0),
            (0, 1), (3, 1),
            (0, 2), (3, 2),
            (1, 3), (2, 3)
        ]),
        
        // Nine photos
        CollageTemplate(id: 18, name: "Grid 9", positions: [
            (0, 0), (1, 0), (2, 0),
            (0, 1), (1, 1), (2, 1),
            (0, 2), (1, 2), (2, 2)
        ]),
        
        // Creative special layouts (unique)
        CollageTemplate(id: 37, name: "Heart 7", positions: [
            (1, 0), (2, 0),
            (0, 1), (1, 1), (2, 1), (3, 1),
            (1, 2)
        ]),
        
        // Magazine style layouts
        CollageTemplate(id: 41, name: "Magazine Cover", positions: [(0, 0), (1, 0), (0, 1)]),
        CollageTemplate(id: 42, name: "Magazine Spread", positions: [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1)]),
        CollageTemplate(id: 43, name: "Photo Strip", positions: [(0, 0), (0, 1), (0, 2), (0, 3), (0, 4)]),
        
        // Polaroid style
        CollageTemplate(id: 44, name: "Polaroid Stack", positions: [(0, 0), (1, 1), (2, 0)]),
        CollageTemplate(id: 45, name: "Scattered Photos", positions: [(0, 0), (2, 1), (1, 2), (3, 0)])
    ]
}
