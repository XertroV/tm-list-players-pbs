// from https://github.com/XertroV/tm-cotd-hud/blob/422a1fc4be32b969de6a76355b3a2c03b5cc8034/src/Color.as

// the entire point of this file is to provide `MakeColorsOkayDarkMode`


dictionary@ DARK_MODE_CACHE = dictionary();

string MakeColorsOkayDarkMode(const string &in raw) {
    /* - find color values
       - for each color value:
         - luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
         - luma < .4 { replace color }
       return;
    */
    // we need at least 4 chars to test $123, so only go to length-3 to test for $.
    if (DARK_MODE_CACHE.Exists(raw)) {
        return string(DARK_MODE_CACHE[raw]);
    }
    string ret = string(raw);
    string _test;
    for (int i = 0; i < int(ret.Length) - 3; i++) {
        if (ret[i] == asciiDollarSign) {
            _test = ret.SubStr(i, 4);
            if (IsCharHex(_test[1]) && IsCharHex(_test[2]) && IsCharHex(_test[3])) {
                auto c = Color(vec3(
                    float(HexCharToInt(_test[1])) / 15.,
                    float(HexCharToInt(_test[2])) / 15.,
                    float(HexCharToInt(_test[3])) / 15.
                ));
                c.AsHSL();
                float l = c.v.z;  /* lightness part of HSL */
                if (l < 60) {
                    // logcall("MakeColorsOkayDarkMode", "fixing color: " + _test + " / " + c.ManiaColor + " / " + c.ToString());
                    c.v = vec3(c.v.x, c.v.y, Math::Max(100. - l, 60));
                    // logcall("MakeColorsOkayDarkMode", "new color: " + Vec3ToStr(c.get_rgb()) + " / " + c.ManiaColor + " / " + c.ToString());
                    ret = ret.Replace(_test, c.ManiaColor);
                }
            }
        }
    }
    DARK_MODE_CACHE[raw] = ret;
    return ret;
}


// rest of the code to make the above work:


const uint asciiDollarSign = "$"[0];

bool IsCharInt(int char) {
    return 48 <= char && char <= 57;
}

bool IsCharInAToF(int char) {
    return (97 <= char && char <= 102) /* lower case */
        || (65 <= char && char <= 70); /* upper case */
}

bool IsCharHex(int char) {
    return IsCharInt(char) || IsCharInAToF(char);
}

uint8 HexCharToInt(int char) {
    if (IsCharInt(char)) {
        return char - 48;
    }
    if (IsCharInAToF(char)) {
        int v = char - 65 + 10;  // A = 65 ascii
        if (v < 16) return v;
        return v - (97 - 65);    // a = 97 ascii
    }
    throw("HexCharToInt got char with code " + char + " but that isn't 0-9 or a-f or A-F in ascii.");
    return 0;
}


enum ColorTy {
    RGB,
    LAB,
    XYZ,
    HSL,
}

ColorTy[] allColorTys = {
    ColorTy::RGB,
    ColorTy::LAB,
    ColorTy::XYZ,
    ColorTy::HSL
};

string ColorTyStr(ColorTy ty) {
    switch (ty) {
        case ColorTy::RGB: return "RGB";
        case ColorTy::LAB: return "LAB";
        case ColorTy::XYZ: return "XYZ";
        case ColorTy::HSL: return "HSL";
    }
    return "UNK";
}

string F3(float v) {
    return Text::Format("%.3f", v);
}

string Vec3ToStr(vec3 v) {
    return "vec3(" + F3(v.x) + ", " + F3(v.y) + ", " + F3(v.z) + ")";
}

vec4 vec3To4(vec3 v, float w) {
    return vec4(v.x, v.y, v.z, w);
}

vec3 rgbToXYZ(vec3 v) {
    float r = v.x <= 0.04045 ? (v.x / 12.92) : Math::Pow((v.x + 0.055) / 1.055, 2.4);
    float g = v.y <= 0.04045 ? (v.y / 12.92) : Math::Pow((v.y + 0.055) / 1.055, 2.4);
    float b = v.z <= 0.04045 ? (v.z / 12.92) : Math::Pow((v.z + 0.055) / 1.055, 2.4);
    return vec3(r * 0.4124 + g * 0.3576 + b * 0.1805,
                r * 0.2126 + g * 0.7152 + b * 0.0722,
                r * 0.0193 + g * 0.1192 + b * 0.9505) * 100;
}

vec3 xyzToRGB(vec3 xyz) {
    float x = xyz.x / 100;
    float y = xyz.y / 100;
    float z = xyz.z / 100;
    float r = x * 3.2406 + y * -1.5372 + z * -0.4986;
    float g = x * -0.9689 + y * 1.8758 + z * 0.0415;
    float b = x * 0.0557 + y * -0.204 + z * 1.057;
    r = r > 0.00313 ? (1.055 * Math::Pow(r, 0.4167) - 0.055) : (12.92 * r);
    g = g > 0.00313 ? (1.055 * Math::Pow(g, 0.4167) - 0.055) : (12.92 * g);
    b = b > 0.00313 ? (1.055 * Math::Pow(b, 0.4167) - 0.055) : (12.92 * b);
    return vec3(r, g, b);
}

vec3 xyzToLAB(vec3 xyz) {
    float x = xyz.x / 95.047;
    float y = xyz.y / 100;
    float z = xyz.z / 108.883;
    x = x > 0.008856 ? Math::Pow(x, 0.3333) : (7.787 * x + 0.13793);
    y = y > 0.008856 ? Math::Pow(y, 0.3333) : (7.787 * y + 0.13793);
    z = z > 0.008856 ? Math::Pow(z, 0.3333) : (7.787 * z + 0.13793);
    return vec3(116 * y - 16,
                500 * (x - y),
                200 * (y - z));
}

vec3 labToXYZ(vec3 lab) {
    float y = (lab.x + 16.) / 116.;
    float x = lab.y / 500. + y;
    float z = y - lab.z / 200.;
    x = Math::Pow(x, 3) > 0.008856 ? Math::Pow(x, 3) : ((x - 0.13793) / 7.787);
    y = Math::Pow(y, 3) > 0.008856 ? Math::Pow(y, 3) : ((y - 0.13793) / 7.787);
    z = Math::Pow(z, 3) > 0.008856 ? Math::Pow(z, 3) : ((z - 0.13793) / 7.787);
    return vec3(95.047 * x, 100.0 * y, 108.883 * z);
}

vec3 rgbToHSL(vec3 rgb) {
    float r = rgb.x;
    float g = rgb.y;
    float b = rgb.z;
    float max = Math::Max(r, Math::Max(g, b));
    float min = Math::Min(r, Math::Min(g, b));
    float h, s, l;
    l = (max + min) / 2.;
    if (max == min) {
        h = s = 0;
    } else {
        float d = max - min;
        s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
        h = max == r
            ? (g-b) / d + (g < b ? 6 : 0)
            : max == g
                ? (b - r) / d + 2
                /* it must be that: max == b */
                : (r - g) / d + 4;
        h /= 6;
    }
    return vec3(
        Math::Clamp(h * 360., 0., 360.),
        Math::Clamp(s * 100., 0., 100.),
        Math::Clamp(l * 100., 0., 100.));
}

float h2RGB(float p, float q, float t) {
    if (t < 0) { t += 1; }
    if (t > 1) { t -= 1; }
    if (t < 0.16667) { return p + (q-p) * 6. * t; }
    if (t < 0.5) { return q; }
    if (t < 0.66667) { return p + (q-p) * 6. * (2./3. - t); }
    return p;
}

vec3 hslToRGB(vec3 hsl) {
    float h = hsl.x / 360.;
    float s = hsl.y / 100.;
    float l = hsl.z / 100.;
    float r, g, b, p, q;
    if (s == 0) {
        r = g = b = l;
    } else {
        q = l < 0.5 ? (l + l*s) : (l + s - l*s);
        p = 2.*l - q;
        r = h2RGB(p, q, h + 1./3.);
        g = h2RGB(p, q, h);
        b = h2RGB(p, q, h - 1./3.);
    }
    return vec3(r, g, b);
}



uint8 ToSingleHexCol(float v) {
    if (v < 0) { v = 0; }
    if (v > 15.9999) { v = 15.9999; }
    int u = uint8(Math::Round(v));
    if (u < 10) { return 48 + u; }  /* 48 = '0' */
    return 87 + u;  /* u>=10 and 97 = 'a' */
    // switch (u) {
    //     case 10: return "a";
    //     case 11: return "b";
    //     case 12: return "c";
    //     case 13: return "d";
    //     case 14: return "e";
    //     case 15: return "f";
    // }
    // // should never happen
    // return "F";
}

string rgbToHexTri(vec3 rgb) {
    auto v = rgb * 15;
    string ret = "000";
    ret[0] = ToSingleHexCol(v.x);
    ret[1] = ToSingleHexCol(v.y);
    ret[2] = ToSingleHexCol(v.z);
    return ret;
}

vec3 hexTriToRgb(const string &in hexTri) {
    if (hexTri.Length != 3) { throw ("hextri must have 3 characters. bad input: " + hexTri); }
    try {
        float r = HexCharToInt(hexTri[0]);
        float g = HexCharToInt(hexTri[1]);
        float b = HexCharToInt(hexTri[2]);
        return vec3(r, g, b) / 15.;
    } catch {
        throw("Exception while processing hexTri (" + hexTri + "): " + getExceptionInfo());
    }
    return vec3();
}



class Color {
    ColorTy ty;
    vec3 v;

    Color(vec3 _v, ColorTy _ty = ColorTy::RGB) {
        v = _v; ty = _ty;
    }

    string ToString() {
        return "Color(" + Vec3ToStr(v) + ", " + ColorTyStr(ty) + ")";
    }

    vec4 rgba(float a) {
        auto _v = this.rgb;
        return vec4(_v.x, _v.y, _v.z, a);
    }

    string get_ManiaColor() {
        return "$" + this.HexTri;
    }

    string get_HexTri() {
        return rgbToHexTri(this.rgb);
        // return ""
        //     + ToSingleHexCol(v.x)
        //     + ToSingleHexCol(v.y)
        //     + ToSingleHexCol(v.z);
    }

    void AsLAB() {
        if (ty == ColorTy::LAB) { return; }
        if (ty == ColorTy::XYZ) { v = xyzToLAB(v); }
        if (ty == ColorTy::RGB) { v = xyzToLAB(rgbToXYZ(v)); }
        if (ty == ColorTy::HSL) { v = xyzToLAB(rgbToXYZ(hslToRGB(v))); }
        ty = ColorTy::LAB;
    }

    void AsRGB() {
        if (ty == ColorTy::RGB) { return; }
        if (ty == ColorTy::XYZ) { v = xyzToRGB(v); }
        if (ty == ColorTy::LAB) { v = xyzToRGB(labToXYZ(v)); }
        if (ty == ColorTy::HSL) { v = hslToRGB(v); }
        ty = ColorTy::RGB;
    }

    void AsHSL() {
        if (ty == ColorTy::HSL) { return; }
        if (ty == ColorTy::RGB) { v = rgbToHSL(v); }
        if (ty == ColorTy::XYZ) { v = rgbToHSL(xyzToRGB(v)); }
        if (ty == ColorTy::LAB) { v = rgbToHSL(xyzToRGB(labToXYZ(v))); }
        ty = ColorTy::HSL;
    }

    void AsXYZ() {
        if (ty == ColorTy::XYZ) { return; }
        if (ty == ColorTy::RGB) { v = rgbToXYZ(v); }
        if (ty == ColorTy::LAB) { v = labToXYZ(v); }
        if (ty == ColorTy::HSL) { v = rgbToXYZ(hslToRGB(v)); }
        ty = ColorTy::XYZ;
    }

    Color@ ToLAB() {
        auto ret = Color(v, this.ty);
        ret.AsLAB();
        return ret;
    }

    Color@ ToXYZ() {
        auto ret = Color(v, this.ty);
        ret.AsXYZ();
        return ret;
    }

    Color@ ToRGB() {
        auto ret = Color(v, this.ty);
        ret.AsRGB();
        return ret;
    }

    Color@ ToHSL() {
        auto ret = Color(v, this.ty);
        ret.AsHSL();
        return ret;
    }

    Color@ ToMode(ColorTy mode) {
        switch (mode) {
            case ColorTy::RGB: return ToRGB();
            case ColorTy::XYZ: return ToXYZ();
            case ColorTy::LAB: return ToLAB();
            case ColorTy::HSL: return ToHSL();
        }
        throw("Unknown ColorTy mode: " + mode);
        return ToRGB();
    }

    vec3 get_rgb() {
        if (ty == ColorTy::RGB) { return vec3(v); }
        if (ty == ColorTy::XYZ) { return xyzToRGB(v); }
        if (ty == ColorTy::LAB) { return xyzToRGB(labToXYZ(v)); }
        if (ty == ColorTy::HSL) { return hslToRGB(v); }
        throw("Unknown color type: " + ty);
        return vec3();
    }

    vec3 get_lab() {
        if (ty == ColorTy::LAB) { return vec3(v); }
        if (ty == ColorTy::XYZ) { return xyzToLAB(v); }
        if (ty == ColorTy::RGB) { return xyzToLAB(rgbToXYZ(v)); }
        if (ty == ColorTy::HSL) { return xyzToLAB(rgbToXYZ(hslToRGB(v))); }
        throw("Unknown color type: " + ty);
        return vec3();
    }
}
