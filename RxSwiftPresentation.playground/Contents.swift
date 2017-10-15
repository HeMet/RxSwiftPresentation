import UIKit
import PlaygroundSupport
import RxSwiftPresentationHost
import RxSwift
import RxCocoa

/*: some text
 ## Создание Observable
 
 ### create
 
 Заворачивает императивный код в реактивную оболочку.
 */
demonstrate("create") {
    Observable<String>.create { observer in
        observer.onNext("Born")
        observer.onCompleted()
        return Disposables.create()
    }
}

// Ленивое создани

demonstrate("deferred") {
    Observable<String>.deferred {
        return .just("Born")
    }
}

// Различные способы завернуть значения в Observable

demonstrate("just") {
    Observable.just(0)
}

demonstrate("never") {
    Observable<String>.never()
}

demonstrate("empty") {
    Observable<String>.empty()
}

demonstrate("error") { () -> Observable<String> in
    enum BadThings: Error {
        case unfortunateCaseOfEvents
    }
    return Observable<String>
        .error(BadThings.unfortunateCaseOfEvents)
}

demonstrate("from") {
    Observable<String>.from(["Born", "to", "be", "wild"])
}

demonstrate("of") {
    Observable<String>.of("Born", "to", "be", "wild")
}

demonstrate("not nil") {
    Observable<String?>
        .from(["Born", nil, "to", nil, "be", nil,  "wild"])
        .flatMap { maybeString -> Observable<String> in
            if let string = maybeString {
                return .just(string)
            }
            return .empty()
        }
}

// Или встроенными средствами

demonstrate("from optional") {
    Observable<String>.from(optional: nil)
}

// Генераторы значений

demonstrate("range") {
    Observable<Int>.range(start: 0, count: 3)
}

demonstrate("repeat") {
    Observable<String>.repeatElement("again").take(3)
}

demonstrate("generate") { () -> Observable<Int> in
    return Observable<(Int, Int)>
        .generate(
            initialState: (0, 1),
            condition: { $0.0 < 100 },
            iterate: { ($0.1, $0.0 + $0.1) })
        .map { $0.0 }
}

// Таймеры

demonstrate("interval") {
    Observable<Int>
        .interval(1, scheduler: MainScheduler.instance)
        .take(3)
}

demonstrate("delay") { () -> Observable<String> in
    let наПотом: RxTimeInterval = 100500
    return Observable<String>
        .just("дело")
        .delay(наПотом, scheduler: MainScheduler.instance)
}

demonstrate("разгильдяйство") { () -> Observable<String> in
    let тянем = Observable<String>.never()
    let доУпора = когдаНастанет(крайнийСрок - чутьЧуть)
    let важноеДело = Observable.just("дело")
    return тянем
        .takeUntil(доУпора)
        .concat(важноеДело)
}

// Комбинация потоков

demonstrate("merge") {
    Observable<String>.merge(.just("пиво"), .just("водка"))
}

demonstrate("combineLatest") {
    Observable
        .combineLatest(
            Observable<Int>.of(0, 1),
            Observable<Int>.of(3, 4)
        ) { $0 + $1 }
}
demonstrate("zip") {
    Observable
        .zip(
            Observable<Int>.of(0, 1),
            Observable<Int>.of(3, 4)
        ) { $0 + $1 }
}

demonstrate("withLatestFrom") { () -> Observable<Int> in
    let хватит = когдаНастанет(0.5)
    let медленный = Observable<Int>.interval(0.05, scheduler: MainScheduler.instance)
    let быстрый = Observable<Int>.interval(0.01, scheduler: MainScheduler.instance)
    return медленный.withLatestFrom(быстрый).takeUntil(хватит)
}

demonstrate("concat") { () -> Observable<String> in
    let кэш = Observable.just("из кеша")
    let сервер = Observable.just("с сервера")
    return Observable.concat(кэш, сервер)
}

// Свертка значений

demonstrate("scan") { () -> Observable<Int> in
    let натуральныеЧисла = Observable.range(start: 1, count: 10)
    return натуральныеЧисла.scan(0, accumulator: +)
}

demonstrate("reduce") { () -> Observable<Int> in
    let натуральныеЧисла = Observable.range(start: 1, count: 10)
    return натуральныеЧисла.reduce(0, accumulator: +)
}

// Обработка ошибок

struct Билд {
    static func исправленный() -> Билд {
        return Билд()
    }
    
    static func закостыленный() -> Билд {
        return Билд()
    }
}

demonstrate("catch") { () -> Observable<Билд> in
    enum Облом: Error {
        case серверСдох
        case накосячил
    }
    
    let срок:RxTimeInterval = 1
    let спринт = Observable<Билд>.just(Билд())
    return спринт
        .catchError { error in
            switch error {
            case Облом.накосячил:
                return Observable.just(Билд.исправленный())
            default:
                return .error(error)
            }
        }
        .timeout(крайнийСрок, scheduler: MainScheduler.instance)
        .catchErrorJustReturn(Билд.закостыленный())
}

demonstrate("retry") { () -> Observable<String> in
    let постучатьсяНаСервер = Observable.just("json")
    return постучатьсяНаСервер.retry() // долбить сервер
}

//demonstrate("управляемая задержка") { () -> Observable<String> in
//    let прокрустинация = Observable<Int>.interval(1, scheduler: MainScheduler.instance)
//    let чатики = прокрустинация.map { _ in "трёп" }
//    let котики = прокрустинация.map { _ in "котик" }
//    let дедлайн = Observable<Void>.never()
//    let важноеДело = Observable.just("дело")
//    return Observable
//        .merge(чатики, котики)
//        .takeUntil(дедлайн)
//        .concat(важноеДело)
//}

// Пример

class ViewModel {
    let value: Driver<Int>
    
    let valid: Driver<Bool> = .just(false)
    
    init(plusTapped: Observable<Void>, minusTapped: Observable<Void>) {
        enum Action {
            case plus, minus
        }
        
        let doIncrement = plusTapped.map { Action.plus }
        let doDecrement = minusTapped.map { Action.minus }
        let actions = Observable.merge(doIncrement, doDecrement)
        value = actions.scan(0) { value, action in
            switch action {
            case .plus:
                return value + 1
            case .minus:
                return value - 1
            }
        }
        .asDriver(onErrorDriveWith: .empty())
    }
}

class View: UIViewController {
    
    var viewModel: ViewModel!
    
    let plusButton = UIButton()
    let minusButton = UIButton()
    let valueLabel = UILabel()
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        [plusButton, minusButton, valueLabel].forEach { view.addSubview($0) }
        
        valueLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 100).isActive = true
        plusButton.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 0).isActive = true
        minusButton.topAnchor.constraint(equalTo: plusButton.bottomAnchor, constant: 0).isActive = true
        [valueLabel.centerXAnchor, plusButton.centerXAnchor, minusButton.centerXAnchor].forEach {
            $0.constraint(equalTo: view.centerXAnchor)
        }
        
        viewModel = ViewModel(
            plusTapped: plusButton.rx.tap.asObservable(),
            minusTapped: minusButton.rx.tap.asObservable())
        
        viewModel.value
            .map { String($0) }
            .drive(valueLabel.rx.text)
            .disposed(by: disposeBag)
    }
}

PlaygroundPage.current.liveView = View()
PlaygroundPage.current.needsIndefiniteExecution = true
