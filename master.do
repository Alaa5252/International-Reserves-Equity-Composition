********************************************************************************
********************************************************************************
********************************************************************************
*** Replication Code: International Reserves, Global Financial Risk, and
* the Composition of Foreign Equity Investment in the
* Recent Era of Financial Globalization.
********************************************************************************
********************************************************************************
********************************************************************************

********************************************************************************
********************************************************************************
** Data Preparation
********************************************************************************
********************************************************************************

********************************************************************************
* Defining project folders, starting a new log, and loading the base panel dataset
********************************************************************************

version 19.5
clear all
set more off
capture log close _all
set seed 123456

********************************************************************************
* Defining the folders used throughout the replication
********************************************************************************

global INPUT   "data/input"
global DERIVED "data/derived"
global FIGURES "output/figures"
global LOGS    "output/logs"

********************************************************************************
* Creating generated-data and output folders if they do not already exist
********************************************************************************

capture mkdir "data/derived"
capture mkdir "output"
capture mkdir "output/figures"
capture mkdir "output/logs"

********************************************************************************
* Starting the replication log
********************************************************************************

log using "$LOGS/master.log", text replace

********************************************************************************
* Loading the base panel dataset
********************************************************************************

use "$INPUT/base_panel_data.dta", clear


********************************************************************************
********************************************************************************
* Constructing the Analysis Dataset
********************************************************************************
********************************************************************************

********************************************************************************
* Merging global annual variables
********************************************************************************

local annual_files ///
    vix ///
    vixa ///
    us_3m_rate_a

tempfile imported_data

foreach file of local annual_files {

    display as text "Importing and merging `file'.xlsx"

    preserve
        import excel "$INPUT/`file'.xlsx", firstrow clear
        isid year
        save "`imported_data'", replace
    restore

    merge m:1 year using "`imported_data'", ///
        keep(master match) nogen
}


********************************************************************************
* Merging country-year variables
********************************************************************************

local panel_files ///
    pel ///
    fdil ///
    share_pel ///
    reserves ///
    tl ///
    rtl ///
    gdp_per_capita_cus ///
    gdp_per_capita ///
    gdppk_growth ///
    total_natural_resources_rent ///
    trade_open ///
    exrr ///
    control_of_corruption ///
    rule_of_law ///
    government_effectiveness ///
    voice_and_accountability ///
    regulatory_quality ///
    pol_stab ///
    aded ///
    rtg ///
    gross_dp

foreach file of local panel_files {

    display as text "Importing and merging `file'.xlsx"

    preserve
        import excel "$INPUT/`file'.xlsx", firstrow clear
        isid countrycode year
        save "`imported_data'", replace
    restore

    merge 1:1 countrycode year using "`imported_data'", ///
        keep(master match) nogen
}


********************************************************************************
********************************************************************************
* Variable Transformations
********************************************************************************
********************************************************************************

sort cn year
xtset cn year

generate lpel  = log(1 + pel)
generate lfdil = log(1 + fdil)

local first_lag_variables ///
    trade_open ///
    rtl ///
    gdppk_growth ///
    total_natural_resources_rent ///
    control_of_corruption ///
    rule_of_law ///
    government_effectiveness ///
    share_pel ///
    gdp_per_capita_cus ///
    exrr ///
    us_3m_rate_a ///
    vix ///
    vixa

foreach variable of local first_lag_variables {
    generate L1_`variable' = L.`variable'
}

generate L2_rtl = L2.rtl


********************************************************************************
********************************************************************************
* Required Packages and Completed Analysis Dataset
********************************************************************************
********************************************************************************

********************************************************************************
* Installing required user-written commands when unavailable
********************************************************************************

capture which xtendothresdpd
if _rc {
    display as text "Installing required package: xtendothresdpd"
    ssc install xtendothresdpd
}

capture which locproj
if _rc {
    display as text "Installing required package: locproj"
    ssc install locproj
}

capture which xthreg
if _rc {
    display as text "Installing required package: xthreg"
    net install st0373, ///
        from("https://www.stata-journal.com/software/sj15-1/")
}

* Moremata is a Mata library required by user-written routines
capture findfile lmoremata.mlib
if _rc {
    display as text "Installing required package: moremata"
    ssc install moremata
}


********************************************************************************
* Saving the completed dataset
********************************************************************************

save "$DERIVED/analysis_data.dta", replace


********************************************************************************
********************************************************************************
** Data and Descriptive Evidence
********************************************************************************
********************************************************************************

********************************************************************************
* Table 1. Descriptive statistics for the main variables
********************************************************************************

use "$DERIVED/analysis_data.dta", clear
keep if inrange(year, 2001, 2020)

* Construct and label the reported variables

capture drop fpis
generate double fpis = share_pel

capture drop res
generate double res = rtl

capture drop vix_average
generate double vix_average = vixa

capture drop vix_end_year
generate double vix_end_year = vix

label variable fpis ///
    "FPI share"

label variable res ///
    "Reserves/total external liabilities"

label variable vix_average ///
    "VIX (annual average)"

label variable vix_end_year ///
    "VIX (end of year)"

set linesize 255


********************************************************************************
* Country-varying variables: Full Sample, AEs, and EMDEs
********************************************************************************

local country_variables ///
    fpis ///
    res

foreach sample in Full AEs EMDEs {

    preserve

        * Define the sample

        if "`sample'" == "Full" {
            local sample_title ///
                "FULL SAMPLE"
        }

        if "`sample'" == "AEs" {
            keep if aded == 1
            local sample_title ///
                "ADVANCED ECONOMIES"
        }

        if "`sample'" == "EMDEs" {
            keep if aded == 2
            local sample_title ///
                "EMERGING MARKET AND DEVELOPING ECONOMIES"
        }

        * Display sample information

        quietly count
        local number_observations = r(N)

        egen byte country_tag = tag(cn)

        quietly count if country_tag == 1
        local number_countries = r(N)

        drop country_tag

        display as text ///
            _newline ///
            "============================================================"

        display as text ///
            "`sample_title'"

        display as text ///
            "Countries: `number_countries'; country-year observations: `number_observations'"

        display as text ///
            "============================================================"

        * Descriptive statistics

        tabstat ///
            `country_variables', ///
            statistics( ///
                n ///
                mean ///
                sd ///
                min ///
                max ///
            ) ///
            columns(statistics) ///
            format(%15.6f) ///
            longstub

    restore
}


********************************************************************************
* Global financial-risk variables
********************************************************************************

preserve

 

    bysort year: egen double vix_average_min = ///
        min(vix_average)

    bysort year: egen double vix_average_max = ///
        max(vix_average)

    bysort year: egen double vix_end_year_min = ///
        min(vix_end_year)

    bysort year: egen double vix_end_year_max = ///
        max(vix_end_year)

    assert vix_average_min == vix_average_max ///
        if !missing(vix_average_min, vix_average_max)

    assert vix_end_year_min == vix_end_year_max ///
        if !missing(vix_end_year_min, vix_end_year_max)

    drop ///
        vix_average_min ///
        vix_average_max ///
        vix_end_year_min ///
        vix_end_year_max


    collapse ///
        (firstnm) vix_average vix_end_year, ///
        by(year)

    isid year

    quietly count
    assert r(N) == 20

    display as text ///
        _newline ///
        "============================================================"

    display as text ///
        "GLOBAL FINANCIAL-RISK VARIABLES"

    display as text ///
        "Annual observations: 20"

    display as text ///
        "============================================================"

    tabstat ///
        vix_average ///
        vix_end_year, ///
        statistics( ///
            n ///
            mean ///
            sd ///
            min ///
            max ///
        ) ///
        columns(statistics) ///
        format(%15.6f) ///
        longstub

restore


********************************************************************************
* Table B.1. Comprehensive descriptive statistics for the full sample
********************************************************************************

use "$DERIVED/analysis_data.dta", clear
keep if inrange(year, 2001, 2020)


capture drop lpel
generate double lpel = ///
    ln(pel) if pel > 0

capture drop lfdil
generate double lfdil = ///
    ln(fdil) if fdil > 0

capture drop pel_gdp
generate double pel_gdp = ///
    100 * (pel / gross_dp) ///
    if gross_dp > 0 & ///
    !missing(pel, gross_dp)

capture drop fdil_gdp
generate double fdil_gdp = ///
    100 * (fdil / gross_dp) ///
    if gross_dp > 0 & ///
    !missing(fdil, gross_dp)

capture drop total_equity_gdp
generate double total_equity_gdp = ///
    100 * ((pel + fdil) / gross_dp) ///
    if gross_dp > 0 & ///
    !missing(pel, fdil, gross_dp)

set linesize 255


********************************************************************************
* Panel A. Foreign equity liabilities and their composition
********************************************************************************

tabstat ///
    pel ///
    fdil ///
    share_pel ///
    lpel ///
    lfdil ///
    pel_gdp ///
    fdil_gdp ///
    total_equity_gdp, ///
    statistics(n mean sd min max) ///
    columns(statistics) ///
    format(%15.3f) ///
    longstub


********************************************************************************
* Panel B. International reserves and external liabilities
********************************************************************************

tabstat ///
    reserves ///
    tl ///
    gross_dp ///
    rtl ///
    rtg, ///
    statistics(n mean sd min max) ///
    columns(statistics) ///
    format(%15.3f) ///
    longstub


********************************************************************************
* Panel C. Global factors
********************************************************************************

preserve


    foreach variable in vixa vix us_3m_rate_a {

        bysort year: egen double minimum_`variable' = ///
            min(`variable')

        bysort year: egen double maximum_`variable' = ///
            max(`variable')

        assert minimum_`variable' == maximum_`variable' ///
            if !missing( ///
                minimum_`variable', ///
                maximum_`variable' ///
            )

        drop ///
            minimum_`variable' ///
            maximum_`variable'
    }


    collapse ///
        (firstnm) ///
        vixa ///
        vix ///
        us_3m_rate_a, ///
        by(year)

    isid year
    assert _N == 20

    tabstat ///
        vixa ///
        vix ///
        us_3m_rate_a, ///
        statistics(n mean sd min max) ///
        columns(statistics) ///
        format(%15.3f) ///
        longstub

restore


********************************************************************************
* Panel D. Domestic factors
********************************************************************************

tabstat ///
    gdp_per_capita_cus ///
    gdppk_growth ///
    trade_open ///
    total_natural_resources_rent, ///
    statistics(n mean sd min max) ///
    columns(statistics) ///
    format(%15.3f) ///
    longstub


********************************************************************************
* Panel E. Institutional-quality indicators
********************************************************************************

tabstat ///
    control_of_corruption ///
    government_effectiveness ///
    rule_of_law ///
    voice_and_accountability ///
    regulatory_quality ///
    pol_stab, ///
    statistics(n mean sd min max) ///
    columns(statistics) ///
    format(%15.3f) ///
    longstub


********************************************************************************
* Figure 1. Foreign equity investment and its composition
********************************************************************************

set scheme s2color


local total_color "31 78 121"
local fpi_color   "46 117 182"
local fdi_color   "112 173 219"

foreach sample in Full AEs EMDEs {

    use "$DERIVED/analysis_data.dta", clear


    local sample_title = cond("`sample'" == "Full", "Full Sample", "`sample'")
    local suffix       = cond("`sample'" == "Full", "FullSample", "`sample'")

    if "`sample'" != "Full" {
        local group = cond("`sample'" == "AEs", 1, 2)
        keep if aded == `group'
    }

    local share_pattern = cond("`sample'" == "AEs",   "longdash", "solid")
    local share_width   = cond("`sample'" == "EMDEs", "thin",     "thick")
    local share_marker  = cond("`sample'" == "EMDEs", "O",        "none")
    local marker_size   = cond("`sample'" == "EMDEs", "small",    "vsmall")

   

    generate total_equity_gdp = 100 * ((pel + fdil) / gross_dp)
    generate pel_gdp          = 100 * (pel / gross_dp)
    generate fdil_gdp         = 100 * (fdil / gross_dp)
    generate fpi_share        = 100 * share_pel

   

    collapse (mean) total_equity_gdp pel_gdp fdil_gdp fpi_share, by(year)
    sort year

    * Fig. 1A. Foreign equity investment and its components

    generate shade = year - 0.5 if _n > 1 & ///
        (pel_gdp < pel_gdp[_n-1] | fdil_gdp < fdil_gdp[_n-1])

    quietly summarize total_equity_gdp, meanonly
    local investment_ymax = ceil(r(max) / 50) * 50
    generate barmax = `investment_ymax'

    twoway ///
        (bar barmax shade if !missing(shade), ///
            barw(0.8) color(gs13%45) lcolor(none) base(0)) ///
        (line total_equity_gdp year, ///
            lcolor("`total_color'") lpattern(solid) lwidth(thick)) ///
        (line pel_gdp year, ///
            lcolor("`fpi_color'") lpattern(shortdash) lwidth(medthick)) ///
        (line fdil_gdp year, ///
            lcolor("`fdi_color'") lpattern(longdash_dot) lwidth(thick)), ///
        title("Foreign Equity Investment", size(medsmall)) ///
        subtitle("`sample_title', 2001 - 2020", size(small)) ///
        xtitle("Year", size(small)) ///
        ytitle("Foreign Equity Investment, % of GDP", size(small)) ///
        xlabel(2001(1)2020, labsize(vsmall) angle(45)) ///
        yscale(range(0 `investment_ymax')) ///
        ylabel(0(50)`investment_ymax', labsize(vsmall) nogrid) ///
        legend( ///
            order(2 "Total Foreign Equity Investment = {it:FPI} + {it:FDI}" ///
                  3 "{it:FPI}" ///
                  4 "{it:FDI}") ///
            cols(3) size(vsmall) region(lstyle(none))) ///
        graphregion(color(white)) ///
        plotregion(color(white)) ///
        name(Fig1A_`suffix', replace)

    foreach format in png pdf {
        graph export ///
            "$FIGURES/ForeignEquityLiabilities_GDP_`suffix'.`format'", ///
            as(`format') replace
    }

    * Fig. 1B. FPI share in total foreign equity investment

    generate shade_share = year - 0.5 if ///
        _n > 1 & fpi_share < fpi_share[_n-1]

    quietly summarize fpi_share, meanonly
    local share_ymin = floor(r(min) / 5) * 5
    local share_ymax = max(ceil(r(max) / 5) * 5, `share_ymin' + 5)
    generate barmax_share = `share_ymax'

    twoway ///
        (bar barmax_share shade_share if !missing(shade_share), ///
            barw(0.8) color(gs13%45) lcolor(none) base(`share_ymin')) ///
        (connected fpi_share year, ///
            lcolor(blue) ///
            lpattern(`share_pattern') ///
            lwidth(`share_width') ///
            msymbol(`share_marker') ///
            msize(`marker_size') ///
            mfcolor(blue) ///
            mlcolor(blue)), ///
        title("FPI Share in Total Foreign Equity Investment", ///
            size(medsmall)) ///
        subtitle("`sample_title', 2001 - 2020", size(small)) ///
        xtitle("Year", size(small)) ///
        ytitle("FPI Share, %", size(small)) ///
        xlabel(2001(1)2020, labsize(vsmall) angle(45)) ///
        yscale(range(`share_ymin' `share_ymax')) ///
        ylabel(`share_ymin'(5)`share_ymax', labsize(vsmall) nogrid) ///
        legend( ///
            order(2 "{it:FPIS} (`sample_title')") ///
            size(vsmall) region(lstyle(none))) ///
        graphregion(color(white)) ///
        plotregion(color(white)) ///
        name(Fig1B_`suffix', replace)

    foreach format in png pdf {
        graph export ///
            "$FIGURES/FPIShare_`suffix'.`format'", ///
            as(`format') replace
    }
}

********************************************************************************
* Figure 2. FPI share and global financial risk
********************************************************************************

set scheme s2color

local decrease_color "211 235 205"
local increase_color "244 204 204"



local risk_measures vixa vix
local risk_titles  `" "VIX (Annual Average)" "VIX (End-of-Year)" "'
local risk_suffixes Average EndOfYear
local risk_markers D S



local sample_titles  `" "Full Sample" "AEs" "EMDEs" "'
local sample_suffixes FullSample AEs EMDEs
local share_patterns solid longdash solid
local share_widths   thick thick thin
local share_markers  none none O
local share_msizes   vsmall vsmall small

forvalues r = 1/2 {

    local risk_measure : word `r' of `risk_measures'
    local risk_title   : word `r' of `risk_titles'
    local risk_suffix  : word `r' of `risk_suffixes'
    local risk_marker  : word `r' of `risk_markers'

    forvalues s = 1/3 {

        local sample_title  : word `s' of `sample_titles'
        local sample_suffix : word `s' of `sample_suffixes'
        local share_pattern : word `s' of `share_patterns'
        local share_width   : word `s' of `share_widths'
        local share_marker  : word `s' of `share_markers'
        local share_msize   : word `s' of `share_msizes'

        use "$DERIVED/analysis_data.dta", clear

        * Retain the full sample, AEs, or EMDEs

        keep if `s' == 1 | aded == `s' - 1

        * Calculate annual unweighted cross-country averages

        generate double fpi_share = 100 * share_pel

        collapse ///
            (mean) fpi_share ///
            (firstnm) risk_value = `risk_measure', ///
            by(year)

        sort year

        * Identify annual changes in the VIX

        generate double shade_x = ///
            year - 0.5 if _n > 1

        generate byte risk_direction = ///
            sign(risk_value - risk_value[_n-1]) if _n > 1

        * Determine the sample-specific FPIS axis

        quietly summarize fpi_share, meanonly

        local share_ymin = floor(r(min) / 5) * 5
        local share_ymax = ceil(r(max) / 5) * 5

        if `share_ymax' == `share_ymin' {
            local share_ymax = `share_ymin' + 5
        }

        generate double barmax_share = `share_ymax'

        * Drawing the figure

        twoway ///
            (bar barmax_share shade_x if risk_direction == -1, ///
                yaxis(1) barw(0.8) base(`share_ymin') ///
                color("`decrease_color'") lcolor(none)) ///
            (bar barmax_share shade_x if risk_direction == 1, ///
                yaxis(1) barw(0.8) base(`share_ymin') ///
                color("`increase_color'") lcolor(none)) ///
            (connected fpi_share year, ///
                yaxis(1) lcolor(blue) ///
                lpattern(`share_pattern') lwidth(`share_width') ///
                msymbol(`share_marker') msize(`share_msize') ///
                mfcolor(blue) mlcolor(blue)) ///
            (connected risk_value year, ///
                yaxis(2) lcolor(black) lpattern(solid) lwidth(thin) ///
                msymbol(`risk_marker') msize(small) ///
                mfcolor(black) mlcolor(black)), ///
            title("FPI Share and `risk_title'", size(medsmall)) ///
            subtitle("`sample_title', 2001–2020", size(small)) ///
            xtitle("Year", size(small)) ///
            ytitle("FPI Share, %", axis(1) size(small)) ///
            ytitle("`risk_title'", axis(2) size(small)) ///
            xlabel(2001(1)2020, labsize(vsmall) angle(45)) ///
            yscale(axis(1) range(`share_ymin' `share_ymax')) ///
            ylabel(`share_ymin'(5)`share_ymax', ///
                axis(1) labsize(vsmall) nogrid) ///
            yscale(axis(2) range(0 45)) ///
            ylabel(0(5)45, axis(2) labsize(vsmall) nogrid) ///
            legend( ///
                order( ///
                    3 "{it:FPIS} (`sample_title')" ///
                    4 "`risk_title'" ///
                    1 "Decrease in `risk_title'" ///
                    2 "Increase in `risk_title'" ///
                ) ///
                cols(2) size(vsmall) region(lstyle(none)) ///
            ) ///
            graphregion(color(white)) ///
            plotregion(color(white)) ///
            name(Figure3_`sample_suffix'_`risk_suffix', replace)

        * Exporting the individual figure

        graph export ///
            "$FIGURES/Figure3_FPIShare_`sample_suffix'_VIX_`risk_suffix'.png", ///
            as(png) width(2400) replace

        graph export ///
            "$FIGURES/Figure3_FPIShare_`sample_suffix'_VIX_`risk_suffix'.pdf", ///
            as(pdf) replace
    }
}

********************************************************************************
* Mean VIX before the GFC and during/subsequent period
********************************************************************************

use "$DERIVED/analysis_data.dta", clear
keep if inrange(year, 2001, 2020)

collapse (firstnm) vixa vix, by(year)

* GFC onset: 2007
generate byte period = year >= 2007
label define periodlbl ///
    0 "2001-2006" ///
    1 "2007-2020"
label values period periodlbl

* Calculate mean VIX by period
collapse (mean) vixa vix, by(period)

set scheme s2color

graph bar vixa vix, ///
    over(period, label(labsize(small))) ///
    bar(1, color("45 45 45")) ///
    bar(2, color("115 115 115")) ///
    blabel(bar, format(%4.2f) size(small)) ///
    title("Mean VIX Before and Since the Onset of the GFC", ///
        size(medsmall)) ///
    ytitle("Mean VIX", size(small)) ///
    legend( ///
        order(1 "VIX (Annual Average)" ///
              2 "VIX (End-of-Year)") ///
        cols(2) ///
        size(small) ///
        region(lstyle(none))) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    name(VIX_Before_Since_GFC, replace)

graph export ///
    "$FIGURES/Figure_B1_VIX_before_since_GFC.png", ///
    width(2400) replace

graph export ///
    "$FIGURES/Figure_B1_VIX_before_since_GFC.pdf", ///
    replace
	
********************************************************************************
* Mean FPIS in AEs and EMDEs before and since the GFC
********************************************************************************

use "$DERIVED/analysis_data.dta", clear

keep if inrange(year, 2001, 2020) & ///
    inlist(aded, 1, 2) & !missing(share_pel)

generate double fpis_pct = 100 * share_pel

* Calculate annual unweighted cross-country averages
collapse (mean) fpis_pct, by(year aded)

* GFC onset: 2007
generate byte period = year >= 2007

* Calculate period averages
collapse (mean) fpis_pct, by(period aded)


generate double bar_x = ///
    period + cond(aded == 1, -0.17, 0.17)

set scheme s2color

twoway ///
    /* AEs: dark-blue bars */ ///
    (bar fpis_pct bar_x if aded == 1, ///
        barw(0.28) ///
        base(0) ///
        color(navy%85) ///
        lcolor(navy)) ///
    /* EMDEs: light-blue bars */ ///
    (bar fpis_pct bar_x if aded == 2, ///
        barw(0.28) ///
        base(0) ///
        color("120 180 230") ///
        lcolor("120 180 230")) ///
    /* Value labels for AEs */ ///
    (scatter fpis_pct bar_x if aded == 1, ///
        msymbol(none) ///
        mlabel(fpis_pct) ///
        mlabformat(%4.1f) ///
        mlabposition(12) ///
        mlabsize(small) ///
        mlabcolor(navy)) ///
    /* Value labels for EMDEs */ ///
    (scatter fpis_pct bar_x if aded == 2, ///
        msymbol(none) ///
        mlabel(fpis_pct) ///
        mlabformat(%4.1f) ///
        mlabposition(12) ///
        mlabsize(small) ///
        mlabcolor("70 145 200")), ///
    title("Mean FPIS Before and Since the Onset of the GFC", ///
        size(medsmall)) ///
    subtitle("AEs and EMDEs", size(small)) ///
    xtitle("") ///
    ytitle("Mean FPIS, %", size(small)) ///
    xlabel( ///
        0 "2001-2006" ///
        1 "2007-2020", ///
        labsize(small)) ///
    xscale(range(-0.5 1.5)) ///
    yscale(range(0 36)) ///
    ylabel(0(5)35, labsize(small) nogrid) ///
    legend( ///
        order(1 "AEs" 2 "EMDEs") ///
        cols(2) ///
        size(small) ///
        region(lstyle(none))) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    name(FPIS_AE_EMDE_Before_Since_GFC, replace)

graph export ///
    "$FIGURES/Figure_B2_FPIS_AE_EMDE_before_since_GFC.png", ///
    width(2400) replace

graph export ///
    "$FIGURES/Figure_B2_FPIS_AE_EMDE_before_since_GFC.pdf", ///
    replace

********************************************************************************
* Figure 3. International reserves relative to alternative denominators
********************************************************************************

use "$DERIVED/analysis_data.dta", clear
set scheme s2color

keep if inrange(year, 2001, 2020)
keep if !missing(rtg, rtl, aded)

local reserve_color "0 90 65"

* Construct reserve measures for the full sample, AEs, and EMDEs

local denominators gdp liabilities
local sources      rtg rtl

forvalues d = 1/2 {

    local denominator : word `d' of `denominators'
    local source      : word `d' of `sources'

    generate reserves_`denominator'_full = 100 * `source'
    generate reserves_`denominator'_ae   = 100 * `source' if aded == 1
    generate reserves_`denominator'_emde = 100 * `source' if aded == 2
}

* Calculate annual unweighted cross-country averages

collapse (mean) reserves_gdp_* reserves_liabilities_*, by(year)
sort year

* Figure specifications

local titles `" "International Reserves Relative to GDP" "International Reserves Relative to Total External Liabilities" "'

local ytitles `" "International Reserves, % of GDP" "International Reserves, % of Total External Liabilities" "'

local graph_names Figure2A_Reserves_GDP Figure2B_Reserves_Liabilities

local file_names Figure2A_Reserves_GDP Figure2B_Reserves_TotalLiabilities

* Produce Figures 3A and 3B

forvalues d = 1/2 {

    local denominator : word `d' of `denominators'
    local title       : word `d' of `titles'
    local ytitle      : word `d' of `ytitles'
    local graph_name  : word `d' of `graph_names'
    local file_name   : word `d' of `file_names'

    egen axis_max = rowmax( ///
        reserves_`denominator'_full ///
        reserves_`denominator'_ae ///
        reserves_`denominator'_emde ///
    )

    quietly summarize axis_max, meanonly
    local ymax = ceil(r(max) / 5) * 5
    drop axis_max

    twoway ///
        (line reserves_`denominator'_full year, ///
            lcolor("`reserve_color'") ///
            lpattern(solid) ///
            lwidth(thick)) ///
        (line reserves_`denominator'_ae year, ///
            lcolor("`reserve_color'") ///
            lpattern(dash) ///
            lwidth(thin)) ///
        (line reserves_`denominator'_emde year, ///
            lcolor("`reserve_color'") ///
            lpattern(dash) ///
            lwidth(vthick)), ///
        title("`title'", size(medsmall)) ///
        subtitle("2001 - 2020", size(small)) ///
        xtitle("Year", size(small)) ///
        ytitle("`ytitle'", size(small)) ///
        xlabel(2001(1)2020, ///
            labsize(vsmall) ///
            angle(45)) ///
        yscale(range(0 `ymax')) ///
        ylabel(0(5)`ymax', ///
            labsize(vsmall) ///
            nogrid) ///
        legend( ///
            order(1 "Full sample" 2 "AEs" 3 "EMDEs") ///
            cols(3) ///
            size(vsmall) ///
            region(lstyle(none)) ///
        ) ///
        graphregion(color(white)) ///
        plotregion(color(white)) ///
        name(`graph_name', replace)

    foreach format in png pdf {

        graph export ///
            "$FIGURES/`file_name'.`format'", ///
            as(`format') ///
            replace
    }
}


********************************************************************************
* Figure 4. Growth rates of international reserves and total external liabilities
********************************************************************************

set scheme s2color

local reserves_color    "0 90 65"
local liabilities_color "112 173 219"

local sample_subtitles `" "AEs, 2001 - 2020" "EMDEs, 2001 - 2020" "'
local suffixes         Advanced EMDE
local graph_names      GRL_AEs GRL_EMDEs

forvalues s = 1/2 {

    local sample_subtitle : word `s' of `sample_subtitles'
    local suffix          : word `s' of `suffixes'
    local graph_name      : word `s' of `graph_names'

    use "$DERIVED/analysis_data.dta", clear

    keep if inrange(year, 2001, 2020) & aded == `s'

    * Calculate country-level annual growth rates

    sort cn year
    xtset cn year

    generate reserves_growth = ///
        reserves / L.reserves - 1 ///
        if reserves > 0 & L.reserves > 0

    generate liabilities_growth = ///
        tl / L.tl - 1 ///
        if tl > 0 & L.tl > 0

    * Retain a common sample and calculate annual averages

    keep if !missing(reserves_growth, liabilities_growth)

    collapse ///
        (mean) reserves_growth liabilities_growth ///
        (count) number_countries = reserves_growth, ///
        by(year)

    sort year

    * Display the underlying statistics

    format reserves_growth liabilities_growth %9.3f

    list ///
        year ///
        number_countries ///
        reserves_growth ///
        liabilities_growth, ///
        noobs


    egen minimum_growth = rowmin( ///
        reserves_growth ///
        liabilities_growth ///
    )

    egen maximum_growth = rowmax( ///
        reserves_growth ///
        liabilities_growth ///
    )

    quietly summarize minimum_growth, meanonly
    local growth_ymin = min(floor(r(min) * 10) / 10, 0)

    quietly summarize maximum_growth, meanonly
    local growth_ymax = max(ceil(r(max) * 10) / 10, 0)

    if `growth_ymax' == `growth_ymin' {
        local growth_ymax = `growth_ymin' + 0.1
    }

    drop minimum_growth maximum_growth

    * Plotting the growth rates

    twoway ///
        (line reserves_growth year, ///
            sort ///
            lcolor("`reserves_color'") ///
            lpattern(solid) ///
            lwidth(thick)) ///
        (line liabilities_growth year, ///
            sort ///
            lcolor("`liabilities_color'") ///
            lpattern(solid) ///
            lwidth(thick)), ///
        title( ///
            "Growth Rates: Reserves vs. Total External Liabilities", ///
            size(medsmall) ///
        ) ///
        subtitle("`sample_subtitle'", size(small)) ///
        xtitle("Year", size(small)) ///
        ytitle("Annual Growth Rate", size(small)) ///
        xscale(range(2000.5 2020.5)) ///
        xlabel(2001(1)2020, ///
            labsize(vsmall) ///
            angle(45)) ///
        yscale(range(`growth_ymin' `growth_ymax')) ///
        ylabel( ///
            `growth_ymin'(0.1)`growth_ymax', ///
            labsize(small) ///
            format(%3.1f) ///
            nogrid ///
        ) ///
        yline(0, ///
            lcolor(black) ///
            lpattern(dash) ///
            lwidth(medthick)) ///
        legend( ///
            order( ///
                1 "Reserves Growth" ///
                2 "Total External Liabilities Growth" ///
            ) ///
            cols(2) ///
            size(small) ///
            region(lstyle(none)) ///
        ) ///
        graphregion(color(white)) ///
        plotregion(color(white)) ///
        name(`graph_name', replace)

    * Exporting figures

    graph export ///
        "$FIGURES/Growth_Reserves_Liabilities_`suffix'.png", ///
        as(png) ///
        width(2400) ///
        replace

    graph export ///
        "$FIGURES/Growth_Reserves_Liabilities_`suffix'.pdf", ///
        as(pdf) ///
        replace
}

********************************************************************************
* Figure 5. FPI share and international reserves
********************************************************************************

set scheme s2color

local positive_color "112 173 71"
local inverse_color  "0 0 0"
local fitted_color   "128 0 0"

local sample_titles  `" "Full Sample" "AEs" "EMDEs" "'
local sample_suffixes Full AEs EMDEs

* Constructing the common country-year sample

use "$DERIVED/analysis_data.dta", clear

keep if inrange(year, 2001, 2020) & inlist(aded, 1, 2)
drop if countrycode == "ISR"

sort cn year
xtset cn year

generate double fpi_share_pct = ///
    100 * share_pel

generate double reserve_coverage_lag_pct = ///
    100 * L.rtl

keep if !missing( ///
    cn, ///
    aded, ///
    fpi_share_pct, ///
    reserve_coverage_lag_pct ///
)

bysort cn: generate number_usable_years = _N
keep if number_usable_years >= 2

sort cn year

tempfile reserve_fpi_common_sample
save `reserve_fpi_common_sample', replace

* Constructing the cross-country dataset

collapse ///
    (mean) ///
        mean_fpi_share_pct = fpi_share_pct ///
        mean_reserve_coverage_pct = reserve_coverage_lag_pct ///
    (count) ///
        number_years = fpi_share_pct, ///
    by(cn countrycode aded)

* Identify visually distinctive countries

egen double maximum_emde_fpi_share = ///
    max(mean_fpi_share_pct) if aded == 2

generate byte highest_fpi_emde = ///
    aded == 2 & ///
    mean_fpi_share_pct == maximum_emde_fpi_share

gsort aded -mean_reserve_coverage_pct

by aded: generate int reserve_coverage_rank = _n

generate byte highest_coverage_aes = ///
    aded == 1 & ///
    reserve_coverage_rank <= 3

generate byte high_coverage_emde = ///
    aded == 2 & ///
    mean_reserve_coverage_pct >= 80

generate byte identified_country = ///
    high_coverage_emde | ///
    highest_fpi_emde | ///
    highest_coverage_aes

generate str12 plot_label = ""

replace plot_label = countrycode ///
    if identified_country

generate str60 identification_reason = ""

replace identification_reason = ///
    "EMDE: reserve coverage at least 80 percent" ///
    if high_coverage_emde

replace identification_reason = ///
    "EMDE: highest average FPI share" ///
    if highest_fpi_emde

replace identification_reason = ///
    "AE: among three highest reserve-coverage ratios" ///
    if highest_coverage_aes

sort aded mean_reserve_coverage_pct

* Display the identified countries

list ///
    countrycode ///
    aded ///
    number_years ///
    mean_fpi_share_pct ///
    mean_reserve_coverage_pct ///
    identification_reason ///
    if identified_country, ///
    sepby(aded) ///
    noobs ///
    abbreviate(24)

tempfile reserve_fpi_cross_country
save `reserve_fpi_cross_country', replace

* Produce figures

local panel_graphs B4_All B5_Excl

local panel_files ///
    FigureB4_Reserves_FPIShare_CrossCountry ///
    FigureB5_Reserves_FPIShare_ExcludingIdentified

forvalues p = 1/2 {

    local graph_prefix : word `p' of `panel_graphs'
    local file_prefix  : word `p' of `panel_files'

    use `reserve_fpi_cross_country', clear

    local label_options

    if `p' == 1 {
        local label_options ///
            "mlabel(plot_label) mlabcolor(gs6) mlabsize(vsmall) mlabposition(3) mlabgap(vsmall)"
    }

    if `p' == 2 {
        drop if identified_country
    }

    forvalues s = 1/3 {

        local sample_title  : word `s' of `sample_titles'
        local sample_suffix : word `s' of `sample_suffixes'

        preserve

        keep if `s' == 1 | aded == `s' - 1

        twoway ///
            (scatter ///
                mean_fpi_share_pct ///
                mean_reserve_coverage_pct, ///
                msymbol(O) ///
                msize(small) ///
                mcolor(navy) ///
                mlcolor(navy) ///
                `label_options') ///
            (lfit ///
                mean_fpi_share_pct ///
                mean_reserve_coverage_pct, ///
                lcolor("`fitted_color'") ///
                lpattern(solid) ///
                lwidth(medthick)), ///
            title( ///
                "FPI Share and International Reserves", ///
                size(medsmall) ///
            ) ///
            subtitle( ///
                "`sample_title', 2001 - 2020", ///
                size(small) ///
            ) ///
            xtitle("{it:RES}, %", size(small)) ///
            ytitle("FPI Share, %", size(small)) ///
            xlabel(, labsize(vsmall)) ///
            ylabel(, labsize(vsmall) nogrid) ///
            legend(off) ///
            graphregion(color(white)) ///
            plotregion(color(white)) ///
            name(`graph_prefix'_`sample_suffix', replace)

        graph export ///
            "$FIGURES/`file_prefix'_`sample_suffix'.png", ///
            as(png) ///
            width(2400) ///
            replace

        graph export ///
            "$FIGURES/`file_prefix'_`sample_suffix'.pdf", ///
            as(pdf) ///
            replace

        restore
    }
}

* Construct within-country deviations

use `reserve_fpi_common_sample', clear

bysort cn: egen double mean_fpi_share_pct = ///
    mean(fpi_share_pct)

bysort cn: egen double mean_reserve_coverage_pct = ///
    mean(reserve_coverage_lag_pct)

generate double fpi_share_within = ///
    fpi_share_pct - mean_fpi_share_pct

generate double reserve_coverage_within = ///
    reserve_coverage_lag_pct - mean_reserve_coverage_pct



quietly summarize fpi_share_within

display ///
    "Mean of within-country FPI share = " ///
    %9.6f r(mean)

quietly summarize reserve_coverage_within

display ///
    "Mean of within-country reserve coverage = " ///
    %9.6f r(mean)

* Produce the figures

forvalues s = 1/3 {

    local sample_title  : word `s' of `sample_titles'
    local sample_suffix : word `s' of `sample_suffixes'

    preserve

    keep if `s' == 1 | aded == `s' - 1

    * Constructing 20 equal-frequency bins

    xtile reserve_bin = ///
        reserve_coverage_within, ///
        nq(20)

    collapse ///
        (mean) ///
            bin_fpi_share = fpi_share_within ///
            bin_reserve_coverage = reserve_coverage_within ///
        (count) ///
            bin_observations = fpi_share_within, ///
        by(reserve_bin)

    sort bin_reserve_coverage

    generate byte same_sign_bin = ///
        bin_fpi_share * bin_reserve_coverage > 0

    replace same_sign_bin = 0 ///
        if missing(same_sign_bin)

    twoway ///
        (scatter ///
            bin_fpi_share ///
            bin_reserve_coverage ///
            if same_sign_bin == 1, ///
            msymbol(O) ///
            msize(small) ///
            mcolor("`positive_color'") ///
            mlcolor("`positive_color'")) ///
        (scatter ///
            bin_fpi_share ///
            bin_reserve_coverage ///
            if same_sign_bin == 0, ///
            msymbol(O) ///
            msize(small) ///
            mcolor("`inverse_color'") ///
            mlcolor("`inverse_color'")), ///
        title( ///
            "FPI Share and International Reserves", ///
            size(medsmall) ///
        ) ///
        subtitle( ///
            "`sample_title', 2001 - 2020", ///
            size(small) ///
        ) ///
        xtitle( ///
            "{it:RES}, Percentage Points (Demeaned)", ///
            size(small) ///
        ) ///
        ytitle( ///
            "{it:FPIS}, Percentage Points (Demeaned)", ///
            size(small) ///
        ) ///
        xlabel(, labsize(vsmall)) ///
        ylabel(, labsize(vsmall) nogrid) ///
        xline(0, ///
            lcolor(gs10) ///
            lpattern(dash) ///
            lwidth(thin)) ///
        yline(0, ///
            lcolor(gs10) ///
            lpattern(dash) ///
            lwidth(thin)) ///
        legend(off) ///
        graphregion(color(white)) ///
        plotregion(color(white)) ///
        name(Fig4_Within_`sample_suffix', replace)

    graph export ///
        "$FIGURES/Figure4_Reserves_FPIShare_Within_`sample_suffix'.png", ///
        as(png) ///
        width(2400) ///
        replace

    graph export ///
        "$FIGURES/Figure4_Reserves_FPIShare_Within_`sample_suffix'.pdf", ///
        as(pdf) ///
        replace

    restore
}

********************************************************************************
* Appendix Table B.2. International reserves by exchange-rate regime
********************************************************************************

use "$DERIVED/analysis_data.dta", clear
preserve

keep if inrange(year, 2001, 2020) & !missing(rtl, exrr)

* Labeling the six exchange-rate regimes

label define exrrlbl ///
    1 "De Facto Peg" ///
    2 "De Facto Crawling Peg" ///
    3 "Managed Floating" ///
    4 "Freely Floating" ///
    5 "Freely Falling" ///
    6 "Dual Market", replace

label values exrr exrrlbl

* Calculating descriptive statistics for RES by regime

collapse ///
    (count) Observations=rtl ///
    (mean)  Mean=rtl ///
    (sd)    StdDev=rtl ///
    (min)   Minimum=rtl ///
    (max)   Maximum=rtl, ///
    by(exrr)

* Grouping the six regimes into the three broad categories

generate byte regime_group = ///
    cond(inlist(exrr, 1, 2), 1, ///
    cond(exrr == 3, 2, 3))

label define regime_group_lbl ///
    1 "Pegged regimes" ///
    2 "Managed regimes" ///
    3 "Floating regimes", replace

label values regime_group regime_group_lbl



format Observations %9.0fc
format Mean StdDev Maximum %9.3f
format Minimum %9.5g

sort regime_group exrr

* Display the table

by regime_group: list ///
    exrr ///
    Observations ///
    Mean ///
    StdDev ///
    Minimum ///
    Maximum, ///
    noobs abbreviate(20)

restore




********************************************************************************
** RESULTS
********************************************************************************

********************************************************************************
* Table 3. SPLRs with FPIS as the dependent variable: full sample
********************************************************************************

use "$DERIVED/analysis_data.dta", clear
estimates clear

* The three-category exchange-rate regime

capture confirm variable exrr3
if _rc {
    recode exrr ///
        (1 2 = 1) ///
        (3   = 2) ///
        (4/6 = 3) ///
        (else = .), ///
        generate(exrr3)
}

label define exrr3lbl ///
    1 "Pegged" ///
    2 "Managed" ///
    3 "Floating", replace

label values exrr3 exrr3lbl


xtset cn year

generate double L1_gdppk_thousands = ///
    L1_gdp_per_capita_cus / 1000

label variable L1_gdppk_thousands ///
    "GDP per capita, thousands of current U.S. dollars (t-1)"

* Reproducible bootstrap inference

set seed 123456
local bootstrap "vce(bootstrap, reps(500))"

* Common regressors

local core ///
    "L1_rtl L1_vixa L1_us_3m_rate_a L1_gdppk_thousands L1_trade_open"

local domestic ///
    "L1_rtl L1_gdppk_thousands L1_trade_open"

* Additional controls across specifications

local additional1 ""
local additional2 "L1_gdppk_growth"
local additional3 "`additional2' L1_total_natural_resources_rent"
local additional4 "`additional3' L1_control_of_corruption"
local additional5 "`additional3' L1_government_effectiveness"
local additional6 "`additional3' L1_rule_of_law"

********************************************************************************
* Columns 1–6: Country fixed effects
********************************************************************************

forvalues column = 1/6 {

    areg share_pel ///
        `core' ///
        `additional`column'' ///
        i.exrr3, ///
        absorb(cn) ///
        `bootstrap'

    estimates store Table3_`column'
}

********************************************************************************
* Column 7: Column 6 plus year fixed effects
********************************************************************************

areg share_pel ///
    `core' ///
    `additional6' ///
    i.exrr3 ///
    i.year, ///
    absorb(cn) ///
    `bootstrap'

estimates store Table3_7

********************************************************************************
* Column 8: Year fixed effects, excluding VIX and U.S. Treasury bill rate
********************************************************************************

areg share_pel ///
    `domestic' ///
    `additional6' ///
    i.exrr3 ///
    i.year, ///
    absorb(cn) ///
    `bootstrap'

estimates store Table3_8

********************************************************************************
* Display Table 3
********************************************************************************

estimates table ///
    Table3_1 Table3_2 Table3_3 Table3_4 ///
    Table3_5 Table3_6 Table3_7 Table3_8, ///
    b(%9.4f) ///
    se(%9.4f) ///
    stats(N r2_a)

********************************************************************************
* Robustness: End-of-year VIX
********************************************************************************

local core_eoy ///
    "L1_rtl L1_vix L1_us_3m_rate_a L1_gdppk_thousands L1_trade_open"

* Column 6 specification without year fixed effects

areg share_pel ///
    `core_eoy' ///
    `additional6' ///
    i.exrr3, ///
    absorb(cn) ///
    `bootstrap'

estimates store Table3_VIX_EOY_6

* Column 7 specification with year fixed effects

areg share_pel ///
    `core_eoy' ///
    `additional6' ///
    i.exrr3 ///
    i.year, ///
    absorb(cn) ///
    `bootstrap'

estimates store Table3_VIX_EOY_7

* The robustness specifications

estimates table ///
    Table3_VIX_EOY_6 ///
    Table3_VIX_EOY_7, ///
    b(%9.4f) ///
    se(%9.4f) ///
    stats(N r2_a)
********************************************************************************
* Table B.3. Log FPI and log FDI liabilities: Country FE
********************************************************************************

use "$DERIVED/analysis_data.dta", clear

* Three category exchange rate regime
capture confirm variable exrr3
if _rc {
    generate byte exrr3 = cond(inlist(exrr, 1, 2), 1, ///
                          cond(exrr == 3, 2, 3)) if !missing(exrr)
}

label define exrr3lbl ///
    1 "Pegged" ///
    2 "Managed" ///
    3 "Floating", replace
label values exrr3 exrr3lbl

* GDP per capita in thousands of current U.S. dollars
capture drop L1_gdppk_thousands
generate double L1_gdppk_thousands = ///
    L1_gdp_per_capita_cus / 1000

sort cn year
xtset cn year
set seed 123456

local boot "vce(bootstrap, reps(500))"

* Controls included in both FPI and FDI regressions
local controls ///
    L1_rtl ///
    L1_vixa ///
    L1_us_3m_rate_a ///
    L1_gdppk_thousands ///
    L1_gdppk_growth ///
    L1_rule_of_law

* Additional FDI-specific controls
local extra_lpel ""
local extra_lfdil ///
    "L1_trade_open L1_total_natural_resources_rent"

* Sample restrictions
local condition_Full ""
local condition_EMDE "if aded == 2"
local condition_AE   "if aded == 1"

* Estimate all six country fixed-effects regressions
local models

foreach sample in Full EMDE AE {
    foreach dependent in lpel lfdil {

        local model B3_`sample'_CFE_`dependent'

        display as text "Estimating `model'"

        areg `dependent' ///
            `controls' ///
            `extra_`dependent'' ///
            i.exrr3 ///
            `condition_`sample'', ///
            absorb(cn) ///
            `boot'

        estimates store `model'
        local models `models' `model'
    }
}

* Display all 
estimates table `models', ///
    b(%9.4f) ///
    se(%9.4f) ///
    stats(N r2_a)
	
	
********************************************************************************
* Table 3. SPLRs for the full sample, AEs, and EMDEs
********************************************************************************

use "$DERIVED/analysis_data.dta", clear

*  Exchange-rate regime
capture confirm variable exrr3
if _rc {
    generate byte exrr3 = cond(inlist(exrr, 1, 2), 1, ///
                          cond(exrr == 3, 2, 3)) if !missing(exrr)
}

label define exrr3lbl ///
    1 "Pegged" ///
    2 "Managed" ///
    3 "Floating", replace
label values exrr3 exrr3lbl

* GDP per capita in thousands of current U.S. dollars
capture drop L1_gdppk_thousands
generate double L1_gdppk_thousands = ///
    L1_gdp_per_capita_cus / 1000

sort cn year
xtset cn year

local boot "vce(bootstrap, reps(500))"

* Benchmark controls using the annual average VIX
local controls ///
    L1_rtl ///
    L1_vixa ///
    L1_us_3m_rate_a ///
    L1_gdppk_thousands ///
    L1_trade_open ///
    L1_gdppk_growth ///
    L1_total_natural_resources_rent ///
    L1_rule_of_law ///
    i.exrr3

* Sample and fixed effect definitions
local sample_AE   "if aded == 1"
local sample_EMDE "if aded == 2"

local year_CFE  ""
local year_TWFE "i.year"

********************************************************************************
* Full sample columns: restore Table 2, columns (6) and (7)
********************************************************************************

capture estimates restore Table3_6
if _rc {
    display as error ///
        "Table3_6 not found. Run the Table 2 section first."
    exit 111
}
estimates store T3_Full_CFE

capture estimates restore Table3_7
if _rc {
    display as error ///
        "Table3_7 not found. Run the Table 2 section first."
    exit 111
}
estimates store T3_Full_TWFE

********************************************************************************
* AE and EMDE specifications
********************************************************************************

set seed 123456

foreach fe in CFE TWFE {
    foreach sample in AE EMDE {

        display as text ///
            "Estimating Table 3: `sample', `fe'"

        areg share_pel ///
            `controls' ///
            `year_`fe'' ///
            `sample_`sample'', ///
            absorb(cn) ///
            `boot'

        estimates store T3_`sample'_`fe'
    }
}

* Display the six main specifications
estimates table ///
    T3_Full_CFE ///
    T3_AE_CFE ///
    T3_EMDE_CFE ///
    T3_Full_TWFE ///
    T3_AE_TWFE ///
    T3_EMDE_TWFE, ///
    b(%9.5f) ///
    se(%9.5f) ///
    stats(N r2_a)

********************************************************************************
* Robustness: End-of-year VIX for AEs and EMDEs
********************************************************************************

local controls_eoy ///
    L1_rtl ///
    L1_vix ///
    L1_us_3m_rate_a ///
    L1_gdppk_thousands ///
    L1_trade_open ///
    L1_gdppk_growth ///
    L1_total_natural_resources_rent ///
    L1_rule_of_law ///
    i.exrr3

set seed 123456

foreach fe in CFE TWFE {
    foreach sample in AE EMDE {

        display as text ///
            "End-of-year VIX robustness: `sample', `fe'"

        areg share_pel ///
            `controls_eoy' ///
            `year_`fe'' ///
            `sample_`sample'', ///
            absorb(cn) ///
            `boot'

        estimates store T3_EOY_`sample'_`fe'
    }
}

* Display the four end-of-year VIX robustness specifications
estimates table ///
    T3_EOY_AE_CFE ///
    T3_EOY_EMDE_CFE ///
    T3_EOY_AE_TWFE ///
    T3_EOY_EMDE_TWFE, ///
    b(%9.5f) ///
    se(%9.5f) ///
    stats(N r2_a)

	 
********************************************************************************
* Table 4 and Table B.6: Static panel nonlinear regressions
* Table 4:  Annual-average VIX
* Table B.6: End-of-year VIX
********************************************************************************

use "data/derived/analysis_data.dta", clear
sort cn year
xtset cn year

* Exchange-rate regime
recode exrr (1 2 = 1) (3 = 2) (4/6 = 3) (else = .), generate(exrr3)
label define exrr3lbl 1 "Pegged" 2 "Managed" 3 "Floating", replace
label values exrr3 exrr3lbl

* Balanced sample indicator
bysort cn: egen count_gdp_per_capita = count(gdp_per_capita_cus)

* GDP per capita in thousands of current U.S. dollars
generate double L1_gdppk_thousands = L1_gdp_per_capita_cus / 1000

* Common controls
local controls ///
    L1_us_3m_rate_a ///
    L1_gdppk_thousands ///
    L1_gdppk_growth ///
    L1_trade_open ///
    L1_total_natural_resources_rent ///
    L1_rule_of_law ///
    i.exrr3

* Table 4: annual-average VIX
* Table B.6: end-of-year VIX
foreach riskvar in vixa vix {

    if "`riskvar'" == "vixa" local prefix Table4
    else                     local prefix TableB6

    set seed 123456
    local column = 0

    foreach group in 0 2 1 {

        local restriction "if count_gdp_per_capita == 20"
        if `group' != 0 local restriction ///
            "if count_gdp_per_capita == 20 & aded == `group'"

        foreach yearfe in no yes {

            local ++column

            local fe ""
            if "`yearfe'" == "yes" local fe "i.year"

            areg share_pel ///
                `controls' ///
                `fe' ///
                c.`riskvar'##c.L1_rtl ///
                `restriction', ///
                absorb(cn) ///
                vce(bootstrap, reps(500))

            estimates store `prefix'_`column'
        }
    }

    estimates table ///
        `prefix'_1 `prefix'_2 `prefix'_3 ///
        `prefix'_4 `prefix'_5 `prefix'_6, ///
        b(%9.5f) se(%9.5f) stats(N r2_a)
}

********************************************************************************
* Ramsey RESET tests for Table 4 interaction specifications
********************************************************************************

* Common explanatory variables
local reset_controls ///
    L1_us_3m_rate_a ///
    L1_gdppk_thousands ///
    L1_gdppk_growth ///
    L1_trade_open ///
    L1_total_natural_resources_rent ///
    L1_rule_of_law ///
    i.exrr3 ///
    c.vixa##c.L1_rtl ///
    i.cn

* Sample restrictions
local reset_if_Full     "if count_gdp_per_capita == 20"
local reset_if_EMDE     "if count_gdp_per_capita == 20 & aded == 2"
local reset_if_Advanced "if count_gdp_per_capita == 20 & aded == 1"

* RESET tests
foreach sample in Full EMDE Advanced {

    foreach yearfe in no yes {

        local fe ""
        if "`yearfe'" == "yes" local fe "i.year"

        display as text "Ramsey RESET: `sample', Year FE = `yearfe'"

        quietly regress share_pel ///
            `reset_controls' ///
            `fe' ///
            `reset_if_`sample'', ///
            vce(robust)

        estat ovtest
    }
}

********************************************************************************
* Tables 5–7: Preliminary analysis and static panel threshold regressions
********************************************************************************

********************************************************************************
* Tables 5–6: Preliminary analysis
********************************************************************************

use "$DERIVED/analysis_data.dta", clear
sort cn year
xtset cn year

* Balanced sample indicator used in the original PTR analysis
bysort cn: egen count_gdppc_ptr = count(gdp_per_capita)


* Table 5. Panel AR(1) regression for reserves

xtreg rtl L1_rtl if count_gdppc_ptr == 20, fe
estimates store Table5_AR1

* Country specific AR(1) coefficients
preserve
keep if count_gdppc_ptr == 20

statsby ar1 = _b[L1_rtl] N = e(N), by(cn) clear: ///
    regress rtl L1_rtl

generate byte above06 = ar1 > 0.6 if !missing(ar1)

summarize above06, meanonly
display "Countries with AR(1) coefficient above 0.6: " ///
    %6.2f (100*r(mean)) "%"

summarize ar1, detail
display "Mean country-specific AR(1) coefficient: " %6.4f r(mean)
display "Median country-specific AR(1) coefficient: " %6.4f r(p50)

list cn ar1 N if ar1 <= 0.6, noobs sep(0)

restore


* Table 6. Fixed effects regressions of reserves on average VIX

xtreg rtl vixa ///
    if count_gdppc_ptr == 20, ///
    fe vce(cluster cn)
estimates store Table6_1

xtreg rtl vixa i.year ///
    if count_gdppc_ptr == 20, ///
    fe vce(cluster cn)
estimates store Table6_2


* Display Tables 5 and 6

estimates table Table5_AR1, ///
    b(%9.4f) se(%9.4f) stats(N r2_w rmse)

estimates table Table6_1 Table6_2, ///
    b(%9.4f) se(%9.4f) stats(N r2_w rmse)


********************************************************************************
* Table 7: Static panel threshold regressions
********************************************************************************

use "$DERIVED/analysis_data.dta", clear

* Excluding countries without sufficiently balanced trade-openness data
drop if inlist(countrycode, ///
    "AGO", "BDI", "ETH", "JAM", "LAO", ///
    "MWI", "NGA", "LKA", "TTO")

sort cn year
xtset cn year

generate double L1_gdppk_thousands = L1_gdp_per_capita_cus / 1000

* Common controls
local controls ///
    L1_us_3m_rate_a ///
    L1_gdppk_thousands ///
    L1_gdppk_growth ///
    L1_trade_open ///
    L1_total_natural_resources_rent ///
    L1_rule_of_law ///
    L1_exrr

* Threshold estimation settings
set seed 123456
local ptr_options thnum(1) grid(600) bs(500) trim(0.10)
local LRcrit95 = 7.35

* Sample definitions
local keep_Full      ""
local keep_EMDE      "keep if aded == 2"
local keep_Advanced  "keep if aded == 1"

local title_Full      "Full Sample"
local title_EMDE      "EMDEs"
local title_Advanced  "AEs"

local suffix_Full      "FULL"
local suffix_EMDE      "EMDE"
local suffix_Advanced  "ADV"


* Estimate Table 7

local column = 0

foreach sample in Full EMDE Advanced {

    local ++column

    preserve

    `keep_`sample''

    sort cn year
    xtset cn year

    display "Estimating Table 7, column `column': `title_`sample''"

    xthreg share_pel ///
        `controls', ///
        rx(vixa) ///
        qx(L1_rtl) ///
        `ptr_options'

    estimates store Table7_`column'

    * Threshold estimate
    matrix list e(Thrss)
    local threshold = e(Thrss)[1,1]

    display "Estimated threshold: " %9.4f `threshold'

    * Number of observations in each regime
    quietly count if e(sample) & L1_rtl <= `threshold'
    local below = r(N)

    quietly count if e(sample) & L1_rtl > `threshold'
    local above = r(N)

    display "Observations below threshold: " `below'
    display "Observations above threshold: " `above'
    display "Total estimation observations: " `below' + `above'

    * Threshold LR confidence interval plot
    local graph "LR_RTL_`suffix_`sample''"

    _matplot e(LR), ///
        connect(direct) ///
        recast(line) ///
        lcolor(black) ///
        lwidth(medthick) ///
        yline(`LRcrit95', lpattern(dash) lcolor(black)) ///
        ytitle("LR Statistics") ///
        xtitle("Threshold Parameter") ///
        title("International Reserves Buffer Effect - `title_`sample''") ///
        graphregion(color(white)) ///
        plotregion(color(white)) ///
        name(`graph', replace)

    graph export "$FIGURES/`graph'.pdf", as(pdf) replace
    graph export "$FIGURES/`graph'.png", as(png) width(2400) replace

    restore
}


* Display Table 7

estimates table ///
    Table7_1 Table7_2 Table7_3, ///
    b(%9.6f) se(%9.6f) stats(N)

********************************************************************************
* Table 8: Dynamic panel threshold regressions
********************************************************************************

use "$DERIVED/analysis_data.dta", clear

* Exclude countries with insufficient trade openness observations
drop if inlist(countrycode, ///
    "AGO", "BDI", "ETH", "JAM", "LAO", ///
    "MWI", "NGA", "LKA", "TTO")

sort cn year
xtset cn year


* Required lags and scaling
generate L1_gdppk_thousands = ///
    L1_gdp_per_capita_cus / 1000


* Variables required for a complete DPTR observation
local required ///
    share_pel ///
    vixa ///
    L1_share_pel ///
    L2_rtl ///
    L1_us_3m_rate_a ///
    L1_gdppk_thousands ///
    L1_gdppk_growth ///
    L1_trade_open ///
    L1_total_natural_resources_rent ///
    L1_rule_of_law ///
    L1_exrr

local nrequired : word count `required'


* Common controls
local controls ///
    L1_share_pel ///
    L1_us_3m_rate_a ///
    L1_gdppk_thousands ///
    L1_gdppk_growth ///
    L1_trade_open ///
    L1_total_natural_resources_rent ///
    L1_rule_of_law ///
    L1_exrr


* Sample definitions
local keep_Full      ""
local keep_EMDE      "keep if aded == 2"
local keep_Advanced  "keep if aded == 1"

local title_Full      "Full Sample"
local title_EMDE      "EMDEs"
local title_Advanced  "AEs"

local stub_Full      "df"
local stub_EMDE      "de"
local stub_Advanced  "da"

local suffix_Full      "FULL"
local suffix_EMDE      "EMDE"
local suffix_Advanced  "ADV"


* Reproducibility
set seed 123456


********************************************************************************
* Estimate Table 8
********************************************************************************

local column = 0

foreach sample in Full EMDE Advanced {

    local ++column

    preserve

    `keep_`sample''

    sort cn year
    xtset cn year



    egen nonmissing = rownonmiss(`required')

    generate byte complete = ///
        nonmissing == `nrequired'

    drop nonmissing




    if "`sample'" == "Full" {

        local threshold "L2_rtl"

        bysort cn: egen ncomplete = ///
            total(complete)

        keep if ncomplete == 18
    }

    else {

        * Percentiles calculated from complete observations only
        keep if complete == 1

        centile L2_rtl, ///
            centile(15 85)

        local p15 = r(c_1)
        local p85 = r(c_2)

        generate L2_rtl_w = ///
            min(max(L2_rtl, `p15'), `p85')

        local threshold "L2_rtl_w"

        bysort cn: generate ncomplete = ///
            _N

        keep if ncomplete == 18
    }


* DPTR

    display " "
    display "=============================================================="
    display "Estimating Table 8, column `column': `title_`sample''"
    display "Threshold variable: `threshold'"
    display "=============================================================="

    xtendothresdpd ///
        share_pel ///
        `controls', ///
        thresv(`threshold') ///
        pivar(vixa) ///
        sig(0.05) ///
        stub(`stub_`sample'') ///
        fodeviation ///
        lagsret(1) ///
        dgmmiv(L1_share_pel, lagrange(2 4))

    estimates store Table8_`column'


    * Observations below and above estimated threshold
 

    local stub "`stub_`sample''"

    * Estimated threshold = gamma where LR statistic reaches its minimum
    quietly summarize `stub'_lrofgamma ///
        if !missing(`stub'_lrofgamma), ///
        meanonly

    local lrmin = r(min)

    quietly summarize `stub'_gamma ///
        if abs(`stub'_lrofgamma - `lrmin') < 1e-10, ///
        meanonly

    local gammahat = r(min)


    * Count observations in each estimated reserve regime
    quietly count if ///
        e(sample) & ///
        `threshold' <= `gammahat'

    local below = r(N)


    quietly count if ///
        e(sample) & ///
        `threshold' > `gammahat'

    local above = r(N)


    * Save counts by sample
    local below_`sample' = `below'
    local above_`sample' = `above'
    local gamma_`sample' = `gammahat'


    * Display regime counts
    display " "
    display "Estimated threshold: " ///
        %9.7f `gammahat'

    display "Observations below threshold: " ///
        `below'

    display "Observations above threshold: " ///
        `above'

    display "Total observations across regimes: " ///
        `below' + `above'

    display "Estimation observations e(N): " ///
        e(N)


    * CheckING that regime counts sum to estimation N
    if (`below' + `above' != e(N)) {

        display as error ///
            "WARNING: Below + Above does not equal e(N)."
    }


    * Save LR critical value 


    local critical = e(confalpha)


    * Test overidentifying restrictions


    estat sargan


    * LR confidence-interval graph


    local graph ///
        "DPTR_LR_`suffix_`sample''"

    twoway ///
        line `stub'_lrofgamma `stub'_gamma ///
        if !missing(`stub'_gamma, `stub'_lrofgamma), ///
        sort ///
        lcolor(black) ///
        lwidth(medthick) ///
        yline(`critical', ///
            lpattern(dash) ///
            lcolor(black)) ///
        title( ///
            "International Reserves Buffer Effect - `title_`sample''" ///
        ) ///
        xtitle("Threshold Parameter") ///
        ytitle("LR Statistics") ///
        graphregion(color(white)) ///
        plotregion(color(white)) ///
        name(`graph', replace)

    graph export ///
        "$FIGURES/`graph'.pdf", ///
        as(pdf) replace

    graph export ///
        "$FIGURES/`graph'.png", ///
        as(png) width(2400) replace


    restore
}


********************************************************************************
* Display Table 8 estimates
********************************************************************************

estimates table ///
    Table8_1 Table8_2 Table8_3, ///
    b(%9.5f) ///
    se(%9.5f) ///
    stats(N)


********************************************************************************
* Display regime counts for Table 8
********************************************************************************

display " "
display "=============================================================="
display "TABLE 8: OBSERVATIONS BELOW AND ABOVE ESTIMATED THRESHOLDS"
display "=============================================================="

display "Full Sample"
display "  Estimated threshold: " %9.7f `gamma_Full'
display "  Below threshold:      " `below_Full'
display "  Above threshold:      " `above_Full'
display "  Total:                " `below_Full' + `above_Full'

display " "

display "EMDEs"
display "  Estimated threshold: " %9.7f `gamma_EMDE'
display "  Below threshold:      " `below_EMDE'
display "  Above threshold:      " `above_EMDE'
display "  Total:                " `below_EMDE' + `above_EMDE'

display " "

display "AEs"
display "  Estimated threshold: " %9.7f `gamma_Advanced'
display "  Below threshold:      " `below_Advanced'
display "  Above threshold:      " `above_Advanced'
display "  Total:                " `below_Advanced' + `above_Advanced'

display "=============================================================="

********************************************************************************
* Fig. 8: State-dependent panel local projections - EMDEs
* Low reserve coverage:  L2_rtl <= 0.0953422
* High reserve coverage: L2_rtl >  0.0953422
* Cutoff equals the exact threshold estimated in the EMDE dynamic PTR
********************************************************************************

use "$DERIVED/analysis_data.dta", clear

* Exclude countries with insufficient trade-openness observations
drop if inlist( ///
    countrycode, ///
    "AGO", "BDI", "ETH", "JAM", "LAO", ///
    "MWI", "NGA", "LKA", "TTO" ///
)

keep if aded == 2

sort cn year
xtset cn year

* Construct second lag of reserve coverage and rescale GDP per capita
capture drop L2_rtl
generate L2_rtl = L2.rtl

capture drop L1_gdppk_thousands
generate L1_gdppk_thousands = ///
    L1_gdp_per_capita_cus / 1000

* Retain countries with 18 complete usable observations
local lp_required ///
    share_pel ///
    vixa ///
    L2_rtl ///
    L1_us_3m_rate_a ///
    L1_gdppk_thousands ///
    L1_gdppk_growth ///
    L1_trade_open ///
    L1_total_natural_resources_rent ///
    L1_rule_of_law ///
    exrr

local lp_required_count : word count `lp_required'

egen lp_nonmissing = ///
    rownonmiss(`lp_required')

generate byte lp_complete = ///
    lp_nonmissing == `lp_required_count'

bysort cn: egen lp_count = ///
    total(lp_complete)

keep if lp_count == 18

drop lp_nonmissing lp_complete lp_count

* Define low and high reserve regimes
local threshold = 0.0953422

generate byte highRTL = ///
    L2_rtl > `threshold' ///
    if !missing(L2_rtl)

label define highRTL_label ///
    0 "Low reserves" ///
    1 "High reserves", replace

label values highRTL highRTL_label

tabulate highRTL

* Local projection settings 
local horizon = 4

local lp_controls ///
    L1_us_3m_rate_a ///
    L1_gdppk_thousands ///
    L1_gdppk_growth ///
    L1_trade_open ///
    L1_total_natural_resources_rent ///
    L1_rule_of_law ///
    i.exrr

* Defining the three reported response functions
local lp_expression1 ///
    "vixa"

local lp_expression2 ///
    "vixa + (c.vixa#1.highRTL)"

local lp_expression3 ///
    "(c.vixa#1.highRTL)"

local lp_title1 ///
    "Low IR (Below Thr.)"

local lp_title2 ///
    "High IR (Above Thr.)"

local lp_title3 ///
    "Diff.: (High IR - Low IR)"

local lp_graph1 ///
    "lp_emde_low"

local lp_graph2 ///
    "lp_emde_high"

local lp_graph3 ///
    "lp_emde_diff"

* Removing graphs remaining from an earlier run
capture graph drop lp_emde_low
capture graph drop lp_emde_high
capture graph drop lp_emde_diff
capture graph drop LP_VIX_EMDE

* Estimate and graph the three response functions
forvalues panel = 1/3 {

    locproj share_pel ///
        vixa ///
        c.vixa#i.highRTL ///
        `lp_controls' ///
        if !missing(highRTL), ///
        fe ///
        cluster(cn) ///
        h(`horizon') ///
        conf(90 95) ///
        lcs(`lp_expression`panel'') ///
        title("`lp_title`panel''")

    graph rename Graph ///
        `lp_graph`panel'', replace
}

* Combine and export the three panels
graph combine ///
    lp_emde_low ///
    lp_emde_high ///
    lp_emde_diff, ///
    row(1) ///
    title( ///
        "Panel LP for the Buffer Effect of IR on FPI Share - EMDEs" ///
    ) ///
    graphregion(color(white)) ///
    name(LP_VIX_EMDE, replace)

graph export ///
    "$FIGURES/LP_VIX_state_dependent_EMDE.pdf", ///
    as(pdf) replace

graph export ///
    "$FIGURES/LP_VIX_state_dependent_EMDE.png", ///
    as(png) width(2400) replace
	
********************************************************************************
* Closing the replication log
********************************************************************************

capture log close _all
