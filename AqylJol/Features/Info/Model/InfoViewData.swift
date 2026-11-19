import Foundation

public struct InfoViewData {
    
    public let title: String
    public let buildingType: String?
    public let subtitle: String?
    public let address: String?
    public let fullAddress: String?
    public let titleAddition: String?
    public let openStatusText: String?
    public let todayHoursText: String?
    public let weeklyHoursLines: [String]?
    public let workIsOpen: Bool?
    public let workDescription: String?
    public let orgBranchCount: UInt32?
    public let rating: Float?
    public let reviewsCount: Int?
    
    public var isSubtitleHidden: Bool { (subtitle ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    public var isAddressHidden:  Bool { (address  ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    public var isFullAddressHidden: Bool { (fullAddress ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    public var isTitleAdditionHidden: Bool { (titleAddition ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    public var isOpenStatusHidden: Bool { (openStatusText ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    public var isTodayHoursHidden: Bool { (todayHoursText ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    public var isWeeklyHoursHidden: Bool { (weeklyHoursLines ?? []).isEmpty }
    public var isReviewsHidden: Bool { rating == nil && reviewsCount == nil }
    public var isWorkStatusHidden: Bool {
        workIsOpen == nil && (workDescription ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public init(
        title: String,
        buildingType: String? = nil,
        subtitle: String?,
        address: String?,
        fullAddress: String?,
        titleAddition: String?,
        openStatusText: String? = nil,
        todayHoursText: String? = nil,
        weeklyHoursLines: [String]? = nil,
        rating: Float? = nil,
        reviewsCount: Int? = nil,
        workIsOpen: Bool? = nil,
        workDescription: String? = nil,
        orgBranchCount: UInt32? = nil
    ) {
        self.title = title
        self.buildingType = buildingType
        self.subtitle = subtitle
        self.address = address
        self.fullAddress = fullAddress
        self.titleAddition = titleAddition
        self.openStatusText = openStatusText
        self.todayHoursText = todayHoursText
        self.weeklyHoursLines = weeklyHoursLines
        self.rating = rating
        self.reviewsCount = reviewsCount
        self.workIsOpen = workIsOpen
        self.workDescription = workDescription
        self.orgBranchCount = orgBranchCount
    }
}
