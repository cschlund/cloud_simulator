@/../../vali_gui/plot_l3.pro
@local_include_file.pro
;+
; NAME:
;   VIS_SIMULATOR
;
; PURPOSE:
;   Visualization tool for cloud_simulator output
;   including comparison with reference data
;
; AUTHOR:
;   Dr. Cornelia Schlundt
;   Deutscher Wetterdienst (DWD)
;   KU22, Climate-based satellite monitoring
;   cornelia.schlundt@dwd.de
;
; CATEGORY:
;   Graphics
;
; CALLING SEQUENCE:
;   see help below
;
; MODIFICATION HISTORY:
;   Jan 2016, first version
;
;******************************************************************************
PRO VIS_SIMULATOR, VERBOSE=verbose, FILE=file, PATTERN=pattern, $
                   ALL=all, ZONAL=zonal, COMPARE=compare, JCH=jch, $
                   HIST1D=hist1d, MAP=map, REFS=refs, SAT=sat, $
                   CCIOLD=cciold, VARS=vars, RATIO=ratio, NOPNG=nopng, $
                   SNAPSHOT=snapshot, HELP=help
;******************************************************************************
    STT = SYSTIME(1)

    IF KEYWORD_SET(all) AND ~KEYWORD_SET(refs) THEN refs = 'cci'
    IF KEYWORD_SET(refs) AND ~KEYWORD_SET(sat) THEN sat = 'NOAA18'

    ; MODIFY settings
    CONFIG_VIS, cfg, FILE=file, VARS=vars, REFS=refs, PATTERN=pattern, $
                     CCIOLD=cciold
    HELP, cfg
    DEFSYSV, '!SAVE_DIR', cfg.OUT_PWD

    IF KEYWORD_SET(help) THEN BEGIN
        PRINT, ""
        PRINT, " *** THIS PROGRAM VISUALIZES THE SIMULATOR OUTPUT AND",$
               " COMPARES IT WITH REFERENCE DATA ***"
        PRINT, ""
        PRINT, " USAGE: "
        PRINT, " VIS_SIMULATOR, /all, pattern='*200807_*nc', ",$
                               "ref='cci,gac2,mod2,myd2,pmx', /nopng "
        PRINT, " VIS_SIMULATOR, /snapshot, pattern='*thv-0.15*snapshot*' "
        PRINT, " VIS_SIMULATOR, /map"
        PRINT, " VIS_SIMULATOR, /jch, refs='cci', sat='NOAA18' "
        PRINT, " VIS_SIMULATOR, /map, file='/path/to/file.nc'"
        PRINT, " VIS_SIMULATOR, /all, refs='cci', sat='NOAA15' "
        PRINT, " VIS_SIMULATOR, /zonal, refs='cci,gac2,mod2,myd2,pmx', sat='NOAA18'"
        PRINT, " VIS_SIMULATOR, /hist1d, vars='ctp,cot'"
        PRINT, " VIS_SIMULATOR, /hist1d, refs='cci,gac2,mod2,myd2', sat='NOAA18' "
        PRINT, " VIS_SIMULATOR, /compare, refs='cci', sat='NOAA18' "
        PRINT, ""
        PRINT, " Optional Keywords:"
        PRINT, " FILE           full qualified filename"
        PRINT, " PATTERN        search pattern for specific file(s)"
        PRINT, " VARS           list of parameters to be plotted, default is: ", vars
        PRINT, " MAP            creates 2D maps"
        PRINT, " HIST1D         creates 1D histogram plots"
        PRINT, " COMPARE        compares simulated and observed data (4 plots)"
        PRINT, " ZONAL          creates zonal mean plot, optional incl.: ",$
                                "options are: ", cfg.REFDATA
        PRINT, " ALL            creates all figures for given variables (default is CCI NOAA18)"
        PRINT, " JCH            creates hist2d, i.e. joint cloud histogram: cot_ctp_hist2d"
        PRINT, " REFS           options are: ", cfg.REFDATA
        PRINT, " SAT            REF requires SAT in some cases, e.g. sat='NOAA18'"
        PRINT, " VERBOSE        increase output verbosity."
        PRINT, " RATIO          adds liquid cloud fraction to HIST1D plot."
        PRINT, " CCIOLD         takes ESA Cloud_cci data, which are hard-coded ",$
                               "in validation_tool_box.pro ",$
                               "= AVHRR 31y time series processed in summer 2015"
        PRINT, " HELP           prints this message."
        PRINT, ""
        RETURN
    ENDIF


    FOR f=0, cfg.NFILES-1 DO BEGIN ; loop over files

        file = cfg.FILES[f]
        PRINT, "** Working on: ", file

        IF KEYWORD_SET(snapshot) THEN BEGIN

            PLOT_ARRAYS, file, !SAVE_DIR
            PLOT_PROFILES, file, 'cfc_profile', !SAVE_DIR
            PLOT_MATRICES, file, 'cfc_matrix', !SAVE_DIR
            PLOT_PROFILES, file, 'cot_profile', !SAVE_DIR
            PLOT_MATRICES, file, 'cot_matrix', !SAVE_DIR
            PLOT_PROFILES, file, 'cwp_profile', !SAVE_DIR
            PLOT_MATRICES, file, 'cwp_matrix', !SAVE_DIR
            PLOT_PROFILES, file, 'cer_profile', !SAVE_DIR
            PLOT_MATRICES, file, 'cer_matrix', !SAVE_DIR
            PLOT_MATRICES, file, 'cph_matrix', !SAVE_DIR

        ENDIF ELSE BEGIN

            FOR i=0, N_ELEMENTS(vars)-1 DO BEGIN ; loop over variables

                ; read simulator output file
                READ_SIM_NCDF, data, FILE=file, VAR_NAME=vars[i], $ 
                    GLOB_ATTR=gatt, VAR_ATTR=vatt

                source    = STRTRIM(STRING(gatt.SOURCE),2)
                time      = STRTRIM(STRING(gatt.TIME_COVERAGE_START),2)
                cot_thv   = STRTRIM(STRING(gatt.COT_THV,FORMAT='(F4.2)'),2)
                nfiles    = STRTRIM(STRING(gatt.NUMBER_OF_FILES),2)
                ;scops     = STRTRIM(STRING(gatt.SCOPS_TYPE),2)
                scops     = STRTRIM(STRING(gatt.SCOPS),2)
                long_name = STRTRIM(STRING(vatt.LONG_NAME),2)
                units     = ' ['+STRTRIM(STRING(vatt.UNITS),2)+']'
                fillvalue = vatt._FILLVALUE

                base = FSC_Base_Filename(file)
                xtitle = long_name + units
                figure_title = source + ' (source) for ' + time

                mini = cfg.MINI_MAXI[0,i]
                maxi = cfg.MINI_MAXI[1,i]

                IF KEYWORD_SET(verbose) THEN BEGIN
                    PRINT, '** Loaded variable: ', xtitle
                    HELP, gatt
                    HELP, vatt
                ENDIF


                IF KEYWORD_SET(hist1d) OR KEYWORD_SET(all) THEN $
                    PLOT_SIM_HIST, file, vars[i], !SAVE_DIR, base, xtitle, $
                                   units, time, cfg.CCI_PWD, $
                                   SAT=sat, REFS=refs, RATIO=ratio


                IF KEYWORD_SET(map) OR KEYWORD_SET(all) THEN $ 
                    PLOT_SIM_MAPS, file, vars[i], !SAVE_DIR, data, fillvalue, $
                                   mini, maxi, base, figure_title, xtitle


                IF KEYWORD_SET(compare) OR KEYWORD_SET(all) THEN $
                    PLOT_SIM_COMPARE_WITH, file, refs, vars[i], !SAVE_DIR, $
                                           time, mini, maxi, cfg.CCI_PWD, $
                                           SAT=sat


                IF KEYWORD_SET(zonal) OR KEYWORD_SET(all) THEN BEGIN
                    PLOT_SIM_COMPARE_ZONAL, file, vars[i], time, !SAVE_DIR, base,$
                                            mini, maxi, cfg.CCI_PWD, $
                                            REFS=refs, SAT=sat
                ENDIF

                IF KEYWORD_SET(jch) OR KEYWORD_SET(all) THEN $
                    PLOT_SIM_COMPARE_JCH, file, vars[i], time, !SAVE_DIR, base, $
                                          mini, maxi, fillvalue, cfg.CCI_PWD, $
                                          REFS=refs, SAT=sat


            ENDFOR ; loop over variables
        ENDELSE ; if snapshot or simulator results
    ENDFOR ;loop over files

    IF ~KEYWORD_SET(nopng) THEN SPAWN, cfg.EPS2PNG + !SAVE_DIR

    PRINT, "** TOTAL Elapsed Time: ", (SYSTIME(1)-STT)/60., " minutes"

;******************************************************************************
END ;end of program
;******************************************************************************
