//
//  FixCompilation.swift
//  RxSwiftPresentationHost
//
//  Created by Evgeniy Gubin on 09.10.17.
//  Copyright © 2017 Eugene Gubin. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

public func demonstrate<T>(_ name: String, body: () -> Observable<T>) {
    let o = body()
    _ = o
        .debug(name)
        .subscribe()
}

public let крайнийСрок: RxTimeInterval = 5
public let чутьЧуть: RxTimeInterval = 1

public func когдаНастанет(_ время: RxTimeInterval) -> Observable<Void> {
    return Observable<Void>.just(()).delay(время, scheduler: MainScheduler.instance)
}
