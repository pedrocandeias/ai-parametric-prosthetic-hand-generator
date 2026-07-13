#!/usr/bin/env python3
"""
generate_multi_population_hand_csv.py

Generates multi_population_hand.csv from nine population studies:
  - Turkey       : Chatzioglou et al. (2024), n=51, age 18-30
  - Mexico       : Rodríguez-Vega et al. (2024), n=2,837, age 15-59
  - India        : Nag et al. (2003), n=95 women, informal industry workers
  - Portugal     : Anacleto Filho et al. (2023), n=343, industrial workers
  - Nigeria      : Ibiwari et al. (2025), n=80, university athletes
  - Jordan       : Mistarihi (2020), n=40, physically disabled workers, age 20-40
  - USA/D2       : Lim et al. (2018), n=50, index finger (D2) only
  - USA/ANSUR II : Gordon et al. (2015), n=6,068 US military, age 17-58
  - Netherlands  : DINED (kima1993, geron1998, dined2004), children 2-12, elderly 50-80+, adults 20-60+
  - China/Beijing: Hu et al. (2007), n=108 elderly (58F+50M), age 65+

Schema adds two columns vs. ansur_1988_*.csv:
  measurement_method_note — how the measurement was taken
  age_group               — age range of the (sub)sample
"""

import csv
import os

OUTPUT_PATH = os.path.join(os.path.dirname(__file__), "multi_population_hand.csv")

FIELDS = [
    "source_document", "source_page", "source_citation",
    "measurement_name", "body_region", "measurement_method_note",
    "population", "country", "sex", "age_group", "sample_size",
    "stat_type", "percentile", "value_cm", "value_mm", "value_in",
    "data_quality_note",
]


def _cm(v):
    return round(v * 10, 4) if v is not None else None

def _mm(v):
    return round(v / 10, 4) if v is not None else None

def _in(v_cm):
    return round(v_cm / 2.54, 4) if v_cm is not None else None


def row(source_document, source_page, source_citation,
        measurement_name, body_region, measurement_method_note,
        population, country, sex, age_group, sample_size,
        stat_type, percentile,
        value_mm=None, value_cm=None,
        data_quality_note=""):
    if value_mm is not None and value_cm is None:
        value_cm = _mm(value_mm)
    elif value_cm is not None and value_mm is None:
        value_mm = _cm(value_cm)
    return {
        "source_document": source_document,
        "source_page": source_page,
        "source_citation": source_citation,
        "measurement_name": measurement_name,
        "body_region": body_region,
        "measurement_method_note": measurement_method_note,
        "population": population,
        "country": country,
        "sex": sex,
        "age_group": age_group,
        "sample_size": sample_size,
        "stat_type": stat_type,
        "percentile": str(percentile) if percentile != "" else "",
        "value_cm": value_cm,
        "value_mm": value_mm,
        "value_in": _in(value_cm),
        "data_quality_note": data_quality_note,
    }


ROWS = []


# ─────────────────────────────────────────────────────────────
# 1. TURKEY — Chatzioglou, Pinar, Govsa (2024)
#    Anatomy & Cell Biology 57:172-182
#    n=51 (32F, 19M), age 18-30, Izmir / Istanbul
#    Method: photo with ImageJ; pixel→mm via 0.08618× formula
#    Table 1: finger lengths (mm), right hand, by sex
#    Finger = from first proximal palmar crease to distal tip
# ─────────────────────────────────────────────────────────────
TUR_DOC  = "Biometric analysis hand parameters in young adults for prosthetic hand and ergonomic product applications"
TUR_CITE = ("Chatzioglou GN, Pinar Y, Govsa F. (2024). Biometric analysis hand parameters in young adults "
            "for prosthetic hand and ergonomic product applications. "
            "Anatomy & Cell Biology, 57:172-182. https://doi.org/10.5115/acb.23.310")
TUR_POP  = "Young adults (age 18-30)"
TUR_METH = ("Photo-anthropometric (ImageJ); right-hand dominant side; "
            "finger length = first proximal palmar crease to distal phalanx tip; values in mm")

# (mean, std_dev, min, max) per finger × sex; right hand Table 1 p.177
TUR_R = {
    "Thumb":         {"female": (47.8, 2.5, 37.2, 53.2, 32), "male": (48.2, 5.4, 37.2, 62.8, 19)},
    "Index finger":  {"female": (61.4, 3.1, 55.8, 68.4, 32), "male": (66.5, 2.8, 61.8, 71.1, 19)},
    "Middle finger": {"female": (67.9, 3.4, 62.4, 76.5, 32), "male": (75.3, 3.7, 69.4, 80.5, 19)},
    "Ring finger":   {"female": (63.0, 3.3, 56.9, 70.1, 32), "male": (70.6, 3.1, 66.1, 76.0, 19)},
    "Little finger": {"female": (51.4, 2.8, 45.0, 56.5, 32), "male": (58.5, 2.6, 54.0, 63.0, 19)},
}

for finger, sexdata in TUR_R.items():
    mname = f"Finger length (right hand) - {finger}"
    for sex, (mean, sd, mn, mx, n) in sexdata.items():
        for st, val in [("mean", mean), ("std_dev", sd), ("min", mn), ("max", mx)]:
            ROWS.append(row(TUR_DOC, 5, TUR_CITE, mname, "hand", TUR_METH,
                            TUR_POP, "Turkey", sex, "18-30", n,
                            st, "", value_mm=val))

# Total-sample values reported in Table 1 (combined sex)
TUR_TOT = {
    "Thumb":         (50.9, 5.7, 39.3, 68.0, 51),
    "Index finger":  (64.5, 4.3, 56.2, 73.3, 51),
    "Ring finger":   (65.8, 4.9, 56.9, 76.1, 51),
    "Little finger": (52.6, 4.3, 44.0, 61.5, 51),
}

for finger, (mean, sd, mn, mx, n) in TUR_TOT.items():
    mname = f"Finger length (combined, right hand) - {finger}"
    for st, val in [("mean", mean), ("std_dev", sd), ("min", mn), ("max", mx)]:
        ROWS.append(row(TUR_DOC, 5, TUR_CITE, mname, "hand", TUR_METH,
                        TUR_POP, "Turkey", "combined", "18-30", n,
                        st, "", value_mm=val))


# ─────────────────────────────────────────────────────────────
# 2. MEXICO — Rodríguez-Vega & Rodríguez-Vega (2024)
#    European Public & Social Innovation Review 9:1-15
#    n=2,837 (2,275M, 562F), Northwest Mexico, age 15-59
#    Dominant hand; HL/PL/HB in cm, HGD in mm (ISO 7250-1)
#    Table 3: general population. Table 4: by age group.
# ─────────────────────────────────────────────────────────────
MEX_DOC  = "Normative data for the anthropometric hand dimensions of the Mexican population"
MEX_CITE = ("Rodríguez-Vega G, Rodríguez-Vega DA. (2024). Normative data for the anthropometric hand "
            "dimensions of the Mexican population. European Public & Social Innovation Review, 9, 1-15. "
            "https://doi.org/10.31637/epsir-2024-932")
MEX_POP  = "General population, Northwest Mexico"
MEX_METH = ("Traditional caliper (dominant hand); HL=wrist stylion to middle-finger tip; "
            "PL=wrist crease to middle-finger base crease; HB=metacarpal II-V; "
            "HGD=thumb-index grip circle diameter; HL/PL/HB in cm, HGD in mm")

MEX_MNAMES = {
    "HL":  ("Hand length",               "cm"),
    "PL":  ("Palm length",               "cm"),
    "HB":  ("Hand breadth (metacarpal)", "cm"),
    "HGD": ("Hand grip diameter",        "mm"),
}

def mex_rows(age_grp, sex, abbr, mean, sd, p5, p50, p95, n, note=""):
    mname, unit = MEX_MNAMES[abbr]
    is_mm = unit == "mm"
    for st, val, pct in [
        ("mean",       mean, ""), ("std_dev", sd, ""),
        ("percentile", p5,   5),  ("percentile", p50, 50), ("percentile", p95, 95),
    ]:
        if is_mm:
            ROWS.append(row(MEX_DOC, 6, MEX_CITE, mname, "hand", MEX_METH,
                            MEX_POP, "Mexico", sex, age_grp, n,
                            st, pct, value_mm=val, data_quality_note=note))
        else:
            ROWS.append(row(MEX_DOC, 6, MEX_CITE, mname, "hand", MEX_METH,
                            MEX_POP, "Mexico", sex, age_grp, n,
                            st, pct, value_cm=val, data_quality_note=note))

# --- General population (Table 3) ---
mex_rows("15-59", "male",   "HL",  18.82, 0.85, 17.42, 18.80, 20.22, 2275)
mex_rows("15-59", "male",   "PL",  10.77, 0.62,  9.75, 10.70, 11.78, 2275)
mex_rows("15-59", "male",   "HB",   8.79, 0.51,  7.96,  8.80,  9.62, 2275)
mex_rows("15-59", "male",   "HGD", 48.14, 3.86, 41.80, 48.00, 54.48, 2275)
mex_rows("15-59", "female", "HL",  17.46, 0.80, 16.14, 17.40, 18.77,  562)
mex_rows("15-59", "female", "PL",   9.99, 0.56,  9.07, 10.00, 10.90,  562)
mex_rows("15-59", "female", "HB",   7.80, 0.52,  6.94,  7.70,  8.65,  562)
mex_rows("15-59", "female", "HGD", 45.51, 3.66, 39.49, 45.00, 51.53,  562)

# --- Age-group breakdown (Table 4) ---
# Format: age_grp → sex → abbr → (mean, sd, p5, p50, p95, n)
MEX_AGES = {
    "15-19": {
        "male":   {"HL": (18.66,.77,17.39,18.66,19.93,26), "PL": (10.55,.52, 9.69,10.55,11.41,26),
                   "HB": ( 8.43,.55, 7.53, 8.43, 9.34,26), "HGD":(47.38,3.19,42.14,47.38,52.63,26)},
        "female": {"HL": (17.46,.74,16.24,17.46,18.69,16), "PL": (10.18,.52, 9.32,10.18,11.03,16),
                   "HB": ( 7.74,.47, 6.97, 7.74, 8.50,16), "HGD":(47.19,3.69,41.12,47.19,53.26,16)},
    },
    "20-24": {
        "male":   {"HL": (18.80,.79,17.49,18.80,20.11,359),"PL": (10.79,.58, 9.83,10.79,11.76,359),
                   "HB": ( 8.75,.52, 7.89, 8.75, 9.61,359),"HGD":(49.16,3.66,43.14,49.16,55.19,359)},
        "female": {"HL": (17.49,.77,16.22,17.49,18.76,125),"PL": ( 9.95,.53, 9.08, 9.95,10.82,125),
                   "HB": ( 7.90,.50, 7.07, 7.90, 8.73,125),"HGD":(46.26,3.51,40.49,46.26,52.03,125)},
    },
    "25-29": {
        "male":   {"HL": (18.80,.84,17.41,18.80,20.19,415),"PL": (10.80,.72, 9.62,10.80,11.93,415),
                   "HB": ( 8.77,.51, 7.93, 8.77, 9.60,415),"HGD":(48.62,3.73,42.48,48.62,54.76,415)},
        "female": {"HL": (17.45,.76,16.21,17.45,18.70,141),
                   "PL": ( 9.99,.56, 9.08,10.00,10.93,141),  # SD estimated; source cell not clearly legible
                   "HB": ( 7.74,.54, 6.86, 7.74, 8.63,141),"HGD":(45.80,3.60,39.88,45.80,51.72,141)},
    },
    "30-34": {
        "male":   {"HL": (18.87,.82,17.51,18.87,20.22,393),"PL": (10.79,.58, 9.84,10.79,11.75,393),
                   "HB": ( 8.88,.52, 8.02, 8.88, 9.74,393),"HGD":(48.59,3.85,42.26,48.59,54.92,393)},
        "female": {"HL": (17.37,.84,15.99,17.37,18.76,120),"PL": ( 9.93,.64, 8.89, 9.93,10.98,120),
                   "HB": ( 7.75,.46, 6.98, 7.75, 8.51,120),"HGD":(45.32,3.73,39.18,45.32,51.45,120)},
    },
    "35-39": {
        "male":   {"HL": (18.85,.88,17.40,18.85,20.31,456),"PL": (10.76,.61, 9.76,10.76,11.78,456),
                   "HB": ( 8.86,.51, 8.03, 8.86, 9.69,456),"HGD":(47.89,3.91,41.46,47.89,54.32,456)},
        "female": {"HL": (17.43,.74,16.21,17.43,18.64,103),"PL": (10.03,.46, 9.27,10.03,10.79,103),
                   "HB": ( 7.76,.54, 6.87, 7.76, 8.64,103),"HGD":(45.00,3.74,38.85,45.00,51.15,103)},
    },
    "40-44": {
        "male":   {"HL": (18.85,.86,17.43,18.85,20.27,425),"PL": (10.74,.60, 9.76,10.74,11.72,425),
                   "HB": ( 8.75,.48, 7.97, 8.75, 9.53,425),"HGD":(47.34,3.85,41.01,47.34,53.67,425)},
        "female": {"HL": (17.51,.93,15.99,17.51,19.04, 43),"PL": ( 9.92,.53, 9.05, 9.92,10.80, 43),
                   "HB": ( 7.84,.60, 6.86, 7.84, 8.83, 43),"HGD":(43.53,3.28,38.13,43.53,48.94, 43)},
    },
    "45-49": {
        "male":   {"HL": (18.66,.96,17.09,18.66,20.24,161),"PL": (10.65,.60, 9.67,10.65,11.63,161),
                   "HB": ( 8.69,.44, 7.97, 8.69, 9.42,161),"HGD":(46.71,3.71,40.61,46.71,52.82,161)},
        "female": {"HL": (17.94,1.08,16.17,17.94,19.71,10),"PL": (10.30,.61, 9.29,10.30,11.31, 10),
                   "HB": ( 8.07,.52, 7.22, 8.07, 8.92, 10),"HGD":(46.00,2.87,41.28,46.00,50.72, 10)},
    },
    "50-54": {
        "male":   {"HL": (18.85,.78,17.57,18.85,20.12, 33),"PL": (10.70,.41,10.02,10.70,11.38, 33),
                   "HB": ( 8.63,.45, 7.89, 8.63, 9.37, 33),"HGD":(46.85,3.32,41.39,46.85,52.31, 33)},
        "female": {"HL": (17.97,1.53,15.45,17.97,20.48,  3),"PL": (10.33,.76, 9.09,10.33,11.58,  3),
                   "HB": ( 7.73,.00, 7.32, 7.73, 8.15,  3),"HGD":(44.00,2.65,39.65,44.00,48.35,  3)},
    },
}

for age_grp, sexdata in MEX_AGES.items():
    for sex, measdata in sexdata.items():
        for abbr, vals in measdata.items():
            mean, sd, p5, p50, p95, n = vals
            note = ""
            if n <= 10:
                note = f"Small subgroup n={n}; treat with caution"
            if abbr == "PL" and age_grp == "25-29" and sex == "female":
                note = "SD estimated from overall female PL SD; source table cell not clearly legible"
            if abbr == "HB" and age_grp == "50-54" and sex == "female":
                note = f"SD=0.00 reported in source (n=3; likely rounding artefact); small subgroup n={n}"
            mex_rows(age_grp, sex, abbr, mean, sd, p5, p50, p95, n, note)


# ─────────────────────────────────────────────────────────────
# 3. INDIA (WOMEN) — Nag, Nag & Desai (2003)
#    Indian J Med Res 117:260-269
#    n=95 women; Ahmedabad informal industry (beedi, agarbatti, garment)
#    Right hand, flat/straight/unsupported, wrist crease as baseline
#    Tables II-VI; values in cm; P5, P50, P95 reported
# ─────────────────────────────────────────────────────────────
IND_DOC  = "Hand anthropometry of Indian women"
IND_CITE = ("Nag A, Nag PK, Desai H. (2003). Hand anthropometry of Indian women. "
            "Indian Journal of Medical Research, 117, pp 260-269.")
IND_POP  = "Informal industry workers (beedi, agarbatti, garment manufacturing), Ahmedabad"
IND_METH = "Caliper (right hand; flat/straight/unsupported); wrist crease as baseline; values in cm"

def ind(mname, body_region, mean, sd, p5, p50, p95, page):
    for st, val, pct in [
        ("mean", mean, ""), ("std_dev", sd, ""),
        ("percentile", p5, 5), ("percentile", p50, 50), ("percentile", p95, 95),
    ]:
        ROWS.append(row(IND_DOC, page, IND_CITE, mname, body_region, IND_METH,
                        IND_POP, "India", "female", "16-58", 95,
                        st, pct, value_cm=val))

# Table II — Hand lengths (p.3 of PDF)
ind("Hand length (wrist crease to middle fingertip)", "hand", 16.96, 0.94, 15.4, 17.0, 18.4, 3)
ind("Hand height perpendicular to wrist crease - Digit 1 (thumb)",  "hand",  8.21, 1.12,  6.5,  8.1, 10.4, 3)
ind("Hand height perpendicular to wrist crease - Digit 2 (index)",  "hand", 15.62, 0.96, 14.0, 15.5, 17.3, 3)
ind("Hand height perpendicular to wrist crease - Digit 3 (middle)", "hand", 16.94, 0.91, 15.5, 17.0, 18.4, 3)
ind("Hand height perpendicular to wrist crease - Digit 4 (ring)",   "hand", 15.37, 0.90, 13.9, 15.4, 16.9, 3)
ind("Hand height perpendicular to wrist crease - Digit 5 (little)", "hand", 11.39, 1.20,  9.8, 11.5, 13.0, 3)
ind("Finger length to crotch level - Digit 1 (thumb)",   "hand", 6.41, 0.63, 5.3, 6.6, 7.2, 3)
ind("Finger length to crotch level - Digit 2 (index)",   "hand", 6.92, 0.55, 5.9, 7.0, 7.7, 3)
ind("Finger length to crotch level - Digit 3 (middle)",  "hand", 7.60, 0.57, 6.6, 7.6, 8.4, 3)
ind("Finger length to crotch level - Digit 4 (ring)",    "hand", 7.02, 0.54, 6.1, 7.0, 7.8, 3)
ind("Finger length to crotch level - Digit 5 (little)",  "hand", 5.63, 0.54, 4.6, 5.7, 6.4, 3)
ind("Hand length thumb-forefinger",                       "hand", 9.35, 0.79, 8.0, 9.3, 10.6, 3)

# Table III — Breadths (p.4)
ind("Hand breadth metacarpal",                          "hand", 6.80, 0.51, 6.0, 6.8, 7.6, 4)
ind("Interphalangeal joint breadth - Digit 1",          "hand", 1.47, 0.21, 1.1, 1.5, 1.8, 4)
ind("Distal interphalangeal joint breadth - Digit 2",   "hand", 1.04, 0.16, 0.7, 1.1, 1.2, 4)
ind("Proximal interphalangeal joint breadth - Digit 2", "hand", 1.30, 0.17, 1.0, 1.3, 1.5, 4)
ind("Distal interphalangeal joint breadth - Digit 3",   "hand", 1.04, 0.15, 0.8, 1.1, 1.2, 4)
ind("Proximal interphalangeal joint breadth - Digit 3", "hand", 1.33, 0.15, 1.0, 1.3, 1.6, 4)
ind("Wrist breadth",                                    "hand", 4.61, 0.48, 4.1, 4.5, 6.0, 4)
ind("Hand breadth metacarpal (minimum)",                "hand", 6.42, 0.71, 5.4, 6.3, 7.1, 4)
ind("Grip breadth inside",                              "hand", 4.43, 0.56, 3.5, 4.5, 5.2, 4)
ind("Grip breadth outside",                             "hand", 8.35, 0.67, 6.9, 8.4, 9.4, 4)

# Table IV — Circumferences (p.4)
ind("Metacarpal circumference",                              "hand", 17.23, 1.06, 15.0, 17.5, 18.6, 4)
ind("Fingertips even circumference",                         "hand", 18.25, 2.16, 15.3, 18.0, 22.5, 4)
ind("Fist circumference",                                    "hand", 23.51, 1.23, 21.5, 23.5, 25.5, 4)
ind("Wrist circumference",                                   "hand", 14.36, 0.69, 13.2, 14.3, 15.5, 4)
ind("Interphalangeal joint circumference - Digit 1",         "hand",  6.06, 0.30,  5.6,  6.0,  6.5, 4)
ind("Distal interphalangeal joint circumference - Digit 2",  "hand",  4.80, 0.42,  4.2,  4.8,  5.1, 4)
ind("Proximal interphalangeal joint circumference - Digit 2","hand",  5.70, 0.31,  5.2,  5.7,  6.2, 4)
ind("Distal interphalangeal joint circumference - Digit 3",  "hand",  4.91, 0.25,  4.5,  4.9,  5.4, 4)
ind("Proximal interphalangeal joint circumference - Digit 3","hand",  5.92, 0.36,  5.3,  5.9,  6.4, 4)
ind("Hand circumference thumb-forefinger",                   "hand", 22.53, 1.62, 20.0, 22.5, 25.0, 4)
ind("Hand circumference metacarpal (minimum)",               "hand", 18.86, 1.02, 17.3, 19.0, 21.0, 4)

# Table V — Depths (p.5)
ind("Hand depth metacarpal 3",                    "hand", 2.22, 0.24, 1.8, 2.2, 2.6, 5)
ind("Hand depth thenar pad",                      "hand", 3.42, 0.52, 2.6, 3.4, 4.4, 5)
ind("Interphalangeal joint depth - Digit 1",      "hand", 1.15, 0.16, 0.9, 1.2, 1.4, 5)
ind("Interphalangeal joint depth - Digit 2",      "hand", 0.78, 0.15, 0.6, 0.8, 1.0, 5)
ind("Proximal interphalangeal joint depth - Digit 2", "hand", 1.13, 0.15, 0.9, 1.1, 1.4, 5)
ind("Distal interphalangeal joint depth - Digit 3",   "hand", 0.79, 0.13, 0.6, 0.8, 1.0, 5)
ind("Proximal interphalangeal joint depth - Digit 3", "hand", 1.19, 0.13, 1.0, 1.2, 1.4, 5)

# Table VI — Spreads and clearances (p.7)
ind("Fingertip spread Digit 2-3",       "hand",  8.54, 1.46,  5.9,  8.6, 10.7, 7)
ind("Fingertip spread Digit 2-4",       "hand", 10.58, 1.26,  8.9, 10.4, 13.0, 7)
ind("Fingertip spread Digit 2-5",       "hand", 13.74, 1.36, 11.2, 13.8, 16.3, 7)
ind("Hand spread maximum",              "hand", 17.26, 1.46, 15.0, 17.3, 19.3, 7)
ind("Hand clearance around knob",       "hand",  6.89, 0.92,  5.2,  7.1,  8.0, 7)
ind("Hand clearance palmar",            "hand",  2.41, 0.47,  1.6,  2.4,  3.2, 7)
ind("Hand clearance supinated",         "hand", 10.40, 1.07,  8.4, 10.6, 11.9, 7)
ind("Hand spread across wedge 1",       "hand", 10.78, 0.87,  9.4, 11.2, 12.5, 7)
ind("Hand spread across wedge 2",       "hand", 12.53, 0.96, 10.5, 13.0, 14.0, 7)
ind("Hand spread across wedge 3",       "hand", 12.92, 0.91, 11.2, 13.0, 14.4, 7)
ind("Hand spread across wedge 4",       "hand", 12.69, 0.95, 11.1, 13.0, 14.0, 7)


# ─────────────────────────────────────────────────────────────
# 4. PORTUGAL — Anacleto Filho et al. (2023)
#    Int J Ind Ergon 97:103473
#    n=343 (169M, 174F), industrial workers Northern Portugal, 2021
#    Only HandL and HandB are hand-specific in their 27-dim set
#    Sitting position (DA+AS); left-side measured; values in mm
#    Table 3 (p.6 of PDF)
# ─────────────────────────────────────────────────────────────
PRT_DOC  = "Establishing an anthropometric database: A case for the Portuguese working population"
PRT_CITE = ("Anacleto Filho PC, da Silva L, Mattos D, Pombeiro A, Castellucci HI, Colim A, Carneiro P, Arezes P. "
            "(2023). Establishing an anthropometric database: A case for the Portuguese working population. "
            "International Journal of Industrial Ergonomics, 97, 103473. "
            "https://doi.org/10.1016/j.ergon.2023.103473")
PRT_POP  = "Industrial workers, Northern Portugal"
PRT_METH = ("Traditional anthropometer (ISO 7250); left side measured (facility constraint); "
            "sitting position; HandL=styloid process to middle finger tip; HandB=metacarpal II-V; values in mm")

PRT_DATA = {
    "Hand length": {
        "female": (186.5, 8.0, 173.0, 187.0, 200.0, 174),
        "male":   (203.4, 9.2, 187.0, 203.0, 217.0, 169),
    },
    "Hand breadth (metacarpal)": {
        "female": (88.9, 4.2, 82.0, 89.0,  95.0, 174),
        "male":   (98.2, 4.7, 91.5, 98.0, 106.0, 169),
    },
}

for mname, sexdata in PRT_DATA.items():
    for sex, (mean, sd, p5, p50, p95, n) in sexdata.items():
        for st, val, pct in [
            ("mean", mean, ""), ("std_dev", sd, ""),
            ("percentile", p5, 5), ("percentile", p50, 50), ("percentile", p95, 95),
        ]:
            ROWS.append(row(PRT_DOC, 6, PRT_CITE, mname, "hand", PRT_METH,
                            PRT_POP, "Portugal", sex, "16-65", n,
                            st, pct, value_mm=val))


# ─────────────────────────────────────────────────────────────
# 5. NIGERIA — Ibiwari et al. (2025)
#    Int J Sci Acad Res 6(8):10513-10517
#    n=80: basketball n=41 (21M, 20F), volleyball n=39 (20M, 19F)
#    Port Harcourt university athletes; age 19-30; right hand
#    Digital Vernier caliper; digits stretched flat
#    Tables 3 & 4; values in mm
# ─────────────────────────────────────────────────────────────
NIG_DOC  = ("Hand anthropometric measurement and grip strength for basketball and volleyball players "
            "in higher institutions in Port Harcourt metropolis")
NIG_CITE = ("Ibiwari BW, Osemeke BE, Progress VD, Khadija A, Chikere OP. (2025). Hand anthropometric "
            "measurement and grip strength for basketball and volleyball players in higher institutions "
            "in Port Harcourt metropolis. International Journal of Science Academic Research, 6(8), "
            "pp 10513-10517.")
NIG_METH = ("Digital Vernier caliper (Shan 200mm, 0.01mm resolution); digits fully stretched and flat; "
            "right hand; hand length=distal wrist crease to 3rd finger tip; "
            "hand width=metacarpal II-V breadth; values in mm")

# (mean, sd, n) per measurement × sport × sex — right hand, Tables 3 & 4
NIG = {
    "basketball": {
        "male": {
            "Hand length":                      (205.71, 11.54, 21),
            "Hand width":                       ( 88.09, 11.48, 21),
            "Palmar length":                    (116.19, 11.48, 21),
            "3rd digit (middle finger) length": ( 91.08,  8.73, 21),
        },
        "female": {
            "Hand length":                      (201.44,  6.99, 20),
            "Hand width":                       ( 91.80,  9.01, 20),
            "Palmar length":                    (111.57,  9.10, 20),
            "3rd digit (middle finger) length": (100.40, 32.07, 20),  # high SD flagged
        },
    },
    "volleyball": {
        "male": {
            "Hand length":                      (185.95, 37.49, 20),  # high SD flagged
            "Hand width":                       ( 88.63, 19.11, 20),
            "Palmar length":                    (109.08, 22.62, 20),
            "3rd digit (middle finger) length": ( 81.68, 19.22, 20),
        },
        "female": {
            "Hand length":                      (177.51, 21.86, 19),
            "Hand width":                       ( 83.97, 15.07, 19),
            "Palmar length":                    (109.98, 10.92, 19),
            "3rd digit (middle finger) length": ( 79.56, 10.92, 19),
        },
    },
}

for sport, sexdata in NIG.items():
    for sex, measdata in sexdata.items():
        for mname, (mean, sd, n) in measdata.items():
            note = f"Sport subgroup: {sport}"
            if sd > 25:
                note += f"; unusually high SD={sd:.2f}mm — possible outliers in source sample"
            pop = f"University sport athletes ({sport}), Port Harcourt"
            for st, val in [("mean", mean), ("std_dev", sd)]:
                ROWS.append(row(NIG_DOC, 3, NIG_CITE, mname, "hand", NIG_METH,
                                pop, "Nigeria", sex, "19-30", n,
                                st, "", value_mm=val, data_quality_note=note))


# ─────────────────────────────────────────────────────────────
# 6. JORDAN — Mistarihi (2020)
#    Data in Brief 30:105420  DOI:10.1016/j.dib.2020.105420
#    n=40 physically disabled workers, Irbid governorate, Jordan
#    Age 20-40; mixed sex (no sex breakdown in Table 4)
#    7 key body measures; hand length (mm) and elbow-fingertip (cm)
#    in Table 4; hand width (cm) from Figure 2 summary diagram
# ─────────────────────────────────────────────────────────────
JOR_DOC  = ("A data set on anthropometric measurements and degree of discomfort "
            "of physically disabled workers for ergonomic requirements in work space design")
JOR_CITE = ("Mistarihi MZ. (2020). A data set on anthropometric measurements and degree of discomfort "
            "of physically disabled workers for ergonomic requirements in work space design. "
            "Data in Brief, 30, 105420. https://doi.org/10.1016/j.dib.2020.105420")
JOR_POP  = "Physically disabled workers, Irbid governorate"
JOR_METH = ("Stadiometer (seca 213), Holtain Bicondylar Caliper (0-140mm), "
            "Harpenden skinfold caliper (±0.2mm); mixed sex combined; workers age 20-40; "
            "values from Table 4 descriptive statistics")

# Table 4: mean, SD, P5, P95 (n=40, combined sex)
_jor_specs = [
    ("Hand length",          "hand",    "mm", 5, 168.3, 3.9, 162.0, 173.3),
    ("Elbow-fingertip length","forearm", "cm", 5,  42.6, 1.4,  40.0,  45.0),
]
for mname, breg, unit, pg, mean, sd, p5, p95 in _jor_specs:
    is_mm = unit == "mm"
    for st, val, pct in [
        ("mean", mean, ""), ("std_dev", sd, ""),
        ("percentile", p5, 5), ("percentile", p95, 95),
    ]:
        kw = dict(value_mm=val) if is_mm else dict(value_cm=val)
        ROWS.append(row(JOR_DOC, pg, JOR_CITE, mname, breg, JOR_METH,
                        JOR_POP, "Jordan", "combined", "20-40", 40,
                        st, pct, **kw))

# Figure 2: body dimensions diagram (sitting position); hand width = 8.1 cm; no SD given
ROWS.append(row(JOR_DOC, 4, JOR_CITE,
                "Hand width (sitting position)", "hand",
                "Statistical summary diagram (sitting position); no SD reported in source",
                JOR_POP, "Jordan", "combined", "20-40", 40,
                "mean", "", value_cm=8.1,
                data_quality_note="From Figure 2 body-dimensions diagram; no SD or percentiles available"))


# ─────────────────────────────────────────────────────────────
# 7. USA — Lim et al. (2018)
#    Customization of a 3D Printed Prosthetic Finger Using Parametric Modeling
#    UC Berkeley; n=50 adults age 18-30
#    D2 (index finger) only: length = MCP joint crease to fingertip;
#    width = PIP joint width; values in mm; mean only (no SD reported)
# ─────────────────────────────────────────────────────────────
LIM_DOC  = "Customization of a 3D Printed Prosthetic Finger Using Parametric Modeling"
LIM_CITE = ("Lim J et al. (2018). Customization of a 3D Printed Prosthetic Finger Using Parametric Modeling. "
            "UC Berkeley.")
LIM_POP  = "University students/volunteers"
LIM_METH = ("Direct measurement; D2 (index finger) length = MCP joint proximal crease to distal fingertip; "
            "D2 width = PIP (proximal interphalangeal) joint width; values in mm; mean only reported")

_lim_data = [
    ("Index finger (D2) length (MCP crease to tip)", 90.9),
    ("Index finger (D2) width (PIP joint)",           16.9),
]
for mname, mean_val in _lim_data:
    ROWS.append(row(LIM_DOC, 3, LIM_CITE, mname, "hand", LIM_METH,
                    LIM_POP, "USA", "combined", "18-30", 50,
                    "mean", "", value_mm=mean_val,
                    data_quality_note=("Mean only; no SD or percentiles reported; "
                                       "D2 index finger only; R²=0.18 for length-width correlation (weak)")))


# ─────────────────────────────────────────────────────────────
# 8. USA / ANSUR II (2012) — Gordon et al. (2015)
#    NATICK/TR-15/007; n=6,068 (4,082M, 1,986F), US Army, age 17-58
#    Raw individual data released publicly (CC BY 4.0) in 2017
#    Statistics computed from raw CSVs (GitHub: senihberkay/US-Army-ANSUR-II)
#    All values in mm; 7 hand/forearm measurements encoded
#    wristheight excluded (floor-to-wrist standing height, not a hand dimension)
# ─────────────────────────────────────────────────────────────
A2_DOC  = ("2012 Anthropometric Survey of U.S. Army Personnel: "
           "Methods and Summary Statistics")
A2_CITE = ("Gordon CC, Blackwell CL, Bradtmiller B, Parham JL, Barrientos P, "
           "Paquette SP, Corner BD, Carson JM, Venezia JC, Rockwell BM, "
           "Mucher M, Kristensen S. (2015). 2012 Anthropometric Survey of "
           "U.S. Army Personnel: Methods and Summary Statistics. "
           "Report No. NATICK/TR-15/007. U.S. Army Natick Soldier Research, "
           "Development and Engineering Center. "
           "Raw data: ANSUR II Public release (2017), CC BY 4.0.")
A2_POP  = "US Military Personnel (Army)"
A2_METH = ("Standard military anthropometric protocol (ISO 7250 / ANSUR procedures); "
           "standing and sitting postures per measurement; trained measurers; "
           "statistics computed from raw individual data (n=6,068); values in mm")

# (measurement_name, body_region, female_stats, male_stats)
# stats tuple: (mean, sd, min, p5, p10, p25, p50, p75, p90, p95, max, n)
A2_DATA = [
    ("Hand length",                               "hand",
     (181.1, 10.1, 145, 165.0, 169.0, 174.0, 180.0, 187.0, 194.0, 199.0, 220, 1986),
     (193.3,  9.9, 164, 177.0, 181.0, 187.0, 193.0, 200.0, 206.0, 210.0, 239, 4082)),
    ("Hand breadth (metacarpal)",                 "hand",
     ( 78.2,  3.8,  67,  72.0,  73.0,  75.0,  78.0,  80.0,  83.0,  85.0,  92, 1986),
     ( 88.3,  4.4,  74,  81.0,  83.0,  85.0,  88.0,  91.0,  94.0,  96.0, 105, 4082)),
    ("Hand circumference",                        "hand",
     (186.6,  8.8, 152, 173.0, 175.0, 180.0, 187.0, 192.0, 198.0, 202.0, 214, 1986),
     (212.3, 10.2, 179, 195.0, 199.0, 206.0, 212.0, 219.0, 225.0, 230.0, 248, 4082)),
    ("Palm length",                               "hand",
     (108.7,  5.9,  88, 100.0, 102.0, 105.0, 108.0, 113.0, 116.0, 119.0, 130, 1986),
     (116.5,  6.2,  95, 107.0, 109.0, 112.0, 116.0, 120.0, 125.0, 127.0, 140, 4082)),
    ("Wrist circumference",                       "hand",
     (154.8,  7.8, 124, 142.2, 145.0, 150.0, 154.0, 160.0, 165.0, 168.0, 183, 1986),
     (175.9,  9.0, 141, 162.0, 165.0, 170.0, 176.0, 182.0, 187.0, 191.0, 216, 4082)),
    ("Forearm-hand length (elbow to middle fingertip)", "forearm",
     (439.9, 23.4, 342, 404.2, 412.0, 424.0, 438.0, 454.0, 471.0, 480.0, 527, 1986),
     (480.2, 23.3, 400, 444.0, 450.0, 465.0, 480.0, 495.0, 509.0, 519.9, 574, 4082)),
    ("Forearm-center of grip length",             "forearm",
     (317.7, 18.0, 258, 290.0, 296.0, 306.0, 316.0, 329.0, 341.0, 350.0, 392, 1986),
     (349.0, 18.0, 290, 320.0, 326.0, 337.0, 348.5, 361.0, 372.0, 379.0, 416, 4082)),
]

_A2_PCTS = [5, 10, 25, 50, 75, 90, 95]

for mname, breg, f_stats, m_stats in A2_DATA:
    for sex, stats in [("female", f_stats), ("male", m_stats)]:
        mean, sd, mn, p5, p10, p25, p50, p75, p90, p95, mx, n = stats
        pct_vals = [p5, p10, p25, p50, p75, p90, p95]
        for st, val, pct in (
            [("mean", mean, ""), ("std_dev", sd, ""), ("min", mn, ""), ("max", mx, "")] +
            [("percentile", pv, pp) for pv, pp in zip(pct_vals, _A2_PCTS)]
        ):
            ROWS.append(row(A2_DOC, None, A2_CITE, mname, breg, A2_METH,
                            A2_POP, "USA", sex, "17-58", n,
                            st, pct, value_mm=val))


# ─────────────────────────────────────────────────────────────
# 9. NETHERLANDS / DINED — kima1993, geron1998, dined2004
#    TU Delft anthropometric databases, accessed via dined.io.tudelft.nl
#    kima1993 : Dutch children, ages 2-12, by sex and integer age
#    geron1998: Dutch elderly, ages 50-80+, 5-year bands, by sex
#    dined2004: Dutch adults, age groups 20-30, 31-60, 60+, by sex
#    Only mean and SD available from web interface (no percentiles)
#    All values in mm
# ─────────────────────────────────────────────────────────────
_DINED_URL   = "https://dined.io.tudelft.nl"
_KIMA_DOC    = "Dutch children hand anthropometry, DINED kima1993 dataset, TU Delft"
_KIMA_CITE   = ("Steenbekkers LPA, van Beijsterveldt CEM (eds.). (1998). Design-relevant "
                "characteristics of ageing users. Delft University Press. "
                "Data retrieved from DINED database (kima1993), TU Delft, "
                "https://dined.io.tudelft.nl")
_KIMA_POP    = "Dutch children (TU Delft KIMA 1993 study)"
_KIMA_METH   = ("Traditional anthropometry; DINED kima1993 dataset; "
                "mean and SD per integer age (2-12) and sex; no percentiles in database")

_GER_DOC     = "Dutch elderly hand anthropometry, DINED geron1998 dataset, TU Delft"
_GER_CITE    = ("Molenbroek JFM. (1998). Geron study on Dutch elderly anthropometry. "
                "Data retrieved from DINED database (geron1998), TU Delft, "
                "https://dined.io.tudelft.nl")
_GER_POP     = "Dutch elderly (TU Delft Geron 1998 study)"
_GER_METH    = ("Traditional anthropometry; DINED geron1998 dataset; "
                "mean and SD per 5-year age band (50-54 through 80+) and sex; "
                "no percentiles in database")

_D04_DOC     = "Dutch adult hand anthropometry, DINED dined2004 dataset, TU Delft"
_D04_CITE    = ("Molenbroek JFM, Kroon-Ramaekers YMT, Snijders CJ. (2003). "
                "Revision of the Dutch Standard for Furniture in Schools. "
                "Ergonomics, 46(5), 491-498. "
                "Data retrieved from DINED database (dined2004), TU Delft, "
                "https://dined.io.tudelft.nl")
_D04_POP     = "Dutch working-age adults (TU Delft DINED 2004)"
_D04_METH    = ("Traditional anthropometry; DINED dined2004 dataset; "
                "mean and SD per age group (20-30, 31-60, 60+) and sex; "
                "no percentiles in database")

# (measurement_name, body_region)
_DINED_METAS = {
    "Hand length":                  "hand",
    "Hand width (without thumb)":   "hand",
    "Thumb breadth":                "hand",
    "Forefinger breadth":           "hand",
    "Hand width (with thumb)":      "hand",
    "Hand thickness":               "hand",
    "Pink (little finger) breadth": "hand",
    "Middle finger length":         "hand",
    "Hand diameter":                "hand",
    "Grip circumference":           "hand",
}

# sex mapping: DINED → CSV field
_DINED_SEX = {"female": "female", "male": "male", "mixed": "combined"}

def _dined_rows(doc, cite, pop, meth, country, sex_dined, age_group, data_dict,
                data_quality_note=""):
    """Emit mean + std_dev rows for each measurement present in data_dict."""
    sex_csv = _DINED_SEX[sex_dined]
    for mname, (mean_val, sd_val) in data_dict.items():
        breg = _DINED_METAS[mname]
        for st, val in [("mean", mean_val), ("std_dev", sd_val)]:
            ROWS.append(row(doc, None, cite, mname, breg, meth,
                            pop, country, sex_csv, age_group, None,
                            st, "", value_mm=val,
                            data_quality_note=data_quality_note))

# ── kima1993: children ages 2-12, all three sex groups ──────────────────────
# Data: {age: {mname: (mean_mm, sd_mm)}}  — female, male, mixed separately
_KIMA_F = {
    2:  {"Hand length":(102,6),"Hand width (without thumb)":(51,3),"Thumb breadth":(13,1),"Hand thickness":(16,2),"Pink (little finger) breadth":(9,1),"Middle finger length":(45,3),"Hand diameter":(45,3),"Grip circumference":(68,6)},
    3:  {"Hand length":(110,7),"Hand width (without thumb)":(53,3),"Thumb breadth":(13,1),"Hand thickness":(16,2),"Pink (little finger) breadth":(9,1),"Middle finger length":(48,3),"Hand diameter":(46,3),"Grip circumference":(74,6)},
    4:  {"Hand length":(118,7),"Hand width (without thumb)":(55,3),"Thumb breadth":(13,1),"Hand thickness":(17,2),"Pink (little finger) breadth":(9,1),"Middle finger length":(50,3),"Hand diameter":(48,3),"Grip circumference":(76,7)},
    5:  {"Hand length":(126,6),"Hand width (without thumb)":(58,3),"Thumb breadth":(14,1),"Hand thickness":(18,2),"Pink (little finger) breadth":(10,1),"Middle finger length":(54,3),"Hand diameter":(51,3),"Grip circumference":(81,7)},
    6:  {"Hand length":(132,7),"Hand width (without thumb)":(61,3),"Thumb breadth":(14,1),"Hand thickness":(18,2),"Pink (little finger) breadth":(10,1),"Middle finger length":(56,3),"Hand diameter":(52,3),"Grip circumference":(87,8)},
    7:  {"Hand length":(138,7),"Hand width (without thumb)":(64,3),"Thumb breadth":(15,1),"Hand thickness":(20,2),"Pink (little finger) breadth":(10,1),"Middle finger length":(59,3),"Hand diameter":(54,4),"Grip circumference":(92,8)},
    8:  {"Hand length":(143,7),"Hand width (without thumb)":(65,3),"Thumb breadth":(15,1),"Hand thickness":(20,2),"Pink (little finger) breadth":(10,1),"Middle finger length":(62,4),"Hand diameter":(55,3),"Grip circumference":(96,9)},
    9:  {"Hand length":(149,8),"Hand width (without thumb)":(66,4),"Thumb breadth":(15,1),"Hand thickness":(21,2),"Pink (little finger) breadth":(10,1),"Middle finger length":(64,4),"Hand diameter":(56,4),"Grip circumference":(101,8)},
    10: {"Hand length":(156,8),"Hand width (without thumb)":(69,4),"Thumb breadth":(16,1),"Hand thickness":(21,2),"Pink (little finger) breadth":(11,1),"Middle finger length":(67,4),"Hand diameter":(59,4),"Grip circumference":(106,9)},
    11: {"Hand length":(161,9),"Hand width (without thumb)":(71,4),"Thumb breadth":(16,1),"Hand thickness":(22,2),"Pink (little finger) breadth":(11,1),"Middle finger length":(69,5),"Hand diameter":(61,4),"Grip circumference":(110,10)},
    12: {"Hand length":(166,11),"Hand width (without thumb)":(72,5),"Thumb breadth":(17,1),"Hand thickness":(22,2),"Pink (little finger) breadth":(11,1),"Middle finger length":(71,5),"Hand diameter":(61,4),"Grip circumference":(115,12)},
}
_KIMA_M = {
    2:  {"Hand length":(104,6),"Hand width (without thumb)":(52,3),"Thumb breadth":(13,1),"Hand thickness":(16,2),"Pink (little finger) breadth":(9,1),"Middle finger length":(45,3),"Hand diameter":(47,3),"Grip circumference":(68,6)},
    3:  {"Hand length":(112,6),"Hand width (without thumb)":(54,3),"Thumb breadth":(14,1),"Hand thickness":(17,2),"Pink (little finger) breadth":(10,1),"Middle finger length":(49,3),"Hand diameter":(48,3),"Grip circumference":(75,7)},
    4:  {"Hand length":(119,7),"Hand width (without thumb)":(56,3),"Thumb breadth":(14,1),"Hand thickness":(17,2),"Pink (little finger) breadth":(10,1),"Middle finger length":(51,3),"Hand diameter":(50,3),"Grip circumference":(76,6)},
    5:  {"Hand length":(127,7),"Hand width (without thumb)":(60,3),"Thumb breadth":(15,1),"Hand thickness":(19,2),"Pink (little finger) breadth":(10,1),"Middle finger length":(54,4),"Hand diameter":(53,3),"Grip circumference":(82,7)},
    6:  {"Hand length":(133,6),"Hand width (without thumb)":(62,3),"Thumb breadth":(15,1),"Hand thickness":(19,2),"Pink (little finger) breadth":(10,1),"Middle finger length":(57,3),"Hand diameter":(53,3),"Grip circumference":(86,7)},
    7:  {"Hand length":(139,7),"Hand width (without thumb)":(64,3),"Thumb breadth":(16,1),"Hand thickness":(20,2),"Pink (little finger) breadth":(10,1),"Middle finger length":(59,4),"Hand diameter":(55,4),"Grip circumference":(91,8)},
    8:  {"Hand length":(145,7),"Hand width (without thumb)":(66,3),"Thumb breadth":(16,1),"Hand thickness":(21,2),"Pink (little finger) breadth":(11,1),"Middle finger length":(62,4),"Hand diameter":(56,4),"Grip circumference":(96,7)},
    9:  {"Hand length":(151,7),"Hand width (without thumb)":(69,4),"Thumb breadth":(17,1),"Hand thickness":(21,2),"Pink (little finger) breadth":(11,1),"Middle finger length":(64,4),"Hand diameter":(58,4),"Grip circumference":(101,8)},
    10: {"Hand length":(156,9),"Hand width (without thumb)":(71,4),"Thumb breadth":(17,1),"Hand thickness":(22,2),"Pink (little finger) breadth":(11,1),"Middle finger length":(67,4),"Hand diameter":(59,4),"Grip circumference":(105,10)},
    11: {"Hand length":(161,9),"Hand width (without thumb)":(73,4),"Thumb breadth":(17,1),"Hand thickness":(22,2),"Pink (little finger) breadth":(12,1),"Middle finger length":(69,5),"Hand diameter":(62,5),"Grip circumference":(109,10)},
    12: {"Hand length":(167,10),"Hand width (without thumb)":(74,4),"Thumb breadth":(18,1),"Hand thickness":(23,2),"Pink (little finger) breadth":(12,1),"Middle finger length":(71,5),"Hand diameter":(64,4),"Grip circumference":(111,10)},
}
_KIMA_X = {
    2:  {"Hand length":(103,6),"Hand width (without thumb)":(52,3),"Thumb breadth":(13,1),"Hand thickness":(16,2),"Pink (little finger) breadth":(9,1),"Middle finger length":(45,3),"Hand diameter":(46,3),"Grip circumference":(68,6)},
    3:  {"Hand length":(111,7),"Hand width (without thumb)":(54,3),"Thumb breadth":(14,1),"Hand thickness":(17,2),"Pink (little finger) breadth":(10,1),"Middle finger length":(49,3),"Hand diameter":(47,3),"Grip circumference":(75,7)},
    4:  {"Hand length":(119,7),"Hand width (without thumb)":(56,3),"Thumb breadth":(14,1),"Hand thickness":(17,2),"Pink (little finger) breadth":(10,1),"Middle finger length":(51,3),"Hand diameter":(49,3),"Grip circumference":(76,7)},
    5:  {"Hand length":(127,7),"Hand width (without thumb)":(59,3),"Thumb breadth":(15,1),"Hand thickness":(19,2),"Pink (little finger) breadth":(10,1),"Middle finger length":(54,4),"Hand diameter":(52,3),"Grip circumference":(82,7)},
    6:  {"Hand length":(133,7),"Hand width (without thumb)":(62,3),"Thumb breadth":(15,1),"Hand thickness":(19,2),"Pink (little finger) breadth":(10,1),"Middle finger length":(57,3),"Hand diameter":(53,3),"Grip circumference":(87,8)},
    7:  {"Hand length":(139,7),"Hand width (without thumb)":(64,3),"Thumb breadth":(16,1),"Hand thickness":(20,2),"Pink (little finger) breadth":(10,1),"Middle finger length":(59,4),"Hand diameter":(55,4),"Grip circumference":(92,8)},
    8:  {"Hand length":(144,7),"Hand width (without thumb)":(66,3),"Thumb breadth":(16,1),"Hand thickness":(21,2),"Pink (little finger) breadth":(11,1),"Middle finger length":(62,4),"Hand diameter":(56,4),"Grip circumference":(96,8)},
    9:  {"Hand length":(150,8),"Hand width (without thumb)":(68,4),"Thumb breadth":(16,1),"Hand thickness":(21,2),"Pink (little finger) breadth":(11,1),"Middle finger length":(64,4),"Hand diameter":(57,4),"Grip circumference":(101,8)},
    10: {"Hand length":(156,9),"Hand width (without thumb)":(70,4),"Thumb breadth":(17,1),"Hand thickness":(22,2),"Pink (little finger) breadth":(11,1),"Middle finger length":(67,4),"Hand diameter":(59,4),"Grip circumference":(106,10)},
    11: {"Hand length":(161,9),"Hand width (without thumb)":(72,4),"Thumb breadth":(17,1),"Hand thickness":(22,2),"Pink (little finger) breadth":(12,1),"Middle finger length":(69,5),"Hand diameter":(62,5),"Grip circumference":(110,10)},
    12: {"Hand length":(167,11),"Hand width (without thumb)":(73,5),"Thumb breadth":(18,1),"Hand thickness":(23,2),"Pink (little finger) breadth":(12,1),"Middle finger length":(71,5),"Hand diameter":(63,4),"Grip circumference":(113,11)},
}
_KIMA_NOTE = ("Sample size per age/sex group not published in DINED web interface; "
              "DINED reports integer-year age groups; no percentiles available")
for age, data in _KIMA_F.items():
    _dined_rows(_KIMA_DOC, _KIMA_CITE, _KIMA_POP, _KIMA_METH, "Netherlands",
                "female", str(age), data, _KIMA_NOTE)
for age, data in _KIMA_M.items():
    _dined_rows(_KIMA_DOC, _KIMA_CITE, _KIMA_POP, _KIMA_METH, "Netherlands",
                "male", str(age), data, _KIMA_NOTE)
for age, data in _KIMA_X.items():
    _dined_rows(_KIMA_DOC, _KIMA_CITE, _KIMA_POP, _KIMA_METH, "Netherlands",
                "mixed", str(age), data, _KIMA_NOTE)


# ── geron1998: elderly 50-54 through 80+, all three sex groups ──────────────
_GER_AGES = ["50-54","55-59","60-64","65-69","70-74","75-79","80+"]
_GER_F = [
    {"Hand length":(179,7),"Hand width (without thumb)":(81,4),"Thumb breadth":(21,1),"Forefinger breadth":(16,1),"Grip circumference":(123,11)},
    {"Hand length":(180,8),"Hand width (without thumb)":(81,4),"Thumb breadth":(22,2),"Forefinger breadth":(16,1),"Grip circumference":(126,10)},
    {"Hand length":(179,9),"Hand width (without thumb)":(81,4),"Thumb breadth":(22,2),"Forefinger breadth":(17,2),"Grip circumference":(121,12)},
    {"Hand length":(179,7),"Hand width (without thumb)":(81,4),"Thumb breadth":(21,1),"Forefinger breadth":(17,2),"Grip circumference":(120,10)},
    {"Hand length":(179,9),"Hand width (without thumb)":(81,4),"Thumb breadth":(21,2),"Forefinger breadth":(17,2),"Grip circumference":(121,10)},
    {"Hand length":(178,10),"Hand width (without thumb)":(81,4),"Thumb breadth":(22,2),"Forefinger breadth":(17,1),"Grip circumference":(117,14)},
    {"Hand length":(174,9),"Hand width (without thumb)":(80,4),"Thumb breadth":(21,2),"Forefinger breadth":(17,1),"Grip circumference":(114,11)},
]
_GER_M = [
    {"Hand length":(195,10),"Hand width (without thumb)":(91,4),"Thumb breadth":(24,2),"Forefinger breadth":(19,2),"Grip circumference":(131,14)},
    {"Hand length":(193,11),"Hand width (without thumb)":(91,4),"Thumb breadth":(25,1),"Forefinger breadth":(19,1),"Grip circumference":(129,12)},
    {"Hand length":(195,9),"Hand width (without thumb)":(90,4),"Thumb breadth":(24,2),"Forefinger breadth":(19,1),"Grip circumference":(131,9)},
    {"Hand length":(191,10),"Hand width (without thumb)":(89,5),"Thumb breadth":(24,2),"Forefinger breadth":(18,2),"Grip circumference":(129,10)},
    {"Hand length":(192,11),"Hand width (without thumb)":(90,5),"Thumb breadth":(24,2),"Forefinger breadth":(19,2),"Grip circumference":(129,14)},
    {"Hand length":(190,9),"Hand width (without thumb)":(90,5),"Thumb breadth":(24,2),"Forefinger breadth":(18,2),"Grip circumference":(127,9)},
    {"Hand length":(188,12),"Hand width (without thumb)":(89,4),"Thumb breadth":(24,2),"Forefinger breadth":(18,2),"Grip circumference":(124,11)},
]
_GER_X = [
    {"Hand length":(187,12),"Hand width (without thumb)":(86,6),"Thumb breadth":(23,2),"Forefinger breadth":(18,2),"Grip circumference":(127,13)},
    {"Hand length":(187,12),"Hand width (without thumb)":(86,6),"Thumb breadth":(24,2),"Forefinger breadth":(18,2),"Grip circumference":(128,11)},
    {"Hand length":(187,12),"Hand width (without thumb)":(86,6),"Thumb breadth":(23,2),"Forefinger breadth":(18,2),"Grip circumference":(126,12)},
    {"Hand length":(185,11),"Hand width (without thumb)":(85,6),"Thumb breadth":(23,2),"Forefinger breadth":(18,2),"Grip circumference":(125,11)},
    {"Hand length":(186,12),"Hand width (without thumb)":(86,6),"Thumb breadth":(23,3),"Forefinger breadth":(18,2),"Grip circumference":(125,13)},
    {"Hand length":(184,11),"Hand width (without thumb)":(86,6),"Thumb breadth":(23,2),"Forefinger breadth":(18,2),"Grip circumference":(122,13)},
    {"Hand length":(181,13),"Hand width (without thumb)":(85,6),"Thumb breadth":(23,3),"Forefinger breadth":(18,2),"Grip circumference":(119,12)},
]
_GER_NOTE = ("Sample size per age/sex group not published in DINED web interface; "
             "no percentiles available from database interface")
for i, ag in enumerate(_GER_AGES):
    _dined_rows(_GER_DOC, _GER_CITE, _GER_POP, _GER_METH, "Netherlands",
                "female", ag, _GER_F[i], _GER_NOTE)
    _dined_rows(_GER_DOC, _GER_CITE, _GER_POP, _GER_METH, "Netherlands",
                "male", ag, _GER_M[i], _GER_NOTE)
    _dined_rows(_GER_DOC, _GER_CITE, _GER_POP, _GER_METH, "Netherlands",
                "mixed", ag, _GER_X[i], _GER_NOTE)


# ── dined2004: adults 20-30, 31-60, 60+, all three sex groups ───────────────
# (20-60 combined age group omitted — redundant summary of 20-30 + 31-60)
_D04_AGES = ["20-30","31-60","60+"]
_D04_F = [
    {"Hand length":(177,8),"Hand width (without thumb)":(79,4),"Thumb breadth":(20,1),"Forefinger breadth":(15,1),"Hand width (with thumb)":(89,8),"Hand thickness":(25,3),"Grip circumference":(122,9)},
    {"Hand length":(179,8),"Hand width (without thumb)":(81,4),"Thumb breadth":(21,1),"Forefinger breadth":(16,1),"Hand width (with thumb)":(93,6),"Hand thickness":(27,5)},
    {"Hand length":(178,9),"Hand width (without thumb)":(81,4),"Thumb breadth":(21,2),"Forefinger breadth":(17,2),"Hand width (with thumb)":(94,6),"Hand thickness":(27,5)},
]
_D04_M = [
    {"Hand length":(197,11),"Hand width (without thumb)":(91,5),"Thumb breadth":(23,2),"Forefinger breadth":(18,1),"Hand width (with thumb)":(108,4),"Hand thickness":(28,2),"Grip circumference":(135,13)},
    {"Hand length":(194,10),"Hand width (without thumb)":(91,4),"Thumb breadth":(25,2),"Forefinger breadth":(19,1),"Hand width (with thumb)":(119,5),"Hand thickness":(29,3)},
    {"Hand length":(191,10),"Hand width (without thumb)":(90,5),"Thumb breadth":(24,2),"Forefinger breadth":(18,2),"Hand width (with thumb)":(111,5),"Hand thickness":(29,3)},
]
_D04_X = [
    {"Hand length":(186,14),"Hand width (without thumb)":(84,8),"Thumb breadth":(21,2),"Forefinger breadth":(16,2),"Hand width (with thumb)":(97,9),"Hand thickness":(24,6),"Grip circumference":(129,13)},
    {"Hand length":(186,12),"Hand width (without thumb)":(86,7),"Thumb breadth":(23,2),"Forefinger breadth":(18,2),"Hand width (with thumb)":(103,9),"Hand thickness":(26,6)},
    {"Hand length":(184,12),"Hand width (without thumb)":(85,6),"Thumb breadth":(23,2),"Forefinger breadth":(18,2),"Hand width (with thumb)":(103,8),"Hand thickness":(28,6)},
]
_D04_NOTE = ("Sample size per age/sex group not published in DINED web interface; "
             "no percentiles available; grip circumference only available for 20-30 age group")
for i, ag in enumerate(_D04_AGES):
    _dined_rows(_D04_DOC, _D04_CITE, _D04_POP, _D04_METH, "Netherlands",
                "female", ag, _D04_F[i], _D04_NOTE)
    _dined_rows(_D04_DOC, _D04_CITE, _D04_POP, _D04_METH, "Netherlands",
                "male", ag, _D04_M[i], _D04_NOTE)
    _dined_rows(_D04_DOC, _D04_CITE, _D04_POP, _D04_METH, "Netherlands",
                "mixed", ag, _D04_X[i], _D04_NOTE)


# ─────────────────────────────────────────────────────────────
# 10. CHINA / Beijing elderly — Hu et al. (2007)
#     Int. J. Industrial Ergonomics 37:303-311
#     DOI: 10.1016/j.ergon.2006.11.006
#     n=58F + 50M, age 65-85, Beijing area, community-dwelling
#     5 hand/forearm measurements; Table 1 (mean, SD) + Table 2 (P5, P50, P95)
#     "Finger length" as defined in GB/T 5703-1999 (equiv. ISO 7250:1996);
#     assumed middle finger; paper uses generic label — see data_quality_note
# ─────────────────────────────────────────────────────────────
_HU_DOC  = ("Anthropometric measurement of the Chinese elderly living "
            "in the Beijing area")
_HU_CITE = ("Hu H, Li Z, Yan J, Wang X, Xiao H, Duan J, Zheng L. (2007). "
            "Anthropometric measurement of the Chinese elderly living in the "
            "Beijing area. International Journal of Industrial Ergonomics, "
            "37(4), 303-311. https://doi.org/10.1016/j.ergon.2006.11.006")
_HU_POP  = "Chinese elderly (Beijing)"
_HU_METH = ("Sliding caliper and spreading caliper; measurements per Chinese "
            "national standard GB/T 5703-1999 (equivalent to ISO 7250:1996); "
            "trained examiners; subjects lightly clothed")

# (measurement_name, body_region,
#  female: (mean, sd, p5, p50, p95, n),
#  male:   (mean, sd, p5, p50, p95, n))
_HU_DATA = [
    ("Hand breadth (metacarpal)", "hand",
     (78,  4.2, 73, 78,  85,  58),
     (84,  4.5, 77, 83,  92,  50)),
    ("Maximum hand breadth",      "hand",
     (95,  5.5, 87, 94, 102,  58),
     (102, 6.3, 91, 102, 113, 50)),
    ("Hand length",               "hand",
     (168, 8.1, 159, 166, 183, 58),
     (179, 8.1, 164, 179, 193, 50)),
    ("Finger length (middle finger)", "hand",
     (66,  4.1, 60, 66, 75, 58),
     (69,  4.7, 61, 70, 79, 48)),
    ("Forearm-fingertip length",  "forearm",
     (431, 24.9, 390, 432, 464, 56),
     (455, 27.7, 397, 459, 490, 50)),
]

_HU_FNG_NOTE = ("'Finger length' as labelled in GB/T 5703-1999; "
                "assumed middle finger MCP-to-tip; paper does not specify "
                "which finger explicitly")

for mname, breg, f_stats, m_stats in _HU_DATA:
    dq = _HU_FNG_NOTE if "middle finger" in mname else ""
    for sex, (mean, sd, p5, p50, p95, n) in [("female", f_stats), ("male", m_stats)]:
        for st, val, pct in [
            ("mean",       mean, ""),
            ("std_dev",    sd,   ""),
            ("percentile", p5,   5),
            ("percentile", p50,  50),
            ("percentile", p95,  95),
        ]:
            ROWS.append(row(_HU_DOC, "305-308", _HU_CITE,
                            mname, breg, _HU_METH,
                            _HU_POP, "China", sex, "65+", n,
                            st, pct, value_mm=val,
                            data_quality_note=dq))


# ─────────────────────────────────────────────────────────────
# WRITE OUTPUT
# ─────────────────────────────────────────────────────────────
with open(OUTPUT_PATH, "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=FIELDS)
    w.writeheader()
    for r in ROWS:
        w.writerow(r)

print(f"Written {len(ROWS)} rows → {OUTPUT_PATH}")

by_country = {}
by_source  = {}
for r in ROWS:
    by_country[r["country"]] = by_country.get(r["country"], 0) + 1
    by_source[r["source_document"][:55]] = by_source.get(r["source_document"][:55], 0) + 1

print("\nRows by country:")
for k, v in sorted(by_country.items()):
    print(f"  {k:<12} {v:>5}")
print("\nRows by source:")
for k, v in sorted(by_source.items()):
    print(f"  {k}…  {v}")
print(f"\nTotal: {len(ROWS)} rows")
