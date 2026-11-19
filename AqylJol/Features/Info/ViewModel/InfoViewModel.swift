import Foundation
import DGis

public protocol InfoViewModeling: AnyObject {
    var onRender: ((InfoViewData) -> Void)? { get set }
    var onClose:  (() -> Void)? { get set }
    
    func configure(with object: DirectoryObject)
    func didTapClose()
}

public final class InfoViewModel: InfoViewModeling {
    
    public var onRender: ((InfoViewData) -> Void)?
    public var onClose:  (() -> Void)?
    
    private var object: DirectoryObject?
    
    public init() {}
    
    public func configure(with object: DirectoryObject) {
        self.object = object
        onRender?(mapToViewData(object))
    }

    public func didTapClose() {
        onClose?()
    }

    private let ruShortWeekdays = [
        "Пн",
        "Вт",
        "Ср",
        "Чт",
        "Пт",
        "Сб",
        "Вс"
    ]
    
    private func mapToViewData(_ obj: DirectoryObject) -> InfoViewData {
        let title = obj.title
        let buildingTypeText: String? = obj.types.debugDescription
        let workIsOpen = obj.workStatus?.isOpen
        let workDescription = obj.workStatus?.description
        let orgBranchCount = obj.orgInfo?.branchCount
        let openStatusFromWork = workDescription
        
        let subtitleText: String? = {
            let s = obj.subtitle.description.trimmingCharacters(in: .whitespacesAndNewlines)
            return s.isEmpty ? nil : s
        }()
        
        let addressText: String? = {
            if let addr = obj.formattedAddress(type: .full)?.streetAddress,
               !addr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return addr
            }
            let fallback = obj.address?.addressComment ?? ""
            let trimmed = fallback.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }()
        
        let fullAddress: String? = buildFullAddress(from: obj.address)
        
        let titleAdditionText: String? = {
            let t = obj.titleAddition.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        }()
        
        let hours = obj.openingHours
        let tzOffsetSec = obj.timeZoneOffset ?? 0
        let weeklyLines: [String]?
        
        if let hours {
            _ = Date(timeIntervalSinceNow: tzOffsetSec)
            weeklyLines = weeklyScheduleLines(hours: hours)
        } else {
            weeklyLines = nil
        }
        let rating: Float?
        let reviewsCount: Int?
        if let reviews = obj.reviews {
            rating = reviews.rating
            reviewsCount = Int(reviews.count)
        } else {
            rating = nil
            reviewsCount = nil
        }
        
        return InfoViewData(
            title: title,
            buildingType: buildingTypeText,
            subtitle: subtitleText,
            address: addressText,
            fullAddress: fullAddress,
            titleAddition: titleAdditionText,
            openStatusText: openStatusFromWork,
            weeklyHoursLines: weeklyLines,
            rating: rating,
            reviewsCount: reviewsCount,
            workIsOpen: workIsOpen,
            workDescription: workDescription,
            orgBranchCount: orgBranchCount
        )
    }

    // MARK: - Opening hours helpers
    private func weekdayIndexMondayZero(from date: Date) -> Int {
        let wd = Calendar.current.component(.weekday, from: date)
        return (wd == 1) ? 6 : (wd - 2)
    }

    private func formatHHmm(_ time: DGis.DayTime) -> String {
        String(format: "%02d:%02d", time.hours, time.minutes)
    }

    private func weeklyScheduleLines(hours: DGis.OpeningHours) -> [String]? {
        guard !hours.weekOpeningHours.isEmpty else { return nil }
        var lines: [String] = []
        for (idx, dayIntervals) in hours.weekOpeningHours.enumerated() {
            let dayName = ruShortWeekdays[idx]
            if dayIntervals.isEmpty {
                lines.append("\(dayName): ")
            } else {
                let merged = dayIntervals.map { it -> String in
                    "\(formatHHmm(it.startTime.time))–\(formatHHmm(it.finishTime.time))"
                }.joined(separator: ", ")
                lines.append("\(dayName): \(merged)")
            }
        }
        return lines
    }
    
    // MARK: - Address builder

    private func buildFullAddress(from address: DGis.Address?) -> String? {
        guard let address else { return nil }
        
        let admin = adminLine(from: address.drillDown)
        let (street, number, location) = componentsLine(from: address.components)
        let buildingName = address.buildingName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let postCode     = address.postCode?.trimmingCharacters(in: .whitespacesAndNewlines)
        let comment      = address.addressComment?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var parts: [String] = []
        
        if let s = street, let n = number, !s.isEmpty, !n.isEmpty {
            parts.append("\(s), \(n)")
        } else if let s = street, !s.isEmpty {
            parts.append(s)
        } else if let loc = location, !loc.isEmpty {
            parts.append(loc)
        }
        
        if let b = buildingName, !b.isEmpty { parts.append(b) }
        if let a = admin, !a.isEmpty { parts.append(a) }
        if let pc = postCode, !pc.isEmpty { parts.append(pc) }
        if let c = comment, !c.isEmpty { parts.append(c) }

        let result = parts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        return result.isEmpty ? nil : result
    }

    private func adminLine(from drillDown: [DGis.AddressAdmDiv]) -> String? {
        let byType: [String: String] = drillDown.reduce(into: [:]) { acc, item in
            acc[item.type] = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let city    = byType["city"]
        let region  = byType["region"] ?? byType["admDivRegion"]
        let country = byType["country"]

        let items = [city, region, country].compactMap { $0 }.filter { !$0.isEmpty }
        return items.isEmpty ? nil : items.joined(separator: ", ")
    }

    private func componentsLine(from components: [DGis.AddressComponent]) -> (street: String?, number: String?, location: String?) {
        var street: String?
        var number: String?
        var location: String?

        for c in components {
            switch c {
            case .streetAddress(let s):
                street = s.street.trimmingCharacters(in: .whitespacesAndNewlines)
            case .number(let n):
                number = n.number.trimmingCharacters(in: .whitespacesAndNewlines)
            case .location(let l):
                location = l.comment.trimmingCharacters(in: .whitespacesAndNewlines)
            @unknown default:
                break
            }
        }
        return (street, number, location)
    }
}
