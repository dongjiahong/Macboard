import Defaults

extension Defaults.Keys {
    static let autoUpdate = Key<Bool>("autoUpdate", default: false)
    static let showSearchbar = Key<Bool>("showSearchbar", default: true)
    static let showUrlMetadata = Key<Bool>("showUrlMetadata", default: true)
    static let maxItems = Key<Int>("maxItems", default: 200)
    static let allowedTypes = Key<[String]>("allowedTypes", default: ["Text", "Image", "File"])
    static let menubarIcon = Key<MenubarIcon>("menubarIcon", default: .normal)
    static let searchType = Key<SearchType>("searchType", default: .insensitive)
    static let clearPins = Key<Bool>("clearPins", default: false)
    static let lanSyncEnabled = Key<Bool>("lanSyncEnabled", default: false)
    static let lanSyncPort = Key<UInt16>("lanSyncPort", default: 8899)
    static let autoCopyLatestOnWake = Key<Bool>("autoCopyLatestOnWake", default: false)
}
