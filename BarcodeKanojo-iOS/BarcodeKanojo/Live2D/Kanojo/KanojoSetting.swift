// KanojoSetting.swift — Character configuration (parts, colors, features)
// Ported from kanojo_app-master/.../live2d/KanojoSetting.java

import Foundation

// MARK: - HSL Color Convert values

struct ColorConvert {
    let hue: Float
    let sat: Float
    let lum: Float
}

// MARK: - Setting Sub-types

struct PartsSet {
    let partsID: String
    var partsItemNo: Int
}

struct ColorSet {
    let colorID: String
    var colorNo: Int
}

struct FeatureSet {
    let featureID: String
    var featureValue: Float
}

// MARK: - KanojoSetting

final class KanojoSetting {
    // Part IDs (matching PARTS_01_* in the .moc)
    static let PARTS_01_CORE = "PARTS_01_CORE"
    static let PARTS_01_BODY = "PARTS_01_BODY"
    static let PARTS_01_FACE = "PARTS_01_FACE"
    static let PARTS_01_EYE = "PARTS_01_EYE"
    static let PARTS_01_BROW = "PARTS_01_BROW"
    static let PARTS_01_MOUTH = "PARTS_01_MOUTH"
    static let PARTS_01_NOSE = "PARTS_01_NOSE"
    static let PARTS_01_EAR = "PARTS_01_EAR"
    static let PARTS_01_FRINGE = "PARTS_01_FRINGE"
    static let PARTS_01_HAIR = "PARTS_01_HAIR"
    static let PARTS_01_CLOTHES = "PARTS_01_CLOTHES"
    static let PARTS_01_GLASSES = "PARTS_01_GLASSES"
    static let PARTS_01_ACCESSORY = "PARTS_01_ACCESSORY"
    static let PARTS_01_SPOT = "PARTS_01_SPOT"
    static let PARTS_01_OPTION = "PARTS_01_OPTION"

    // Color channel IDs
    static let COLOR_01_SKIN = "COLOR_01_SKIN"
    static let COLOR_01_HAIR = "COLOR_01_HAIR"
    static let COLOR_01_EYE = "COLOR_01_EYE"
    static let COLOR_01_CLOTHES_A = "COLOR_01_CLOTHES_A"
    static let COLOR_01_CLOTHES_B = "COLOR_01_CLOTHES_B"

    // Feature IDs
    static let FEATURE_01_EYE_POS = "FEATURE_01_EYE_POS"
    static let FEATURE_01_BROW_POS = "FEATURE_01_BROW_POS"
    static let FEATURE_01_MOUTH_POS = "FEATURE_01_MOUTH_POS"

    // BkOptionColor flags
    static let OPTION_FLAG_COLOR_CONVERT_NONE: Int32 = 0
    static let OPTION_FLAG_COLOR_CONVERT_HAIR: Int32 = 1
    static let OPTION_FLAG_COLOR_CONVERT_SKIN: Int32 = 2
    static let OPTION_FLAG_COLOR_CONVERT_EYE: Int32 = 3
    static let OPTION_FLAG_COLOR_CONVERT_CLOTHES_1: Int32 = 4
    static let OPTION_FLAG_COLOR_CONVERT_CLOTHES_2: Int32 = 5
    static let OPTION_FLAG_COLOR_CONVERT_CLOTHES_3: Int32 = 6
    static let OPTION_FLAG_COLOR_CONVERT_CLOTHES_4: Int32 = 7
    static let OPTION_FLAG_COLOR_CONVERT_CLOTHES_5A: Int32 = 8
    static let OPTION_FLAG_COLOR_CONVERT_CLOTHES_5B: Int32 = 9

    // Color tables — exact match from KanojoSetting.java
    static let SKIN_CONVERT: [ColorConvert] = [
        ColorConvert(hue: 0, sat: 0, lum: 0),
        ColorConvert(hue: 3, sat: 0.16, lum: 0.16),
        ColorConvert(hue: 0, sat: 0.04, lum: -0.22),
        ColorConvert(hue: -5, sat: -0.05, lum: -0.55),
        ColorConvert(hue: 0, sat: -0.09, lum: -0.91),
        ColorConvert(hue: -160, sat: -0.07, lum: -0.46),
        ColorConvert(hue: -5, sat: -0.01, lum: 0.07),
        ColorConvert(hue: -6, sat: -0.01, lum: 0.2),
        ColorConvert(hue: -9, sat: 0, lum: -0.21),
        ColorConvert(hue: 12, sat: -0.01, lum: 0.11),
        ColorConvert(hue: 8, sat: 0.09, lum: 0),
        ColorConvert(hue: 0, sat: 0, lum: -0.62),
    ]

    static let HAIR_CONVERT: [ColorConvert] = [
        ColorConvert(hue: 1, sat: 0.19, lum: 0.28),
        ColorConvert(hue: 27, sat: 0.3, lum: 0.64),
        ColorConvert(hue: 7, sat: -0.09, lum: 0.52),
        ColorConvert(hue: 7, sat: 0.01, lum: 0.51),
        ColorConvert(hue: 21, sat: 0.26, lum: 0.22),
        ColorConvert(hue: -9, sat: 0.29, lum: 0.71),
        ColorConvert(hue: -56, sat: 0.01, lum: 0.02),
        ColorConvert(hue: 21, sat: 1.0, lum: 0.91),
        ColorConvert(hue: 0, sat: 0, lum: 0),
        ColorConvert(hue: 12, sat: 0.26, lum: 0.23),
        ColorConvert(hue: 7, sat: 0, lum: 0.19),
        ColorConvert(hue: 8, sat: 0.09, lum: 0.24),
        ColorConvert(hue: 21, sat: 0, lum: 0),
        ColorConvert(hue: 180, sat: 0.17, lum: 0.64),
        ColorConvert(hue: 21, sat: 0.51, lum: 0.69),
        ColorConvert(hue: 10, sat: -0.14, lum: 0.96),
        ColorConvert(hue: 0, sat: -0.08, lum: -0.35),
        ColorConvert(hue: 4, sat: 0.17, lum: 0),
        ColorConvert(hue: 26, sat: -0.12, lum: -0.46),
        ColorConvert(hue: 3, sat: 0, lum: -0.31),
        ColorConvert(hue: -25, sat: -0.1, lum: -0.42),
        ColorConvert(hue: 163, sat: 0.1, lum: 0.16),
        ColorConvert(hue: 97, sat: 0.1, lum: 0.55),
        ColorConvert(hue: -9, sat: 0.11, lum: 0.9),
    ]

    static let EYE_CONVERT: [ColorConvert] = [
        ColorConvert(hue: 0, sat: 0, lum: 0),
        ColorConvert(hue: 33, sat: -0.06, lum: 0.2),
        ColorConvert(hue: 155, sat: -0.05, lum: 0),
        ColorConvert(hue: 5, sat: -0.17, lum: -0.02),
        ColorConvert(hue: 12, sat: 0.06, lum: 0.15),
        ColorConvert(hue: -176, sat: 0.02, lum: 0.09),
        ColorConvert(hue: -6, sat: -0.26, lum: 0.14),
        ColorConvert(hue: 10, sat: 0.22, lum: 0.01),
        ColorConvert(hue: -143, sat: -0.12, lum: 0.05),
        ColorConvert(hue: 0, sat: -0.33, lum: -0.05),
        ColorConvert(hue: -12, sat: 0.05, lum: 0.17),
        ColorConvert(hue: -18, sat: -0.15, lum: 0.19),
    ]

    static let CLOTHES_A_1_CONVERT: [ColorConvert] = [
        ColorConvert(hue: 0, sat: 0, lum: 0), ColorConvert(hue: 27, sat: 0, lum: 0.06),
        ColorConvert(hue: 98, sat: -0.15, lum: 0.07), ColorConvert(hue: -63, sat: -0.21, lum: 0.04),
        ColorConvert(hue: 12, sat: -0.23, lum: 0.17), ColorConvert(hue: 0, sat: -0.24, lum: -0.23),
    ]
    static let CLOTHES_A_2_CONVERT: [ColorConvert] = [
        ColorConvert(hue: 0, sat: 0, lum: 0), ColorConvert(hue: 43, sat: -0.05, lum: -0.18),
        ColorConvert(hue: -24, sat: -0.23, lum: -0.32), ColorConvert(hue: -96, sat: -0.26, lum: -0.42),
        ColorConvert(hue: 5, sat: 0.12, lum: 0.49), ColorConvert(hue: -113, sat: -0.06, lum: 0.38),
    ]
    static let CLOTHES_A_3_CONVERT: [ColorConvert] = [
        ColorConvert(hue: 0, sat: 0.01, lum: 0), ColorConvert(hue: -100, sat: -0.03, lum: 0.01),
        ColorConvert(hue: -44, sat: 0, lum: 0), ColorConvert(hue: 155, sat: 0.02, lum: -0.01),
        ColorConvert(hue: 79, sat: 0, lum: 0), ColorConvert(hue: -1, sat: -0.06, lum: 0.03),
    ]
    static let CLOTHES_A_4_CONVERT: [ColorConvert] = [
        ColorConvert(hue: 0, sat: 0.01, lum: 0), ColorConvert(hue: -50, sat: -0.24, lum: -0.05),
        ColorConvert(hue: 36, sat: -0.04, lum: 0), ColorConvert(hue: -163, sat: -0.12, lum: 0.06),
        ColorConvert(hue: 28, sat: 0, lum: 0.19), ColorConvert(hue: 8, sat: -0.13, lum: -0.42),
    ]
    static let CLOTHES_A_5_CONVERT: [ColorConvert] = [
        ColorConvert(hue: 1, sat: 0, lum: 0), ColorConvert(hue: 76, sat: -0.09, lum: -0.51),
        ColorConvert(hue: -24, sat: 0, lum: -0.45), ColorConvert(hue: -5, sat: -0.11, lum: -0.92),
        ColorConvert(hue: 0, sat: -0.11, lum: -0.3), ColorConvert(hue: 18, sat: -0.06, lum: 0.2),
    ]

    // MARK: - State

    var partsSetList: [PartsSet]
    var colorSetList: [ColorSet]
    var featureSetList: [FeatureSet]
    var kanojoState: Int = 1
    var loveGauge: Double = 75.0
    var silhouetteMode: Bool = false

    init() {
        partsSetList = [
            PartsSet(partsID: Self.PARTS_01_BODY, partsItemNo: 1),
            PartsSet(partsID: Self.PARTS_01_FACE, partsItemNo: 1),
            PartsSet(partsID: Self.PARTS_01_EYE, partsItemNo: 1),
            PartsSet(partsID: Self.PARTS_01_BROW, partsItemNo: 1),
            PartsSet(partsID: Self.PARTS_01_MOUTH, partsItemNo: 1),
            PartsSet(partsID: Self.PARTS_01_NOSE, partsItemNo: 1),
            PartsSet(partsID: Self.PARTS_01_EAR, partsItemNo: 1),
            PartsSet(partsID: Self.PARTS_01_FRINGE, partsItemNo: 1),
            PartsSet(partsID: Self.PARTS_01_HAIR, partsItemNo: 1),
            PartsSet(partsID: Self.PARTS_01_CLOTHES, partsItemNo: 1),
            PartsSet(partsID: Self.PARTS_01_GLASSES, partsItemNo: 1),
            PartsSet(partsID: Self.PARTS_01_ACCESSORY, partsItemNo: 1),
            PartsSet(partsID: Self.PARTS_01_SPOT, partsItemNo: 1),
            PartsSet(partsID: Self.PARTS_01_OPTION, partsItemNo: 1),
        ]
        colorSetList = [
            ColorSet(colorID: Self.COLOR_01_SKIN, colorNo: 1),
            ColorSet(colorID: Self.COLOR_01_HAIR, colorNo: 1),
            ColorSet(colorID: Self.COLOR_01_EYE, colorNo: 1),
            ColorSet(colorID: Self.COLOR_01_CLOTHES_A, colorNo: 1),
            ColorSet(colorID: Self.COLOR_01_CLOTHES_B, colorNo: 1),
        ]
        featureSetList = [
            FeatureSet(featureID: Self.FEATURE_01_EYE_POS, featureValue: 0),
            FeatureSet(featureID: Self.FEATURE_01_BROW_POS, featureValue: 0),
            FeatureSet(featureID: Self.FEATURE_01_MOUTH_POS, featureValue: 0),
        ]
    }

    // MARK: - Accessors

    func setParts(_ partsID: String, _ itemNo: Int) {
        for i in 0..<partsSetList.count {
            if partsSetList[i].partsID == partsID {
                partsSetList[i].partsItemNo = itemNo
                return
            }
        }
    }

    func getParts(_ partsID: String) -> Int {
        for ps in partsSetList {
            if ps.partsID == partsID { return ps.partsItemNo }
        }
        return 1
    }

    func setColor(_ colorID: String, _ colorNo: Int) {
        for i in 0..<colorSetList.count {
            if colorSetList[i].colorID == colorID {
                colorSetList[i].colorNo = colorNo
                return
            }
        }
    }

    func getColor(_ colorID: String) -> Int {
        for cs in colorSetList {
            if cs.colorID == colorID { return cs.colorNo }
        }
        return 1
    }

    func setFeature(_ featureID: String, _ value: Float) {
        for i in 0..<featureSetList.count {
            if featureSetList[i].featureID == featureID {
                featureSetList[i].featureValue = value
                return
            }
        }
    }

    func getFeature(_ featureID: String) -> Float {
        for fs in featureSetList {
            if fs.featureID == featureID { return fs.featureValue }
        }
        return 0
    }

    // MARK: - Color lookup

    func getColorConvert(_ colorID: String, _ colorType: Int32) -> ColorConvert? {
        var cno = getColor(colorID)
        if cno < 1 { cno = 1 }

        if colorID == Self.COLOR_01_SKIN {
            if cno > 12 { cno = 1 }
            return Self.SKIN_CONVERT[cno - 1]
        } else if colorID == Self.COLOR_01_HAIR {
            if cno > 24 { cno = 1 }
            return Self.HAIR_CONVERT[cno - 1]
        } else if colorID == Self.COLOR_01_EYE {
            if cno > 12 { cno = 1 }
            return Self.EYE_CONVERT[cno - 1]
        } else if colorID == Self.COLOR_01_CLOTHES_A {
            if cno > 6 { cno = 1 }
            switch colorType {
            case 4: return Self.CLOTHES_A_1_CONVERT[cno - 1]
            case 5: return Self.CLOTHES_A_2_CONVERT[cno - 1]
            case 6: return Self.CLOTHES_A_3_CONVERT[cno - 1]
            case 7: return Self.CLOTHES_A_4_CONVERT[cno - 1]
            case 8, 9: return Self.CLOTHES_A_5_CONVERT[cno - 1]
            default: return nil
            }
        }
        return nil
    }
}
