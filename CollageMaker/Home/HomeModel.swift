//
//  HomeModel.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 31.01.2025.
//

import Foundation
import RxSwift

// Model layer: responsible for fetching data
class HomeModel {
    func fetchCollageTemplates() -> Observable<[CollageTemplate]> {
        return Observable.create { observer in
            // Here you can add asynchronous data fetching logic (from a server, database, etc.)
            let templates = CollageTemplatesManager.shared.templates
            observer.onNext(templates)
            observer.onCompleted()
            return Disposables.create()
        }
    }
}
