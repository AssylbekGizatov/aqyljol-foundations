import DGis

// Быстрые хелперы
@inline(__always)
func gp(_ lat: Double, _ lon: Double) -> DGis.GeoPoint {
    DGis.GeoPoint(
        latitude:  DGis.Latitude(value: lat),
        longitude: DGis.Longitude(value: lon)
    )
}

@inline(__always)
func meters(_ m: Int) -> DGis.RouteDistance {
    DGis.RouteDistance(millimeters: Int64(m) * 1_000)
}

let FAKE_EXCLUDED_AREAS: [DGis.ExcludedArea] = [
//    DGis.ExcludedArea(
//        type: .point,
//        severity: .hard,
//        extent: meters(50),
//        points: [ gp(51.165712, 71.428877) ]
//    ),
    
//    DGis.ExcludedArea(
//        type: .polyline,
//        severity: .hard,
//        extent: meters(100),
//        points: [
//            gp(51.13350, 71.40500),
//            gp(51.13420, 71.41200),
//            gp(51.13510, 71.41850)
//        ]
//    ),
    DGis.ExcludedArea(
        type: .polygon,
        severity: .hard,
        extent: meters(0),
        points: [
            gp(51.165748, 71.427059),
            gp(51.165783, 71.427598),
            gp(51.168294, 71.426904),
            gp(51.168202, 71.426136)
        ]
    ),
    DGis.ExcludedArea(
        type: .polygon,
        severity: .hard,
        extent: meters(0),
        points: [
            gp(51.134215, 71.407093),
            gp(51.134157, 71.407617),
            gp(51.130003, 71.405369),
            gp(51.129829, 71.406046)
        ]
    ),
    DGis.ExcludedArea(
        type: .polygon,
        severity: .hard,
        extent: meters(0),
        points: [
            gp(51.124418, 71.423506),
            gp(51.123819, 71.423105),
            gp(51.122775, 71.433482),
            gp(51.122369, 71.433205)
        ]
    ),
    DGis.ExcludedArea(
        type: .polygon,
        severity: .hard,
        extent: meters(0),
        points: [
            gp(51.115597, 71.439763),
            gp(51.115524, 71.440138),
            gp(51.113996, 71.439202),
            gp(51.113908, 71.439553)
        ]
    ),
    DGis.ExcludedArea(
        type: .polygon,
        severity: .hard,
        extent: meters(0),
        points: [
            gp(51.109443, 71.424837),
            gp(51.109355, 71.425515),
            gp(51.105712, 71.423433),
            gp(51.105580, 71.424182)
        ]
    ),
    DGis.ExcludedArea(
        type: .polygon,
        severity: .hard,
        extent: meters(0),
        points: [
            gp(51.103978, 71.429305),
            gp(51.103787, 71.429703),
            gp(51.101364, 71.428674),
            gp(51.101481, 71.429142)
        ]
    ),
    DGis.ExcludedArea(
        type: .polygon,
        severity: .hard,
        extent: meters(0),
        points: [
            gp(51.091139, 71.419829),
            gp(51.091338, 71.420333),
            gp(51.090047, 71.420483),
            gp(51.090106, 71.421081)
        ]
    ),
    DGis.ExcludedArea(
        type: .polygon,
        severity: .hard,
        extent: meters(0),
        points: [
            gp(51.100998, 71.394675),
            gp(51.100946, 71.395528),
            gp(51.102604, 71.395500),
            gp(51.102535, 71.396133)
        ]
    ),
    DGis.ExcludedArea(
        type: .polygon,
        severity: .hard,
        extent: meters(0),
        points: [
            gp(51.113605, 71.396050),
            gp(51.113916, 71.396105),
            gp(51.113260, 71.398746),
            gp(51.113536, 71.398828)
        ]
    ),
    DGis.ExcludedArea(
        type: .polygon,
        severity: .hard,
        extent: meters(0),
        points: [
            gp(51.118251, 71.391290),
            gp(51.118095, 71.391758),
            gp(51.119183, 71.392446),
            gp(51.119080, 71.392748)
        ]
    ),
    DGis.ExcludedArea(
        type: .polygon,
        severity: .hard,
        extent: meters(0),
        points: [
            gp(51.131796, 71.387274),
            gp(51.131623, 71.387384),
            gp(51.132227, 71.388842),
            gp(51.132037, 71.388925)
        ]
    ),
    DGis.ExcludedArea(
        type: .polygon,
        severity: .hard,
        extent: meters(0),
        points: [
            gp(51.137769, 71.363340),
            gp(51.137561, 71.364165),
            gp(51.134057, 71.361992),
            gp(51.133919, 71.362790)
        ]
    ),
    DGis.ExcludedArea(
        type: .polygon,
        severity: .hard,
        extent: meters(0),
        points: [
            gp(51.140888, 71.463322),
            gp(51.141132, 71.464044),
            gp(51.138710, 71.464877),
            gp(51.138884, 71.465516)
        ]
    ),
    DGis.ExcludedArea(
        type: .polygon,
        severity: .hard,
        extent: meters(0),
        points: [
            gp(51.117672, 71.466373),
            gp(51.117646, 71.466668),
            gp(51.119852, 71.467218),
            gp(51.119785, 71.467537)
        ]
    ),
    DGis.ExcludedArea(
        type: .polygon,
        severity: .hard,
        extent: meters(0),
        points: [
            gp(51.148698, 71.423144),
            gp(51.148390, 71.423880),
            gp(51.150365, 71.425515),
            gp(51.150019, 71.426067)
        ]
    ),
    DGis.ExcludedArea(
        type: .polygon,
        severity: .hard,
        extent: meters(0),
        points: [
            gp(51.146630, 71.416005),
            gp(51.146394, 71.416073),
            gp(51.146711, 71.416839),
            gp(51.146468, 71.416918)
        ]
    ),
    DGis.ExcludedArea(
        type: .polygon,
        severity: .hard,
        extent: meters(0),
        points: [
            gp(51.100261, 71.448551),
            gp(51.100453, 71.448769),
            gp(51.099668, 71.449715),
            gp(51.099784, 71.449872)
        ]
    ),
    DGis.ExcludedArea(
        type: .polygon,
        severity: .hard,
        extent: meters(0),
        points: [
            gp(51.113335, 71.416855),
            gp(51.113283, 71.417286),
            gp(51.112669, 71.416515),
            gp(51.112601, 71.417004)
        ]
    ),
    DGis.ExcludedArea(
        type: .polygon,
        severity: .hard,
        extent: meters(0),
        points: [
            gp(51.150716, 71.397109),
            gp(51.150740, 71.397468),
            gp(51.148096, 71.396827),
            gp(51.147984, 71.397289)
        ]
    ),
]
