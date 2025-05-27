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
        
        // Two photos
        CollageTemplate(id: 1, name: "Vertical 2", positions: [(0, 0), (1, 0)]),
        CollageTemplate(id: 2, name: "Horizontal 2", positions: [(0, 0), (0, 1)]),
        CollageTemplate(id: 3, name: "Diagonal 2", positions: [(0, 0), (1, 1)]),
        
        // Three photos
        CollageTemplate(id: 4, name: "L-Shape 3", positions: [(0, 0), (1, 0), (0, 1)]),
        CollageTemplate(id: 5, name: "L-Shape Bottom 3", positions: [(0, 0), (0, 1), (1, 1)]),  // переименован из T-Shape Bottom 3
        CollageTemplate(id: 6, name: "Triplet Shape 3", positions: [(0, 0), (1, 0), (2, 0)]),
        // New special templates for three photos:
        CollageTemplate(id: 7, name: "Left Tall, Right Two", positions: [(0, 0), (1, 0), (1, 1)]),
        CollageTemplate(id: 8, name: "Right Tall, Left Two", positions: [(0, 0), (0, 1), (1, 0)]),
        CollageTemplate(id: 9, name: "Top Long, Bottom Two", positions: [(0, 0), (0, 1), (1, 1)]),
        CollageTemplate(id: 10, name: "Bottom Long, Top Two", positions: [(0, 0), (1, 0), (0, 1)]),
        
        // Four photos
        CollageTemplate(id: 11, name: "Grid 4", positions: [(0, 0), (1, 0), (0, 1), (1, 1)]),
        CollageTemplate(id: 12, name: "Vertical Line 4", positions: [(0, 0), (1, 0), (2, 0), (3, 0)]),
        CollageTemplate(id: 13, name: "Side L-Shape 4", positions: [(0, 0), (0, 1), (1, 1), (1, 2)]),
        CollageTemplate(id: 14, name: "Cross Shape 4", positions: [(0, 1), (1, 0), (1, 2), (2, 1)]),
        
        // Five photos
        CollageTemplate(id: 15, name: "Pentagon Shape 5", positions: [(0, 1), (1, 0), (1, 1), (1, 2), (2, 1)]),
        
        // Six photos
        CollageTemplate(id: 16, name: "Horizontal Rows 6", positions: [(0, 0), (0, 1), (0, 2), (1, 0), (1, 1), (1, 2)]),
        CollageTemplate(id: 17, name: "Vertical Columns 6", positions: [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)]),
        
        // Nine photos
        CollageTemplate(id: 18, name: "Grid 9", positions: [
            (0, 0), (1, 0), (2, 0),
            (0, 1), (1, 1), (2, 1),
            (0, 2), (1, 2), (2, 2)
        ])
    ]
}
