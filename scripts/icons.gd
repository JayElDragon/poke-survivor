extends RefCounted
# Iconos pixel art (portados de ui/icons.js): se dibujan al vuelo desde mapas de
# caracteres, asi que no hacen falta imagenes. Nombres: "heart", "coin", "move:<id>", "type:<tipo>"...

const MD = preload("res://scripts/moves_data.gd")
const K := Color("#1b1528")

# Movimientos con el mismo tipo y clase: usan el dibujo de otro tipo para distinguirse.
const GLYPH_OVERRIDE := {"swords-dance": "steel", "agility": "flying", "harden": "rock", "body-slam": "fighting", "poison-sting": "bug"}

const EXTRA := {"gcoin": {"pal": {"W": "#f4f6fb", "H": "#ffffff", "R": "#e0434f", "P": "#7a3fd0"}, "rows": [".....kRRRRk.....", "...kkkRRRRkkk...", "..kWWWWWWWWWWk..", ".kWPPPPPPPPPPWk.", ".kWPWWWWWWWWPWk.", "kWWPWWkkkkWWPWWk", "kWWPWkWHWWkWPWWk", "kWWPWkWWWWkWPWWk", "kWWPWkRRRRkWPWWk", "kWWPWkPPPPkWPWWk", "kWWPWWkkkkWWPWWk", ".kWPWWWWWWWWPWk.", ".kWPPPPPPPPPPWk.", "..kWWWWWWWWWWk..", "...kkkRRRRkkk...", ".....kRRRRk....."]}, "gcoin_gold": {"pal": {"W": "#ffe27a", "H": "#fffbe0", "R": "#e0434f", "P": "#c9791a"}, "rows": [".....kRRRRk.....", "...kkkRRRRkkk...", "..kWWWWWWWWWWk..", ".kWPPPPPPPPPPWk.", ".kWPWWWWWWWWPWk.", "kWWPWWkkkkWWPWWk", "kWWPWkWHWWkWPWWk", "kWWPWkWWWWkWPWWk", "kWWPWkRRRRkWPWWk", "kWWPWkPPPPkWPWWk", "kWWPWWkkkkWWPWWk", ".kWPWWWWWWWWPWk.", ".kWPPPPPPPPPPWk.", "..kWWWWWWWWWWk..", "...kkkRRRRkkk...", ".....kRRRRk....."]}, "bigorb": {"pal": {"O": "#8a5ad0", "Y": "#c9a6ff", "W": "#f4ecff", "o": "#4a2a96"}, "rows": ["......kWWk......", ".....kWWWWk.....", "......kWWk......", "....kkkOOkkk....", "...kOOYYYYOOk...", "..kOYWWYYYYOk...", "kWOYWYYYYYYYOWk.", "kWWOYYYYYYYYOWWk", "kWWOYYYYYYYYOWWk", "kWOOYYYYYYYOOWk.", "..kOOYYYYYOOk...", "...kooOOOOook...", "....kkoooookk...", "......kWWk......", ".....kWWWWk.....", "......kWWk......"]}, "size": {"pal": {"O": "#ff9a3d", "Y": "#ffd23f", "W": "#fff6c8", "o": "#b8501a"}, "rows": ["......kWWk......", ".....kWWWWk.....", "......kWWk......", "....kkkOOkkk....", "...kOOYYYYOOk...", "..kOYWWYYYYOk...", "kWOYWYYYYYYYOWk.", "kWWOYYYYYYYYOWWk", "kWWOYYYYYYYYOWWk", "kWOOYYYYYYYOOWk.", "..kOOYYYYYOOk...", "...kooOOOOook...", "....kkoooookk...", "......kWWk......", ".....kWWWWk.....", "......kWWk......"]}, "news": {"pal": {"B": "#4f8fd8", "L": "#9cc8ff", "W": "#ffffff"}, "rows": ["................", "..kkkkkkkkkkkk..", ".kBBBBBBBBBBBBk.", ".kBLLLLLLLLLLBk.", ".kBLWWWWWWWWLBk.", ".kBLLLLLLLLLLBk.", ".kBLWWWWWWWWLBk.", ".kBLLLLLLLLLLBk.", ".kBLWWWWWWLLLBk.", ".kBLLLLLLLLLLBk.", ".kBLWWWWWWWWLBk.", ".kBLLLLLLLLLLBk.", ".kBBBBBBBBBBBBk.", "..kkkkkkkkkkkk..", "................", "................"]}, "r_l_reap": {"pal": {"Y": "#ffd23f", "y": "#fff3a8", "o": "#b8860b", "W": "#ffffff", "S": "#e8edf5", "s": "#9aa6bd", "B": "#8a4b1f", "b": "#5b3a1f", "R": "#d12a3c", "r": "#8a1424", "H": "#ff8a96"}, "rows": ["......kRk.......", ".....kRHRk......", ".....kRRRk......", ".....kRRRk......", ".....kRWrk......", ".....kRWsk......", ".....krWsk......", ".....kSWsk......", ".....kSWsk......", "...kkkSWskkkk...", "..kyyyyyyyyyyk..", "..koYYYYYYYYok..", "...kkkkBbkkkk...", "......kBbk......", ".....kyYYYk.....", "......kkkk......"]}, "r_l_time": {"pal": {"Y": "#ffd23f", "y": "#fff3a8", "o": "#b8860b", "C": "#cfeeff", "W": "#ffffff", "S": "#ffb81c"}, "rows": ["..kkkkkkkkkkkk..", ".kyyyyyyyyyyyyk.", ".kYYYYYYYYYYYYk.", ".koCCCCCCCCCkk..", "..kkWCSSSSCCk...", "...kWCCSSCCk....", "....kkCSCCk.....", "......kSCk......", "......kSCk......", ".....kCSCCk.....", "....kCCSSCCk....", "...kCCSSSSCCkk..", "..kkkkkkkkkkkok.", ".kYYYYYYYYYYYYk.", ".kYYYYYYYYYYYYk.", "..kkkkkkkkkkkk.."]}, "r_l_bag": {"pal": {"Y": "#ffd23f", "y": "#fff3a8", "o": "#b8860b", "B": "#a8682a", "b": "#6b3f15", "R": "#e0434f", "W": "#ffffff"}, "rows": [".......kkk......", "......koook.....", ".....kokkkok....", "...kkokkkkkok...", "..kyyyyyyyyyyk..", "..kYYYYYYYYYYk..", "..kYYYYYYYYYYk..", "..kYYYYWRYYYYk..", "..kooooRRooook..", "..kBBBBRRBBBBk..", "..kBooooooooBk..", "..kBbbbbbbbbBk..", "..kBbbbbbbbbBk..", "..kBBBBBBBBBBk..", "...kkkkkkkkkk...", "................"]}, "r_l_armor": {"pal": {"Y": "#ffd23f", "y": "#fff3a8", "o": "#b8860b", "R": "#e0434f", "W": "#ffffff", "d": "#7a5a0b"}, "rows": ["................", "...kkkk..kkk....", ".kkyYYYkkYYYkk..", "kYyYYYYyyYYYYYk.", ".kYYYYYyyYYYYYk.", ".kYYYYYyyYYYYYk.", ".kYoooYWRYoooYk.", ".kYYYYYRRYYYYYk.", ".kooooooooooook.", "..kYYYYyyYYYYk..", "..kYYYYyyYYYk...", "...kddYyyYddk...", "...kYYYyyYYk....", "....kYYyyYYk....", ".....kkkkkk.....", "................"]}, "r_frenzy": {"pal": {"R": "#e0434f", "r": "#a82a35", "W": "#fff6e0", "Y": "#ffd23f", "g": "#9aa3b5"}, "rows": ["......kkkk......", ".....kggggk.....", ".....kggggk.kk..", ".....kkRRkkkggk.", "....kRRRRRRkggk.", "...kRRWWYWRRkk..", "..kRRWWWYWWRRk..", "..kRWWWYYWWWRk..", ".kRRWWYYYYWWRRk.", ".kRRWWWWYYWWRRk.", "..krWWWYYWWWRk..", "..krRWWYWWWRRk..", "...krRWWWWRRk...", "....kRRRRRRk....", ".....kkRRkk.....", ".......kk......."]}, "r_glass": {"pal": {"C": "#b9ecff", "W": "#ffffff", "B": "#5fb4e8", "b": "#3a6fa8", "D": "#2a3f66", "Y": "#ffd23f"}, "rows": ["................", "................", "................", "..........kkk...", "..kkkkkkkkBBBk..", ".kWWWDWWWWBbBkk.", ".kCCCCDCCCBbBkYk", ".kCCCDCCCCBbBYYk", ".kCCCCDCCCBbBkYk", ".kCCCDCCCCBbBkk.", "..kbbBBBbbBBBk..", "..kbBBDBBbkkk...", "...kBDDDBk......", "...kBBDBBk......", "....kBBBk.......", ".....kkk........"]}, "r_swift": {"pal": {"B": "#a8683a", "T": "#d9a066", "d": "#5b3a1f", "W": "#ffffff", "L": "#cfe8ff"}, "rows": ["................", "......kkkkk.....", ".....kTTTTTk....", "..kkkkTTTTTk....", ".kLWWkBBBBBk....", ".kWWWkBTBBBk....", "kWLWWkBTBBBk....", ".kWWWkBBBBBk....", "..kLWkBBBBBk....", "...kkkBBBBBkkk..", ".....kBBBBBBBBk.", ".....kBBBBBBBBk.", ".....kBBBBBBBBk.", ".....kddddddddk.", "......kkkkkkkk..", "................"]}, "r_blood": {"pal": {"R": "#d12a3c", "D": "#8a1424", "H": "#ff9aa8", "Y": "#ffd23f"}, "rows": ["................", ".......kk.......", "......kRRk......", "......kHRk......", ".....kRRRRk.....", "....kkRRRRkk....", "...kRRRRRRRRk...", "...kRRRRRRRRk...", "..kRRHRRRRRRRk..", "..kRRHRRRRRRRk..", "..kRRHRRRRRRRk..", "..kRRRHRRRRRRk..", "...kRRRRRRRRk...", "...kRDRRRRDRk...", "....kkDDDDkk....", "......kkkk......"]}, "r_scholar": {"pal": {"P": "#7a4fd0", "p": "#4a2a96", "W": "#f4f0e0", "Y": "#ffd23f", "y": "#fff3a8", "d": "#2a1a4a", "R": "#e0434f"}, "rows": ["................", "...kkkkkkkkkk...", "..kppPPPPPPPPk..", "..kpppPPPPPPPWk.", "..kppPRPPPRPPWk.", "..kppPPPPPPPPWk.", "..kppPPyyyPPPWk.", "..kppYyyyyyYYWk.", "..kppYyydyyYYWk.", "..kppYyydyyYYWk.", "..kppPPyyyPPPWk.", "..kppPRPPPRPPWk.", "..kppPPPPPPPPWk.", "..kppPPPPPPPPk..", "...kkkkkkkkkk...", "................"]}, "r_stone": {"pal": {"S": "#9aa3b2", "L": "#c9d0dc", "d": "#5d6674", "D": "#3a4150"}, "rows": ["................", "..kkkkkkkkkkkk..", ".kLLLLLLLLLLLLk.", ".kLLLLLLLLLLLLk.", ".kSSLSSDSSSLSk..", ".kSSddSSDSSSSk..", ".kSSSSSSDSddSk..", ".kSSSSSSDSSSSk..", ".kSSSLSSSDSSSk..", "..kSSSdSSDSSSk..", "...kSSSSDdSSk...", "....kSSdDSSk....", "....kSSSSSk.....", ".....kkSSk......", ".......kk.......", "................"]}, "r_fast": {"pal": {"W": "#f4f6fb", "L": "#c9d0dc", "g": "#9aa3b5", "d": "#6b7385"}, "rows": ["................", ".kkk.........kk.", "kgggk.......kWLk", "kgkgk.......kWLk", "kgkgk..kkkk.kWLk", "kgkgk.kWWWWkkWLk", "kgggkkWWWWWWkWLk", ".kgkkWWLLLLWWWLk", ".kgkkWWLLLLWWWLk", ".kgkkWWLLLLWWggk", ".kgkkWWLLLLWWggk", ".kgk.kWWWWWWkggk", ".kgk..kWWWWkkggk", ".kgk...kkkk.kggk", "..k..........kk.", "................"]}, "r_swarm": {"pal": {"C": "#f0dfae", "c": "#c9a26a", "Y": "#ffd23f", "d": "#6b4a2b", "W": "#ffffff"}, "rows": ["....k...........", "...kYk..........", "..kYk......kk...", ".kYk......kYYk..", ".kk......kYddYk.", "kYk.....kCYddYk.", ".kYk...kCCYddYk.", "..k...kCCcYddYk.", ".....kCCcCCYYk..", "....kCCcCCcCk...", "...kCCcCccCk....", "..kCCcCCCCk.....", ".kCCcCCCkk......", "..kCCCkk........", "...kkk..........", "................"]}, "r_berserk": {"pal": {"W": "#fff0f0", "R": "#e0434f", "r": "#ff9aa2", "d": "#3a0f16", "D": "#5b1f2a"}, "rows": ["................", ".kk...........kk", "kDDk.........kDD", "kDDDkk.....kkDDD", ".kDDDDk...kDDDDk", "..kDDDDkkkDDDDk.", "...kWDDDRDDDkk..", "..kWWrDDdDDWk...", ".kWWWRrddRRWWk..", "kWWrWRRddRRWrWk.", ".kWWWRRddRRWWk..", "..kWrWRddRWrk...", "...kWWWRRWWk....", "....kkkkkkk.....", "................", "................"]}, "r_quick": {"pal": {"F": "#f5c9a0", "f": "#e0a878", "W": "#ffffff", "g": "#9aa3b5", "s": "#c98f60"}, "rows": ["................", ".......kk.......", ".....kkffkk.....", ".kkkkFFffFFk....", "kWWWkFFffFFkk...", ".kkkkFFffFFffk..", "....kFFffFFffk..", ".kkkkFFffFFffkk.", "kWWWkFFffFFffFFk", ".kkkkFFFFFFFFFFk", "....kFFFFFFFFFFk", ".kkkkFFFFFFFFkk.", "kWWWkFFFFFFFFk..", ".kkkkssssssssk..", ".....kkkkkkkk...", "................"]}, "r_heavy": {"pal": {"S": "#9aa3b2", "L": "#d4dae6", "d": "#5d6674", "B": "#a8683a", "D": "#5b3a1f", "Y": "#ffd23f"}, "rows": ["................", "..kkkkkkkkkk.k..", ".kLLLLLLLLLLkYk.", ".kSSSSSSSSSSkkk.", ".kSSSSSSSSSSYYYk", ".kSSSSSSSSSSkkk.", ".kSSSSSSSSSSkYk.", ".kddddddddddkk..", "..kkkkBBkkkk.k..", ".....kBBk...kYk.", ".....kBBk..kYkYk", ".....kBBk...kYk.", ".....kDDk....k..", ".....kDDk.......", "......kk........", "................"]}, "r_overclock": {"pal": {"S": "#9aa3b2", "R": "#e8643a", "Y": "#ffd23f", "d": "#5d6674"}, "rows": ["......kkkk......", ".....kSSSSk.....", "...kkkSSSSkkk...", "..kSSSSSSSSSSk..", "..kSdSSRRSSSSk..", ".kkSSRRRRRRSSkk.", "kSSSSRRYYRRSSSSk", "kSSSRRYYYYRRSSSk", "kSSSRRYYYYRRSSSk", "kSSSSRRYYRRSSSSk", ".kkSSRRRRRRSSkk.", "..kSSSSRRSSdSk..", "..kSSSSSSSSSSk..", "...kkkSSSSkkk...", ".....kSSSSk.....", "......kkkk......"]}, "r_metronome": {"pal": {"B": "#a8683a", "T": "#d9a066", "D": "#5b3a1f", "Y": "#ffd23f", "R": "#e0434f", "W": "#fff3a8"}, "rows": ["...........k....", "..........kYk...", ".........kkYk...", "........kRRk....", ".....kkkkRRk....", "....kBBBBYk.....", "....kBBTTYBk....", "....kBBTTYBk....", "...kBBDTYDBBk...", "...kBBTTYTBBk...", "...kBBTYTTBBk...", "..kBBBTWTTBBBk..", ".kkBBBBBBBBBBkk.", "kDDDDDDDDDDDDDDk", "kDDDDDDDDDDDDDDk", ".kkkkkkkkkkkkkk."]}, "r_slowburn": {"pal": {"d": "#4a4f5e", "D": "#2f3340", "O": "#ff8a3d", "Y": "#ffd23f", "R": "#e0434f"}, "rows": ["................", "........k.......", ".......kOk......", "......kOOOk.....", ".....kOOYOOk....", ".....kOOYOOk....", "....kOOOOOOOk...", "...kddddddddk...", "...kddddddOddk..", "..kddOddOdddddk.", ".kddddOddddOddk.", "..kddddddOddddk.", "..kDDDDODDDDDDk.", "..kDDDDDDDDDDDk.", "...kkkkkkkkkkk..", "................"]}, "r_skip": {"pal": {"B": "#a8683a", "W": "#ffffff", "g": "#c9d0dc", "G": "#5fa84a", "d": "#5b3a1f"}, "rows": ["...kk...........", "..kBBk..........", "..kBBkkkkkkkk...", "..kBBWWWWWWWWk..", "..kBBWWWWWWWk...", "..kBBWWWWWWkk...", "..kBBWWWWggggk..", "..kBBggggWWWWk..", "..kBBkkkkkkkk...", "..kBBk..........", "..kBBk..........", "..kBBk..........", ".kkBBkkkk.......", "kGGGGGGGGk......", "kGGGGGGGGk......", ".kkkkkkkk......."]}, "r_rest": {"pal": {"B": "#a8683a", "D": "#5b3a1f", "O": "#ff8a3d", "Y": "#ffd23f", "R": "#e0434f"}, "rows": ["................", "........k.......", ".......kOk......", "......kOOOk.....", ".....kOOOOOk....", ".....kOOOOOk....", "....kOOOYOOOk...", "....kOOYYYOOk...", "...kOOYYYYOOk...", "..kkkOOYYYOOkkk.", ".kDDDOOYYYOkBBBk", ".kDDDDDDDBBBBBBk", "..kkDDDDDDDDDkk.", ".kBBBBBBDDDDDDDk", ".kBBBkkkkkkkDDDk", "..kkk.......kkk."]}, "r_train": {"pal": {"B": "#4f8fd8", "L": "#9cc8ff", "d": "#2a4a7a", "g": "#9aa3b5", "W": "#d4dae6"}, "rows": ["................", "................", "..kkk......kkk..", ".kLBBk....kLBBk.", ".kLBBk....kLBBk.", ".kLBdkkkkkkdBBk.", ".kLBdWWWWWWdBBk.", ".kLBdggggggdBBk.", ".kLBdggggggdBBk.", ".kLBdggggggdBBk.", ".kLBdkkkkkkdBBk.", ".kLBBk....kLBBk.", ".kLBBk....kLBBk.", "..kkk......kkk..", "................", "................"]}, "r_shield": {"pal": {"Y": "#ffd23f", "B": "#3f7fe0", "C": "#9cd0ff", "W": "#ffffff", "d": "#2a4a8a"}, "rows": ["................", ".....kkkkkk.....", "...kkYYYYYYkk...", "..kYYWdBBddYYk..", "..kYWBBBBBBdYk..", ".kYdWBBCCBBBdYk.", ".kYdBBCCCCBBdYk.", ".kYBBCCYYCCBBYk.", ".kYBBCCYYCCBBYk.", ".kYdBBCCCCBBdYk.", ".kYdBBBCCBBBdYk.", "..kYdBBBBBBdYk..", "..kYYddBBddYYk..", "...kkYYYYYYkk...", ".....kkkkkk.....", "................"]}, "contract": {"pal": {"P": "#f0dfae", "D": "#c9a26a", "T": "#7a5a35", "R": "#c0392b"}, "rows": ["..kkkkkkkkkkkk..", ".kDDDDDDDDDDDDk.", "kDDkkkkkkkkkkDDk", ".kkPPPPPPPPPPkk.", "..kPTTTTTTTTPk..", "..kPPPPPPPPPPk..", "..kPTTTTTTTTPk..", "..kPPPPPPPPPPk..", "..kPTTTTTTPPPk..", "..kPPPPPPPPPPk..", "..kPTTTTPPRRPk..", "..kPPPPPPRRRPk..", ".kkPPPPPPPPPPkk.", "kDDkkkkkkkkkkDDk", ".kDDDDDDDDDDDDk.", "..kkkkkkkkkkkk.."]}, "m_daily": {"pal": {"W": "#f4f6fb", "R": "#e0434f", "g": "#8a93a6", "d": "#5b6a8a", "Y": "#ffd23f"}, "rows": ["....kk....kk....", "...kggk..kggk...", "..kkggkkkkggkk..", ".kRRggRRRRggRRk.", ".kRRggRRRRggRRk.", ".kRRRRRRRRRRRRk.", ".kWWWWWWWWWWWWk.", ".kWWWWWWWWWWWWk.", ".kWWddWddWddWWk.", ".kWWddWddWddWWk.", ".kWWWWWWWWWWWWk.", ".kWWddYYYYddWWk.", ".kWWddWYYWddWWk.", ".kWWWWWWWWWWWWk.", ".kWWWWWWWWWWWWk.", "..kkkkkkkkkkkk.."]}, "m_rush": {"pal": {"W": "#f4f6fb", "R": "#e0434f", "H": "#ff9aa2", "S": "#c9cfdc"}, "rows": ["........k.......", ".....kkkRkkk....", "....kRRRRRRRk...", "...kHHRRRRRRRk..", "..kRHRRRRRRRRRk.", ".kRRRRRRRRRRRRRk", ".kRRRRRRkRRRRRRk", "..kkkkkkWkkkkkk.", ".kkkkkkWWWkkkkkk", ".kWWWWWkWkWWWWWk", ".kWWWWWWkWWWWWWk", ".kWWWWWWWWWWWWWk", "..kWWWWWWWWWWWk.", "...kWSSSWWWWWk..", "....kWWWWWWWk...", ".....kkkWkkk...."]}, "m_party": {"pal": {"P": "#ff6ad5", "B": "#4fa8ff", "Y": "#ffd23f", "G": "#5fe08a", "R": "#e0434f", "W": "#ffffff"}, "rows": [".......kYk......", "......kYYYk.....", ".....kYYYYYk....", "......kYYYk..k..", "..k...kBYPk.kRk.", ".kGk..kPPPk..k..", "..k..kBWBPPk....", ".....kBBPPPk....", "....kPPBBBPPk...", "....kPBBBWPPGk..", "...kRPPPBBBPPk..", "...kPPWBBBPPPk..", "..kBBBPPPBBBPPk.", ".kBYYYYYYYYYYYBk", "..kYYYYYYYYYYYk.", "...kkkkkkkkkkk.."]}, "m_horde": {"pal": {"a": "#9a6bff", "b": "#c49bff"}, "rows": ["................", "................", "........k.......", "......kkbkk.....", ".....kbbbbbk....", "....kkbbbbbk....", "..kkabbkbkbbkk..", ".kaaaabbbbbaaak.", ".kaaaabbbbbaaak.", "kaakakaabakakaak", ".kaaaaakkaaaaak.", ".kaaaaakkaaaaak.", "..kaaaaaaaaaak..", "..kaaaaaaaaaak..", "..kaaaaaaaaaak..", "...kkkkkkkkkk..."]}, "m_type": {"pal": {"R": "#ff6a3d", "G": "#5fe08a", "B": "#4fa8ff", "Y": "#ffd23f", "W": "#ffffff"}, "rows": ["................", "........k.......", ".....kkkGkkk....", "....kRRRGGGGk...", "...kRRRRGGGGGk..", "..kRRRRRGGGGGGk.", "..kRRRRRGGGGGGk.", "..kRRRRRWGGGGGk.", ".kBBBBBWWWYYYYYk", "..kBBBBBWYYYYYk.", "..kBBBBBYYYYYYk.", "..kBBBBBYYYYYYk.", "...kBBBBYYYYYk..", "....kBBBYYYYk...", ".....kkkYkkk....", "........k......."]}, "m_team": {"pal": {"W": "#f4f6fb", "R": "#e0434f"}, "rows": ["................", "...........k....", ".........kkRkk..", "........kRRRRRk.", ".....k.kRRRRRRRk", "...kkRkkRRRRRRRk", "..kRRRRkkkkWkkkk", ".kRRRRRRWWWWWWWk", ".kRRRRRRWWWWWWWk", ".kkkkWkkkWWWWWk.", ".kWWWWWWWkkWkk..", ".kWWWWWWWk.k....", "..kWWWWWk.......", "...kkWkk........", ".....k..........", "................"]}, "m_clock": {"pal": {"W": "#f4f6fb", "g": "#8a93a6", "R": "#e0434f"}, "rows": [".......kkk......", "......kgggk.....", "......kgggk..kk.", ".....kkkWkkkkggk", "....kWWWWWWWkggk", "...kWWWWkWWWWkk.", "..kWWWWWkWWWWWk.", "..kWWWWWkWWWWWk.", "..kWWWWWkWWWWWk.", ".kWWWWWWRkkkWWWk", "..kWWWWWWWWWWWk.", "..kWWWWWWWWWWWk.", "..kWWWWWWWWWWWk.", "...kWWWWWWWWWk..", "....kWWWWWWWk...", ".....kkkWkkk...."]}, "m_tower": {"pal": {"S": "#b9bfcc", "d": "#5b6a8a", "R": "#e0434f"}, "rows": ["....k.k.k.kkRRRk", "...kSkSkSkSkRRRk", "...kSSSSSSSSkkk.", "...kSSSSSSSSk...", "...kSSSSSSSSk...", "....kSSSSSSk....", "....kSSddSSk....", "....kSSddSSk....", "....kSSSSSSk....", "....kSSSSSSk....", "....kSSddSSk....", "....kSSddSSk....", "....kSSddSSk....", "....kSSddSSk....", "....kSSddSSk....", ".....kkkkkk....."]}, "m_coop": {"pal": {"A": "#4fa8ff", "B": "#ff8a5b"}, "rows": ["................", "................", ".....k.....k....", "...kkAkk.kkBkk..", "..kAAAAAkBBBBBk.", "..kAAAAAkBBBBBk.", ".kAAkAkABBkBkBBk", "..kAAAAAkBBBBBk.", "..kAAAAAkBBBBBk.", "..kkkAkkkkkBkkk.", ".kAAAAAABBBBBBBk", ".kAAAAAABBBBBBBk", ".kAAAAAABBBBBBBk", ".kAAAAAABBBBBBBk", ".kAAAAAABBBBBBBk", "..kkkkkkkkkkkkk."]}}

static var data: Dictionary = {}
static var cache := {}
static var loaded := false


static func _load() -> void:
	if loaded:
		return
	loaded = true
	var f := FileAccess.open("res://data/icons.json", FileAccess.READ)
	if f != null:
		var d = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			data = d


static func _shade(c: Color, k: float) -> Color:
	return Color(clampf(c.r * k, 0.0, 1.0), clampf(c.g * k, 0.0, 1.0), clampf(c.b * k, 0.0, 1.0), c.a)


static func _from_rows(def: Dictionary) -> Image:
	var rows: Array = def["rows"]
	var h: int = rows.size()
	var w := 0
	for r in rows:
		w = maxi(w, String(r).length())
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var pal: Dictionary = def.get("pal", {})
	for y in range(h):
		var row: String = String(rows[y])
		for x in range(row.length()):
			var ch: String = row.substr(x, 1)
			if ch == "." or ch == " ":
				continue
			if ch == "k":
				img.set_pixel(x, y, K)
			elif pal.has(ch):
				img.set_pixel(x, y, Color.html(String(pal[ch])))
	return img


static func _emblem(type: String, kind: String, evo: bool = false, glyph: String = "") -> Image:
	var S := 16
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	var col := Color.html(String(MD.TYPE_COLOR.get(type, "#b0a99f")))
	var dark: Color = _shade(col, 0.55)
	var lite: Color = _shade(col, 1.3)
	var edge: Color = Color("#ffd23f") if evo else K
	for y in range(S):
		for x in range(S):
			var d: float = Vector2(float(x) - 7.5, float(y) - 7.5).length()
			if d > 7.6:
				continue
			var f: Color = col
			if d > 6.6:
				f = edge
			elif (float(x) - 7.5) + (float(y) - 7.5) > 6.0:
				f = dark
			elif (float(x) - 7.5) + (float(y) - 7.5) < -6.5:
				f = lite
			img.set_pixel(x, y, f)
	var g: Array = data["type"].get(glyph if glyph != "" else type, data["type"]["normal"])
	for y in range(g.size()):
		var row: String = String(g[y])
		for x in range(row.length()):
			if row.substr(x, 1) == "#":
				img.set_pixel(x + 5, y + 5, dark)
	for y in range(g.size()):
		var row2: String = String(g[y])
		for x in range(row2.length()):
			if row2.substr(x, 1) == "#":
				img.set_pixel(x + 4, y + 4, Color.WHITE)
	if kind != "" and data["kind"].has(kind):
		for y in range(9, 16):
			for x in range(9, 16):
				img.set_pixel(x, y, K)
		for y in range(10, 15):
			for x in range(10, 15):
				img.set_pixel(x, y, Color("#2b3454"))
		var kg: Array = data["kind"][kind]
		for y in range(kg.size()):
			var kr: String = String(kg[y])
			for x in range(kr.length()):
				if kr.substr(x, 1) == "#":
					img.set_pixel(x + 10, y + 10, Color("#ffd23f"))
	return img


static func image(name: String) -> Image:
	_load()
	if name.begins_with("move:") or name.begins_with("evo:"):
		var evo: bool = name.begins_with("evo:")
		var id: String = name.substr(4 if evo else 5)
		if MD.MOVES.has(id):
			return _emblem(String(MD.MOVES[id]["type"]), String(MD.MOVES[id]["kind"]), evo, String(GLYPH_OVERRIDE.get(id, "")))
		var fr: Array = _fusion_recipe(id)
		if not fr.is_empty():
			return _fusion_emblem(fr)
		return _emblem("normal", "")
	if name.begins_with("type:"):
		return _emblem(name.substr(5), "")
	if name.begins_with("zc:"):
		return _zcrystal_img(name.substr(3))
	if name == "st:charm":
		return _status_heart()
	if name.begins_with("kec:"):
		return _kec_icon(name.substr(4))
	if name.begins_with("ti_"):
		return _emblem(name.substr(3), "", true)   # objeto de tipo: emblema del tipo con borde dorado
	if EXTRA.has(name):
		return _from_rows(EXTRA[name])
	var ui: Dictionary = data["ui"]
	return _from_rows(ui.get(name, ui["star"]))


# Estado "Enamorado": mismo emblema redondo que los demas estados, rosa y con un corazon.
static func _status_heart() -> Image:
	var S := 16
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	var col := Color("#ff6fa8")
	var dark: Color = _shade(col, 0.55)
	var lite: Color = _shade(col, 1.3)
	for y in range(S):
		for x in range(S):
			var d: float = Vector2(float(x) - 7.5, float(y) - 7.5).length()
			if d > 7.6:
				continue
			var f: Color = col
			if d > 6.6:
				f = K
			elif (float(x) - 7.5) + (float(y) - 7.5) > 6.0:
				f = dark
			elif (float(x) - 7.5) + (float(y) - 7.5) < -6.5:
				f = lite
			img.set_pixel(x, y, f)
	var heart := [".##.##.", "#######", "#######", ".#####.", "..###..", "...#..."]
	for pass_i in range(2):
		var off: int = 5 if pass_i == 0 else 4
		var c: Color = dark if pass_i == 0 else Color.WHITE
		for y in range(heart.size()):
			var row: String = heart[y]
			for x in range(row.length()):
				if row.substr(x, 1) == "#":
					img.set_pixel(x + off, y + off, c)
	return img


# Objetos de Kecleon: gema 16x16 del color de su variante con un dibujo simetrico unico por objeto.
static func _kec_icon(id: String) -> Image:
	var KSP = load("res://scripts/kec_spr.gd")
	if KSP.D.has(id):
		return _from_rows(KSP.D[id])
	var KCS = load("res://scripts/kecleon.gd")
	var col := Color("#b0a99f")
	for v in KCS.CAT:
		if (KCS.CAT[v] as Array).has(id):
			col = Color.html(String(KCS.VAR[v]["col"]))
	var S := 16
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	var dark: Color = _shade(col, 0.55)
	var lite: Color = _shade(col, 1.35)
	for y in range(S):
		for x in range(S):
			var d: float = absf(float(x) - 7.5) + absf(float(y) - 7.5)
			if d > 9.6:
				continue
			var f: Color = col
			if d > 8.4:
				f = K
			elif d > 7.4:
				f = lite if (x + y) < 15 else dark
			elif (float(x) - 7.5) + (float(y) - 7.5) > 3.0:
				f = _shade(col, 0.82)
			img.set_pixel(x, y, f)
	# dibujo simetrico 3x6 (espejo) derivado del identificador
	var h: int = absi(id.hash())
	for gy in range(6):
		for gx in range(3):
			if (h >> (gy * 3 + gx)) & 1 == 1:
				var px: int = 7 - gx
				var py: int = 5 + gy
				img.set_pixel(px, py, Color.WHITE)
				img.set_pixel(15 - px, py, Color.WHITE)
	img.set_pixel(7, 7, Color.WHITE)
	img.set_pixel(8, 7, Color.WHITE)
	return img


# Recetas de fusion: el icono de un movimiento fusionado es un emblema propio.
static func _fusion_recipe(id: String) -> Array:
	var FUS = load("res://scripts/fusions.gd")
	for r in FUS.R:
		if String(r[0]) == id:
			return r
	return []


# Emblema de fusion 16x16: mitad izquierda del color del tipo A, mitad derecha del tipo B, borde dorado,
# destello blanco en forma de estrella de cuatro puntas y chispas. Es distinto en cada receta.
static func _fusion_emblem(r: Array) -> Image:
	var S := 16
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	var ta := "normal"
	var tb := "normal"
	if MD.MOVES.has(String(r[2])):
		ta = String(MD.MOVES[String(r[2])]["type"])
	if MD.MOVES.has(String(r[3])):
		tb = String(MD.MOVES[String(r[3])]["type"])
	var ca := Color.html(String(MD.TYPE_COLOR.get(ta, "#b0a99f")))
	var cb := Color.html(String(MD.TYPE_COLOR.get(tb, "#b0a99f")))
	var cm := Color.html(String(r[5]))
	var h: int = absi(String(r[0]).hash())
	var tilt: float = float(h % 5 - 2) * 0.25
	for y in range(S):
		for x in range(S):
			var dx: float = float(x) - 7.5
			var dy: float = float(y) - 7.5
			var d: float = Vector2(dx, dy).length()
			if d > 7.6:
				continue
			var side: float = dx + dy * tilt
			var f: Color = _shade(ca, 1.1) if side < -0.6 else (_shade(cb, 1.1) if side > 0.6 else cm)
			if dx + dy > 6.0:
				f = _shade(f, 0.7)
			if d > 6.6:
				f = Color("#ffd23f") if d < 7.2 else K
			img.set_pixel(x, y, f)
	# estrella central de cuatro puntas
	for i in range(-4, 5):
		var w: int = 4 - absi(i)
		if w >= 1:
			img.set_pixel(8 + i, 7, Color.WHITE)
			img.set_pixel(7 + i, 8, Color.WHITE)
			img.set_pixel(7, 8 + i, Color.WHITE)
			img.set_pixel(8, 7 + i, Color.WHITE)
	for p in [Vector2i(4, 4), Vector2i(11, 4), Vector2i(4, 11), Vector2i(11, 11)]:
		img.set_pixel(p.x, p.y, _shade(cm, 1.5))
	return img


# Cristal Z de un tipo: rombo con borde negro y filo blanco, color del tipo a dos tonos y el simbolo del tipo en oscuro (24x16).
static func _zcrystal_img(type: String) -> Image:
	var W := 24
	var H := 16
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var col := Color.html(String(MD.TYPE_COLOR.get(type, "#b0a99f")))
	var lite: Color = _shade(col, 1.25)
	var dark: Color = _shade(col, 0.72)
	var cx: float = (W - 1) * 0.5
	var cy: float = (H - 1) * 0.5
	for y in range(H):
		for x in range(W):
			var d: float = absf(float(x) - cx) / 11.8 + absf(float(y) - cy) / 7.8
			if d > 1.0:
				continue
			var f: Color
			if d > 0.86:
				f = K
			elif d > 0.78:
				f = Color("#f4f6fb")
			else:
				f = lite if (float(y) - cy) + (float(x) - cx) * 0.25 < 0.0 else dark
				if d > 0.70:
					f = _shade(f, 0.85)
			img.set_pixel(x, y, f)
	var g: Array = data["type"].get(type, data["type"]["normal"])
	var gh: int = g.size()
	var gw: int = 0
	for r in g:
		gw = maxi(gw, String(r).length())
	var ox: int = int((W - gw) * 0.5)
	var oy: int = int((H - gh) * 0.5)
	for y in range(gh):
		var row: String = String(g[y])
		for x in range(row.length()):
			if row.substr(x, 1) == "#":
				img.set_pixel(ox + x, oy + y, K)
	return img


# Textura ampliada por un factor entero (sin suavizar).
static func tex(name: String, scale: int = 1) -> Texture2D:
	var key := "%s@%d" % [name, scale]
	if cache.has(key):
		return cache[key]
	var img: Image = image(name)
	if scale > 1:
		img.resize(img.get_width() * scale, img.get_height() * scale, Image.INTERPOLATE_NEAREST)
	var t := ImageTexture.create_from_image(img)
	cache[key] = t
	return t


# Escala entera que mas se acerca a un tamano objetivo en pantalla.
static func scale_for(name: String, size: float) -> int:
	_load()
	var w: int = 16
	if name.begins_with("zc:"):
		return maxi(1, roundi(size / 24.0))
	if not (name.begins_with("move:") or name.begins_with("type:") or name.begins_with("evo:") or name.begins_with("zc:")):
		if EXTRA.has(name) or name.begins_with("ti_") or name.begins_with("kec:"):
			return maxi(1, roundi(size / 16.0))
		var ui: Dictionary = data["ui"]
		var rows: Array = ui.get(name, ui["star"])["rows"]
		w = String(rows[0]).length()
	return maxi(1, roundi(size / float(w)))


# Dibuja el icono centrado en un rectangulo (para _draw de un CanvasItem).
static func draw_in(ci: CanvasItem, name: String, center: Vector2, size: float, mod: Color = Color.WHITE) -> void:
	var sc: int = scale_for(name, size)
	var t: Texture2D = tex(name, 1)
	var sz := Vector2(t.get_width(), t.get_height()) * float(sc)
	ci.draw_texture_rect(t, Rect2((center - sz * 0.5).round(), sz), false, mod)


# TextureRect listo para meter en un menu.
static func rect(name: String, size: float) -> TextureRect:
	var sc: int = scale_for(name, size)
	var t: Texture2D = tex(name, sc)
	var tr := TextureRect.new()
	tr.texture = t
	tr.stretch_mode = TextureRect.STRETCH_KEEP
	tr.custom_minimum_size = Vector2(t.get_width(), t.get_height())
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return tr


# Icono para el campo "icon" de un Button (ya ampliado).
static func btn_tex(name: String, size: float) -> Texture2D:
	return tex(name, scale_for(name, size))
